import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rafiki_app/core/di/service_locator.dart';
import 'package:rafiki_app/features/prayer/data/models/prayer_models.dart';
import 'package:rafiki_app/features/prayer/data/services/prayer_engine.dart';
import 'package:rafiki_app/features/prayer/data/services/prayer_streak_engine.dart';
import 'package:rafiki_app/features/prayer/data/services/score_engine.dart';
import 'package:rafiki_app/features/prayer/domain/repositories/prayer_repository.dart';
import 'package:rafiki_app/features/prayer/presentation/controllers/prayer_schedule_controller.dart';
import 'package:rafiki_app/features/prayer/presentation/widgets/prayer_schedule_painters.dart';
import 'package:rafiki_app/features/prayer/presentation/widgets/prayer_schedule_widgets.dart';

class _T {
  static const bg = T.bg;
  static const ruby = T.ruby;
  static const rubyL = T.rubyL;
  static const t1 = T.t1;
  static const t2 = T.t2;
}

String _dateKey(DateTime d) => dateKey(d);
String _todayKey() => todayKey();

// ─────────────────────────────────────────────────────────────
//  Main Page — Prayer Score / Prayer Streak Screen
// ─────────────────────────────────────────────────────────────
class PrayerSchedulePage extends StatefulWidget {
  const PrayerSchedulePage({super.key});

  @override
  State<PrayerSchedulePage> createState() => _PrayerSchedulePageState();
}

