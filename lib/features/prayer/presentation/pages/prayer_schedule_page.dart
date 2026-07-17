import 'package:rafiki_app/core/di/service_locator.dart';
import 'package:rafiki_app/features/prayer/data/services/prayer_streak_engine.dart';

import 'package:adhan/adhan.dart';
import 'package:rafiki_app/features/prayer/data/services/prayer_engine.dart';
import 'package:rafiki_app/features/prayer/data/models/prayer_models.dart';
import 'package:rafiki_app/features/prayer/domain/repositories/prayer_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rafiki_app/features/prayer/presentation/widgets/prayer_schedule_widgets.dart';
import 'package:rafiki_app/features/prayer/presentation/widgets/prayer_schedule_painters.dart';


import 'package:rafiki_app/features/prayer/presentation/controllers/prayer_schedule_controller.dart';

class _T {
  static const bg      = T.bg;
  static const card    = T.card;

  static const jade    = T.jade;
  static const jadeDim = T.jadeDim;
  static const jadeSoft= T.jadeSoft;

  static const gold    = T.gold;
  static const goldSoft= T.goldSoft;

  static const flame   = T.flame;

  static const violet  = T.violet;
  static const violetL = T.violetL;

  static const ruby    = T.ruby;
  static const rubyL   = T.rubyL;

  static const t1 = T.t1;
  static const t2 = T.t2;
  static const t3 = T.t3;
}

String _dateKey(DateTime d) => dateKey(d);
String _todayKey() => todayKey();

// ─────────────────────────────────────────────────────────────
//  Entry Point
// ─────────────────────────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const PrayerTrackerApp());
}