class _PrayerSchedulePageState extends State<PrayerSchedulePage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // Current day
  late DayRecord _today;
  // Historical completed days (last 7)
  List<DayRecord> _history = [];

  int get _streak => sl<PrayerStreakEngine>().globalStreak.value;

  // Banner message
  String _banner = '';

  // Qada-pending prayers that belong to PREVIOUS days (carried over)
  List<QadaCarryEntry> _pendingQada = [];

  late AnimationController _bgCtrl;
  late AnimationController _headerCtrl;
  late Animation<double> _headerFade;

  // ── Lifecycle ────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _today = DayRecord(dateKey: _todayKey());
    _bgCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 20))
      ..repeat();
    _headerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _headerFade =
        CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic);
    _headerCtrl.forward();
    _loadData();

    // Tick every 30 seconds to update prayer states.
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 30));
      if (!mounted) return false;
      _tick();
      return true;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bgCtrl.dispose();
    _headerCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_bgCtrl.isAnimating) _bgCtrl.repeat();
    } else if (state == AppLifecycleState.paused) {
      _bgCtrl.stop();
    }
  }

  // ── Tick — evaluate prayer states every 30 s ─────────────────
  void _tick() {
    final now = DateTime.now();
    final todayKey = _todayKey();

    // Day rolled over while app was in foreground?
    if (_today.dateKey != todayKey) {
      _rolloverDay(now);
      return;
    }

    bool changed = false;

    for (int i = 0; i < kPrayers.length; i++) {
      final p = kPrayers[i];
      final rec = _today.recordFor(p);

      // Final states are immutable.
      if (rec.state.isFinal) continue;

      final next = PrayerTimeService.computeStateFor(
        prayerIndex: i,
        now: now,
        current: rec.state,
      );

      if (next != rec.state) {
        if (next == PrayerState.oadaPending &&
            rec.state != PrayerState.oadaPending) {
          sl<PrayerEngine>()
              .addPrayerEvent(p.adhanPrayer, CustomPrayerEventType.missed);
        }
        rec.state = next;
        changed = true;
      }
    }

    // Evaluate Duha state
    final duhaRec = _today.recordFor('الضحى');
    if (!duhaRec.state.isFinal) {
      final nextDuha = PrayerTimeService.computeDuhaState(
        now: now,
        current: duhaRec.state,
      );
      if (nextDuha != duhaRec.state) {
        duhaRec.state = nextDuha;
        changed = true;
      }
    }

    if (changed && mounted) {
      setState(() {});
      _saveData();
    }
  }

  // ── Day rollover ─────────────────────────────────────────────
  void _rolloverDay(DateTime now) {
    DateTime currentDate = DateTime.parse(_today.dateKey);
    final targetDate = prayerDate(now);
    final todayDate = DateTime(targetDate.year, targetDate.month, targetDate.day);

    while (currentDate.isBefore(todayDate)) {
      // ── Finalise the current day ──────────────────────────────
      for (final p in kPrayers) {
        final rec = _today.recordFor(p);

        // Any prayer still in a non-final, non-pending state is now missed.
        if (!rec.state.isFinal && rec.state != PrayerState.oadaPending) {
          rec.state = PrayerState.oadaPending;
        }
      }

      // ── Carry over missed prayers as qada ─────────────────────
      for (final p in kPrayers) {
        final rec = _today.recordFor(p);
        if (rec.state == PrayerState.oadaPending) {
          _pendingQada.add(
              QadaCarryEntry(prayerName: p.name, dateKey: _today.dateKey));
        }
      }

      // ── Archive day ───────────────────────────────────────────
      _history.add(_today);
      if (_history.length > 7) _history.removeAt(0);

      // ── Advance to next day ───────────────────────────────────
      currentDate = currentDate.add(const Duration(days: 1));
      _today = DayRecord(dateKey: _dateKey(currentDate));

      if (currentDate.isAtSameMomentAs(todayDate)) {
        _initTodayStates(now);
      } else {
        // Intermediate day — all prayers were missed (gap while app was closed).
        for (final p in kPrayers) {
          _today.recordFor(p).state = PrayerState.oadaPending;
        }
      }
    }

    if (mounted) {
      setState(() => _banner = 'يوم جديد! استمر في التقدم ✨');
    }
    _saveData();
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _banner = '');
    });
  }

  int day(DateTime d) => d.day;

  // ── Init today's prayer states ────────────────────────────────
  void _initTodayStates(DateTime now) {
    for (int i = 0; i < kPrayers.length; i++) {
      final rec = _today.recordFor(kPrayers[i]);
      rec.state = PrayerTimeService.computeStateFor(
        prayerIndex: i,
        now: now,
        current: PrayerState.locked,
      );
    }
    final duhaRec = _today.recordFor('الضحى');
    duhaRec.state = PrayerTimeService.computeDuhaState(
      now: now,
      current: duhaRec.state,
    );
  }

  // ── Persistence ──────────────────────────────────────────────
  Future<void> _saveData() async {
    await sl<PrayerRepository>().saveTodayRecord(_today);
    await sl<PrayerRepository>().saveHistory(_history);

    final entries = _pendingQada
        .map((e) => QadaEntry(prayerName: e.prayerName, dateKey: e.dateKey))
        .toList();
    await sl<PrayerRepository>().saveQadaEntries(entries);
  }

  Future<void> _loadData() async {
    final now = DateTime.now();

    // Load history
    _history = await sl<PrayerRepository>().loadHistory();

    // Load pending qada entries
    final entries = await sl<PrayerRepository>().loadQadaEntries();
    _pendingQada = entries
        .map((e) => QadaCarryEntry(prayerName: e.prayerName, dateKey: e.dateKey))
        .toList();

    // Load or initialise today's record
    _today = await sl<PrayerRepository>().loadTodayRecord(_todayKey());

    // Re-evaluate non-final states against current time.
    for (int i = 0; i < kPrayers.length; i++) {
      final rec = _today.recordFor(kPrayers[i]);
      if (!rec.state.isFinal) {
        final next = PrayerTimeService.computeStateFor(
          prayerIndex: i,
          now: now,
          current: rec.state,
        );
        if (next != rec.state) {
          if (next == PrayerState.oadaPending &&
              rec.state != PrayerState.oadaPending) {
            sl<PrayerEngine>().addPrayerEvent(
                kPrayers[i].adhanPrayer, CustomPrayerEventType.missed);
          }
          rec.state = next;
        }
      }
    }

    final duhaRec = _today.recordFor('الضحى');
    if (!duhaRec.state.isFinal) {
      final nextDuha = PrayerTimeService.computeDuhaState(
        now: now,
        current: duhaRec.state,
      );
      if (nextDuha != duhaRec.state) {
        duhaRec.state = nextDuha;
      }
    }

    if (mounted) setState(() {});
    await _saveData();
  }

  // ── Action: Complete prayer ──────────────────────────────────
  void _completePrayer(PrayerDef p, {required bool congregation}) async {
    final rec = _today.recordFor(p);

    if (rec.state != PrayerState.available) return;

    HapticFeedback.mediumImpact();
    final newState = congregation
        ? PrayerState.completedCongregation
        : PrayerState.completedIndividual;

    final scoreToAward = PrayerTimeService.scoreFor(newState);

    final success = await sl<PrayerEngine>().addPrayerEvent(
      p.adhanPrayer,
      congregation
          ? CustomPrayerEventType.jamaah
          : CustomPrayerEventType.onTime,
      score: scoreToAward,
      dateKey: _today.dateKey,
    );

    if (success) {
      if (mounted) {
        setState(() {
          rec.state = newState;
          rec.scoreAwarded = scoreToAward;
        });
      }
      await _saveData();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('عذراً، انتهى وقت هذه الصلاة أو تم تسجيلها مسبقاً.')),
        );
      }
    }
  }

  // ── Action: Complete today's own qada prayer ─────────────────
  void _completeQada(PrayerDef p) async {
    final rec = _today.recordFor(p);
    if (rec.state != PrayerState.oadaPending) return;

    HapticFeedback.mediumImpact();

    final success = await sl<PrayerEngine>().addPrayerEvent(
      p.adhanPrayer,
      CustomPrayerEventType.qada,
      score: ScoreConstants.qada,
      dateKey: _today.dateKey,
    );

    if (success) {
      if (mounted) {
        setState(() {
          rec.state = PrayerState.oadaCompleted;
          rec.scoreAwarded = ScoreConstants.qada;
        });
      }
      await _saveData();
    }
  }

  // ── Action: Complete Duha prayer ────────────────────────────
  void _completeDuha() async {
    final rec = _today.recordFor('الضحى');
    if (rec.state != PrayerState.available) return;

    HapticFeedback.mediumImpact();

    final success = await sl<PrayerEngine>().completeDuha(dateKey: _today.dateKey);
    if (success) {
      if (mounted) {
        setState(() {
          rec.state = PrayerState.completedIndividual;
          rec.scoreAwarded = ScoreConstants.duha;
        });
      }
      await _saveData();
    }
  }

  // ── Helper to map string to adhan Prayer enum ─────────────────
  Prayer _mapStringToAdhanPrayer(String name) {
    switch (name.toLowerCase()) {
      case 'fajr':
      case 'الفجر':
        return Prayer.fajr;
      case 'dhuhr':
      case 'الظهر':
        return Prayer.dhuhr;
      case 'asr':
      case 'العصر':
        return Prayer.asr;
      case 'maghrib':
      case 'المغرب':
        return Prayer.maghrib;
      case 'isha':
      case 'العشاء':
        return Prayer.isha;
      default:
        return Prayer.none;
    }
  }

  // ── Action: Complete a carried-over qada from a previous day ─
  void _completeCarryQada(QadaCarryEntry entry) async {
    HapticFeedback.mediumImpact();

    final score = ScoreConstants.qada;
    final adhanPrayer = _mapStringToAdhanPrayer(entry.prayerName);

    final success = await sl<PrayerEngine>().addPrayerEvent(
      adhanPrayer,
      CustomPrayerEventType.qada,
      score: score,
      dateKey: entry.dateKey,
    );

    if (success) {
      if (mounted) {
        setState(() {
          entry.completed = true;
        });
      }
      _pendingQada.removeWhere((e) => e.completed);
      await _saveData();
    }
  }

  // ── Mark sunnah ──────────────────────────────────────────────
  void _markSunnah(PrayerDef p, int i) async {
    final rec = _today.recordFor(p);
    if (rec.completedSunnah.contains(i)) return;

    HapticFeedback.selectionClick();

    final scoreDelta = ScoreConstants.sunnah;
    final success = await sl<PrayerEngine>().addPrayerEvent(
      p.adhanPrayer,
      CustomPrayerEventType.sunnah,
      score: scoreDelta,
      sunnahIndex: i,
    );

    if (success && mounted) {
      setState(() {
        rec.completedSunnah.add(i);
        rec.sunnahScoreAwarded =
            PrayerTimeService.sunnahScoreFor(rec.completedSunnah.length);
      });
      _saveData();
    }
  }

  // ── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _T.bg,
        extendBodyBehindAppBar: true,
        appBar: _buildAppBar(),
        body: Stack(
          children: [
            _buildBg(),
            SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(child: SizedBox(height: 6)),

                  // Header Subtitle
                  SliverToBoxAdapter(child: _buildHeaderSubtitle()),

                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // Rollover Banner if active
                  if (_banner.isNotEmpty)
                    SliverToBoxAdapter(child: BannerWidget(text: _banner)),



                  // 1. Hero Score Element (Unlimited Score + Daily Gain + Current Streak)
                  SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: _headerFade,
                      child: AnimatedBuilder(
                        animation: Listenable.merge([
                          sl<ScoreEngine>().totalScore,
                          sl<ScoreEngine>().todayScore,
                          sl<PrayerStreakEngine>().globalStreak,
                        ]),
                        builder: (context, _) {
                          return PrayerScoreHero(
                            totalScore: sl<ScoreEngine>().totalScore.value,
                            todayGain: sl<ScoreEngine>().todayScore.value,
                            streak: _streak,
                          );
                        },
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // 2. Carried-over Qada Section (if exists)
                  if (_pendingQada.isNotEmpty) ...[
                    SliverToBoxAdapter(child: _buildQadaSection()),
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  ],

                  // 3. Today's Prayers Section (Compact, unified list)
                  SliverToBoxAdapter(
                    child: TodayPrayersCard(
                      today: _today,
                      onComplete: (prayer, isCong) =>
                          _completePrayer(prayer, congregation: isCong),
                      onQada: (prayer) => _completeQada(prayer),
                      onMarkSunnah: (prayer, idx) => _markSunnah(prayer, idx),
                      onCompleteDuha: _completeDuha,
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // 4. Minimal Motivation Footer
                  const SliverToBoxAdapter(child: MinimalMotivationFooter()),

                  const SliverToBoxAdapter(child: SizedBox(height: 36)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'سلسلة صلاتي',
          style: TextStyle(
            color: _T.t1,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.2,
          ),
        ),
      );

  Widget _buildHeaderSubtitle() => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Center(
          child: Text(
            'استمر في المحافظة على صلاتك 🌙',
            style: TextStyle(
              color: _T.t2,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );

  Widget _buildBg() => Positioned.fill(
        child: AnimatedBuilder(
          animation: _bgCtrl,
          builder: (_, __) => CustomPaint(
            painter: BgPainter(_bgCtrl.value),
          ),
        ),
      );

  Widget _buildQadaSection() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _T.ruby.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _T.ruby.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: _T.rubyL, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'صلوات قضاء متراكمة',
                    style: TextStyle(
                      color: _T.rubyL,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._pendingQada.map((e) => QadaCarryCard(
                    entry: e,
                    onComplete: () => _completeCarryQada(e),
                  )),
            ],
          ),
        ),
      );
}