class PrayerTrackerApp extends StatelessWidget {
  const PrayerTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تقدمك اليومي',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.dark(surface: _T.bg),
        scaffoldBackgroundColor: _T.bg,
        fontFamily: 'Cairo',
      ),
      home: const PrayerSchedulePage(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Main Page
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
  late Animation<double>   _headerFade;

  // ── Computed ────────────────────────────────────────────────
  int get _prayedCount => kPrayers.where((p) {
    final s = _today.recordFor(p).state;
    return s == PrayerState.completedIndividual ||
        s == PrayerState.completedCongregation;
  }).length;

  int get _sunnahDone => kPrayers.fold(
      0, (a, p) => a + _today.recordFor(p).completedSunnah.length);

  double get _progress {
    const total = kTotalPrayers + kTotalSunnah;
    return (_prayedCount + _sunnahDone) / total;
  }

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
    // Using a self-scheduling Future instead of a Timer so it's
    // automatically stopped when the widget is unmounted.
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
    final now      = DateTime.now();
    final todayKey = _todayKey();

    // Day rolled over while app was in foreground?
    if (_today.dateKey != todayKey) {
      _rolloverDay(now);
      return;
    }

    bool changed = false;

    for (int i = 0; i < kPrayers.length; i++) {
      final p   = kPrayers[i];
      final rec = _today.recordFor(p);

      // Final states are immutable.
      if (rec.state.isFinal) continue;

      final next = PrayerTimeService.computeStateFor(
        prayerIndex: i,
        now:         now,
        current:     rec.state,
      );

      if (next != rec.state) {
        if (next == PrayerState.oadaPending && rec.state != PrayerState.oadaPending) {
          sl<PrayerEngine>().addPrayerEvent(p.adhanPrayer, CustomPrayerEventType.missed);
        }
        rec.state = next;
        changed   = true;
      }
    }

    if (changed && mounted) {
      setState(() {});
      _saveData();
    }
  }

  // ── Day rollover ─────────────────────────────────────────────
  /// Handles the case where the date has changed (app woke up on a new day,
  /// or multiple days were skipped while the app was closed).
  void _rolloverDay(DateTime now) {
    DateTime currentDate = DateTime.parse(_today.dateKey);
    final todayDate      = DateTime(now.year, now.month, now.day);

    while (currentDate.isBefore(todayDate)) {
      // ── Finalise the current day ──────────────────────────────
      for (final p in kPrayers) {
        final rec = _today.recordFor(p);

        // Any prayer still in a non-final, non-pending state is now missed.
        if (!rec.state.isFinal && rec.state != PrayerState.oadaPending) {
          rec.state = PrayerState.oadaPending;
        }
      }
      // Engines handle total score internally now

      // ── Carry over missed prayers as qada ─────────────────────
      for (final p in kPrayers) {
        final rec = _today.recordFor(p);
        if (rec.state == PrayerState.oadaPending) {
          _pendingQada.add(
              QadaCarryEntry(prayerName: p.name, dateKey: _today.dateKey));
        }
      }

      // Engines handle streak internally now

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

  // ── Init today's prayer states ────────────────────────────────
  void _initTodayStates(DateTime now) {
    for (int i = 0; i < kPrayers.length; i++) {
      final rec = _today.recordFor(kPrayers[i]);
      rec.state = PrayerTimeService.computeStateFor(
        prayerIndex: i,
        now:         now,
        current:     PrayerState.locked,
      );
    }
  }

  // ── Persistence ──────────────────────────────────────────────
  Future<void> _saveData() async {
    await sl<PrayerRepository>().saveTodayRecord(_today);
    await sl<PrayerRepository>().saveHistory(_history);
    
    final entries = _pendingQada.map((e) => QadaEntry(prayerName: e.prayerName, dateKey: e.dateKey)).toList();
    await sl<PrayerRepository>().saveQadaEntries(entries);
  }

  Future<void> _loadData() async {
    final now   = DateTime.now();

    // Load history
    _history = await sl<PrayerRepository>().loadHistory();

    // Load pending qada entries
    final entries = await sl<PrayerRepository>().loadQadaEntries();
    _pendingQada = entries.map((e) => QadaCarryEntry(prayerName: e.prayerName, dateKey: e.dateKey)).toList();

    // Load or initialise today's record
    _today = await sl<PrayerRepository>().loadTodayRecord(_todayKey());
    
    // Re-evaluate non-final states against current time.
    for (int i = 0; i < kPrayers.length; i++) {
      final rec = _today.recordFor(kPrayers[i]);
      if (!rec.state.isFinal) {
        final next = PrayerTimeService.computeStateFor(
          prayerIndex: i,
          now:         now,
          current:     rec.state,
        );
        if (next != rec.state) {
          if (next == PrayerState.oadaPending && rec.state != PrayerState.oadaPending) {
            sl<PrayerEngine>().addPrayerEvent(kPrayers[i].adhanPrayer, CustomPrayerEventType.missed);
          }
          rec.state = next;
        }
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
      congregation ? CustomPrayerEventType.jamaah : CustomPrayerEventType.onTime,
      score: scoreToAward,
    );
    
    if (success) {
      if (mounted) {
        setState(() {
          rec.state        = newState;
          rec.scoreAwarded = scoreToAward;
        });
      }
      await _saveData();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('عذراً، انتهى وقت هذه الصلاة أو تم تسجيلها مسبقاً.')),
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
      score: ScoreConstants.individual,
    );

    if (success) {
      if (mounted) {
        setState(() {
          rec.state        = PrayerState.oadaCompleted;
          rec.scoreAwarded = ScoreConstants.qada;
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
    );

    if (success) {
      if (mounted) {
        setState(() {
          entry.completed = true;
        });
      }
      _pendingQada.removeWhere((e) => e.completed);
      _saveData();
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
    return Scaffold(
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
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                if (_banner.isNotEmpty)
                  SliverToBoxAdapter(child: BannerWidget(text: _banner)),
                SliverToBoxAdapter(child: _buildHeroCard()),
                const SliverToBoxAdapter(child: SizedBox(height: 14)),
                SliverToBoxAdapter(child: _buildMiniStats()),
                const SliverToBoxAdapter(child: SizedBox(height: 14)),
                SliverToBoxAdapter(child: _buildLiveScoreCard()),
                const SliverToBoxAdapter(child: SizedBox(height: 14)),
                SliverToBoxAdapter(child: _buildScoreCard()),
                const SliverToBoxAdapter(child: SizedBox(height: 14)),
                if (_pendingQada.isNotEmpty)
                  SliverToBoxAdapter(child: _buildQadaSection()),
                if (_pendingQada.isNotEmpty)
                  const SliverToBoxAdapter(child: SizedBox(height: 14)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (ctx, i) {
                        final pr  = kPrayers[i];
                        final rec = _today.recordFor(pr);
                        return PrayerCard(
                          key:          ValueKey(pr.name),
                          prayer:       pr,
                          record:       rec,
                          onComplete:   (cong) =>
                              _completePrayer(pr, congregation: cong),
                          onQada:       () => _completeQada(pr),
                          onMarkSunnah: (j) => _markSunnah(pr, j),
                          index:        i,
                        );
                      },
                      childCount: kPrayers.length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    centerTitle: true,
    title: const Text(
      'تقدمك اليومي',
      style: TextStyle(
          color: _T.t1, fontSize: 18, fontWeight: FontWeight.w800),
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

  Widget _buildHeroCard() => FadeTransition(
    opacity: _headerFade,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [_T.jadeDim.withValues(alpha: 0.25), _T.card],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
              color: _T.jade.withValues(alpha: 0.2), width: 1.2),
          boxShadow: [
            BoxShadow(
                color: _T.jade.withValues(alpha: 0.1),
                blurRadius: 32,
                offset: const Offset(0, 12))
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 88,
              height: 88,
              child: CustomPaint(
                painter: ArcProgressPainter(_progress, _T.jade),
                child: Center(
                  child: Text('${(_progress * 100).toInt()}%',
                      style: const TextStyle(
                          color: _T.jadeSoft,
                          fontSize: 18,
                          fontWeight: FontWeight.w900)),
                ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_progressLabel(),
                      style: const TextStyle(
                          color: _T.t1,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          height: 1.2)),
                  const SizedBox(height: 5),
                  Text(
                      '$_prayedCount من ${kPrayers.length} صلوات • $_sunnahDone من $kTotalSunnah سنة',
                      style: const TextStyle(
                          color: _T.t2, fontSize: 13, height: 1.5)),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: _progress,
                      minHeight: 6,
                      backgroundColor:
                      _T.t3.withValues(alpha: 0.2),
                      valueColor:
                      const AlwaysStoppedAnimation(_T.jade),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  String _progressLabel() {
    if (_progress == 0)  return 'ابدأ يومك بـ الله 🌅';
    if (_progress < 0.4) return 'أحسنت، واصل 💪';
    if (_progress < 0.8) return 'رائع، أنت في المنتصف ✨';
    if (_progress < 1.0) return 'اكتمال قريب! 🌟';
    return 'أتممت يومك 🎉';
  }

  Widget _buildMiniStats() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      children: [
        // Show today's daily streak count (on-time fardh prayers so far)
        Expanded(
            child: MiniStatCard(
                icon: Icons.local_fire_department_rounded,
                label: 'السلسلة',
                value: '$_streak يوم',
                color: _T.flame)),
        const SizedBox(width: 10),
        Expanded(
            child: MiniStatCard(
                icon: Icons.mosque_rounded,
                label: 'الفروض',
                value: '$_prayedCount / ${kPrayers.length}',
                color: _T.jade)),
        const SizedBox(width: 10),
        Expanded(
            child: MiniStatCard(
                icon: Icons.auto_awesome_rounded,
                label: 'السنن',
                value: '$_sunnahDone / $kTotalSunnah',
                color: _T.gold)),
      ],
    ),
  );

  // ── Live Score Card — النقاط اللحظية لهذا اليوم ────────────────
  Widget _buildLiveScoreCard() {
    // ── حساب تفاصيل الـ Score ──────────────────────────────────
    double fardhScore  = 0;
    double sunnahScore = 0;

    for (final p in kPrayers) {
      final rec = _today.recordFor(p);
      fardhScore  += PrayerTimeService.scoreFor(rec.state);
      sunnahScore += rec.sunnahScoreAwarded;
    }
    fardhScore  = double.parse(fardhScore.toStringAsFixed(2));
    sunnahScore = double.parse(sunnahScore.toStringAsFixed(2));
    final total = double.parse((fardhScore + sunnahScore).toStringAsFixed(2));

    // نسبة التقدم من أقصى نقاط ممكنة في اليوم
    // أقصى نقاط: 5 صلوات جماعة (5×2.7=13.5) + سنن (5×0.75=3.75) = 17.25
    const double kMaxPossible = 17.25;
    final double scoreProgress = (total / kMaxPossible).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              _T.violet.withValues(alpha: 0.08),
              _T.card,
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          border: Border.all(color: _T.violet.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: _T.violet.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _T.violet.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.stars_rounded,
                      color: _T.violetL, size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('النقاط اللحظية',
                          style: TextStyle(
                              color: _T.t1,
                              fontSize: 14,
                              fontWeight: FontWeight.w800)),
                      Text('تُحدَّث فور تعليم كل صلاة',
                          style: TextStyle(color: _T.t3, fontSize: 11)),
                    ],
                  ),
                ),
                // ── الرقم الكبير ──────────────────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '$total',
                            style: const TextStyle(
                              color: _T.violetL,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ),
                          TextSpan(
                            text: ' نقطة',
                            style: TextStyle(
                              color: _T.violetL.withValues(alpha: 0.7),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'من ${kMaxPossible.toStringAsFixed(0)}',
                      style: const TextStyle(color: _T.t3, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Progress bar ────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: scoreProgress,
                minHeight: 6,
                backgroundColor: _T.t3.withValues(alpha: 0.15),
                valueColor: const AlwaysStoppedAnimation(_T.violetL),
              ),
            ),

            const SizedBox(height: 14),

            // ── تفاصيل: فروض + سنن ──────────────────────────────
            Row(
              children: [
                // فروض
                Expanded(
                  child: ScoreDetailChip(
                    label: 'الفروض',
                    value: fardhScore,
                    icon: Icons.mosque_rounded,
                    color: _T.jade,
                  ),
                ),
                const SizedBox(width: 8),
                // سنن
                Expanded(
                  child: ScoreDetailChip(
                    label: 'السنن',
                    value: sunnahScore,
                    icon: Icons.auto_awesome_rounded,
                    color: _T.gold,
                  ),
                ),
              ],
            ),

            // ── تفاصيل كل صلاة ──────────────────────────────────
            const SizedBox(height: 12),
            const Divider(color: Color(0xFF1E2A3A), thickness: 1, height: 1),
            const SizedBox(height: 10),

            ...kPrayers.map((p) {
              final rec        = _today.recordFor(p);
              final pScore     = PrayerTimeService.scoreFor(rec.state);
              final pSunnah    = rec.sunnahScoreAwarded;
              final isPending  = rec.state == PrayerState.oadaPending;
              final isLocked   = rec.state == PrayerState.locked;
              final isAvail    = rec.state == PrayerState.available;

              Color rowColor;
              String statusLabel;
              if (rec.state == PrayerState.completedCongregation) {
                rowColor    = _T.gold;
                statusLabel = 'جماعة';
              } else if (rec.state == PrayerState.completedIndividual) {
                rowColor    = _T.jade;
                statusLabel = 'فردي';
              } else if (rec.state == PrayerState.oadaCompleted) {
                rowColor    = _T.violet;
                statusLabel = 'قضاء';
              } else if (isPending) {
                rowColor    = _T.ruby;
                statusLabel = 'فائتة';
              } else if (isAvail) {
                rowColor    = p.accent;
                statusLabel = 'متاحة';
              } else {
                rowColor    = _T.t3;
                statusLabel = 'مغلق';
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    // اسم الصلاة
                    SizedBox(
                      width: 56,
                      child: Text(
                        p.name,
                        style: TextStyle(
                          color: isLocked ? _T.t3 : _T.t2,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // حالة
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: rowColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: rowColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                            color: rowColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    const Spacer(),
                    // نقاط الفرض
                    if (pScore > 0)
                      Text(
                        '+${pScore.toStringAsFixed(pScore % 1 == 0 ? 0 : 1)}',
                        style: TextStyle(
                          color: rowColor.withValues(alpha: 0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    else
                      Text(
                        '—',
                        style: TextStyle(
                            color: _T.t3.withValues(alpha: 0.5),
                            fontSize: 12),
                      ),
                    // نقاط السنة
                    if (pSunnah > 0) ...[
                      const SizedBox(width: 4),
                      Text(
                        '+${pSunnah.toStringAsFixed(2)} ✨',
                        style: const TextStyle(
                            color: _T.gold, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard() {
    final hist = _history.reversed.take(5).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _T.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _T.gold.withValues(alpha: 0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.calendar_month_rounded, color: _T.goldSoft, size: 36),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('سجل الأيام المنتهية',
                      style: TextStyle(color: _T.t2, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: hist.isEmpty
                        ? [const DayChip(completed: false, isEmpty: true)]
                        : hist
                        .map((d) => DayChip(
                        completed: d.totalScore >= kMaxDayScore))
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
          Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: _T.rubyL, size: 18),
              const SizedBox(width: 8),
              const Text('صلوات قضاء متراكمة',
                  style: TextStyle(
                      color: _T.rubyL,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          ..._pendingQada.map((e) => QadaCarryCard(
            entry:      e,
            onComplete: () => _completeCarryQada(e),
          )),
        ],
      ),
    ),
  );
}

