import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────
//  Design Tokens
// ─────────────────────────────────────────────────────────────
class _T {
  static const bg      = Color(0xFF080D12);
  static const surface = Color(0xFF0E1620);
  static const card    = Color(0xFF121C2A);
  static const cardHi  = Color(0xFF182435);

  static const jade    = Color(0xFF2EC4A0);
  static const jadeDim = Color(0xFF1A7060);
  static const jadeSoft= Color(0xFF80DFCA);

  static const gold    = Color(0xFFD4A030);
  static const goldSoft= Color(0xFFF0C860);

  static const flame   = Color(0xFFFF6B30);
  static const flameL  = Color(0xFFFFAA60);

  static const violet  = Color(0xFF9B59B6);
  static const violetL = Color(0xFFBB8FD4);

  static const ruby    = Color(0xFFE74C3C);
  static const rubyL   = Color(0xFFF1948A);

  static const sky     = Color(0xFF3498DB);
  static const skyL    = Color(0xFF7FB3D3);

  static const t1 = Color(0xFFEEE8D8);
  static const t2 = Color(0xFFAAA498);
  static const t3 = Color(0xFF585450);

  static const List<List<Color>> prayerColors = [
    [Color(0xFF0E1E2A), Color(0xFF60C8F0)],
    [Color(0xFF1A1808), Color(0xFFD4A030)],
    [Color(0xFF1A1208), Color(0xFFE87840)],
    [Color(0xFF10180A), Color(0xFF80C840)],
    [Color(0xFF0E1020), Color(0xFF8890E0)],
  ];

  static const List<IconData> prayerIcons = [
    Icons.wb_twilight_rounded,
    Icons.wb_sunny_rounded,
    Icons.light_mode_rounded,
    Icons.wb_cloudy_rounded,
    Icons.nights_stay_rounded,
  ];
}

// ─────────────────────────────────────────────────────────────
//  Scoring Constants  (modify here to adjust)
// ─────────────────────────────────────────────────────────────
class ScoreConstants {
  static const double congregation = 2.7;
  static const double individual   = 1.0;
  static const double qada         = 0.5;
  static const double sunnah       = 0.75;
}

// ─────────────────────────────────────────────────────────────
//  Prayer State Enum
// ─────────────────────────────────────────────────────────────
enum PrayerState {
  locked,             // before prayer time
  available,          // during prayer window
  completedIndividual,// prayed alone on time
  completedCongregation,// prayed in congregation on time
  oadaPending,        // missed (qada owed)
  oadaCompleted,      // qada made up
}

extension PrayerStateX on PrayerState {
  bool get isCompleted =>
      this == PrayerState.completedIndividual ||
          this == PrayerState.completedCongregation ||
          this == PrayerState.oadaCompleted;

  bool get isFinal => isCompleted;

  String toJson() => name;
  static PrayerState fromJson(String s) =>
      PrayerState.values.firstWhere((e) => e.name == s,
          orElse: () => PrayerState.locked);
}

// ─────────────────────────────────────────────────────────────
//  Prayer Time Definition
// ─────────────────────────────────────────────────────────────
class PrayerTimeDef {
  /// Minutes from midnight
  final int startMinutes;
  final int endMinutes; // when it becomes qada

  const PrayerTimeDef(this.startMinutes, this.endMinutes);

  DateTime start(DateTime day) =>
      DateTime(day.year, day.month, day.day, startMinutes ~/ 60, startMinutes % 60);

  DateTime end(DateTime day) =>
      DateTime(day.year, day.month, day.day, endMinutes ~/ 60, endMinutes % 60);
}

// Default times — replace with calculation or API as needed.
// Fajr 05:00 → Shuruq 06:30 | Dhuhr 12:00 → Asr 15:30
// Asr 15:30 → Maghrib 18:00 | Maghrib 18:00 → Isha 19:30
// Isha 19:30 → next Fajr 05:00
class DefaultPrayerTimes {
  static const fajr    = PrayerTimeDef(5 * 60,       6 * 60 + 30);
  static const dhuhr   = PrayerTimeDef(12 * 60,      15 * 60 + 30);
  static const asr     = PrayerTimeDef(15 * 60 + 30, 18 * 60);
  static const maghrib = PrayerTimeDef(18 * 60,      19 * 60 + 30);
  static const isha    = PrayerTimeDef(19 * 60 + 30, 24 * 60 + 5 * 60); // ends next day 05:00
}

// ─────────────────────────────────────────────────────────────
//  Prayer Definition
// ─────────────────────────────────────────────────────────────
class PrayerDef {
  final String name;
  final int rakats;
  final List<String> sunnah;
  final List<Color> colors;
  final IconData icon;
  final PrayerTimeDef times;

  const PrayerDef({
    required this.name,
    required this.rakats,
    required this.sunnah,
    required this.colors,
    required this.icon,
    required this.times,
  });

  Color get accent => colors[1];
  Color get tint   => colors[0];
}

final List<PrayerDef> kPrayers = [
  PrayerDef(name: "الفجر",  rakats: 2, sunnah: ["٢ سنة قبلية"],
      colors: _T.prayerColors[0], icon: _T.prayerIcons[0], times: DefaultPrayerTimes.fajr),
  PrayerDef(name: "الظهر",  rakats: 4, sunnah: ["٤ سنة قبلية", "٢ سنة بعدية"],
      colors: _T.prayerColors[1], icon: _T.prayerIcons[1], times: DefaultPrayerTimes.dhuhr),
  PrayerDef(name: "العصر",  rakats: 4, sunnah: [],
      colors: _T.prayerColors[2], icon: _T.prayerIcons[2], times: DefaultPrayerTimes.asr),
  PrayerDef(name: "المغرب", rakats: 3, sunnah: ["٢ سنة بعدية"],
      colors: _T.prayerColors[3], icon: _T.prayerIcons[3], times: DefaultPrayerTimes.maghrib),
  PrayerDef(name: "العشاء", rakats: 4, sunnah: ["٢ سنة بعدية"],
      colors: _T.prayerColors[4], icon: _T.prayerIcons[4], times: DefaultPrayerTimes.isha),
];

const int kTotalSunnah  = 5;
const int kTotalPrayers = 5;
const double kMaxDayScore = 3.0;

// ─────────────────────────────────────────────────────────────
//  Prayer Record (per prayer per day)
// ─────────────────────────────────────────────────────────────
class PrayerRecord {
  PrayerState state;
  Set<int> completedSunnah;
  double scoreAwarded; // actual fardh score already credited (0 until finalized)
  double sunnahScoreAwarded; // sunnah score accumulated separately

  PrayerRecord({
    this.state = PrayerState.locked,
    Set<int>? completedSunnah,
    this.scoreAwarded = 0,
    this.sunnahScoreAwarded = 0,
  }) : completedSunnah = completedSunnah ?? {};

  Map<String, dynamic> toJson() => {
    'state': state.toJson(),
    'sunnah': completedSunnah.toList(),
    'score': scoreAwarded,
    'sunnahScore': sunnahScoreAwarded,
  };

  factory PrayerRecord.fromJson(Map<String, dynamic> j) => PrayerRecord(
    state: PrayerStateX.fromJson(j['state'] as String? ?? 'locked'),
    completedSunnah: Set<int>.from((j['sunnah'] as List<dynamic>?) ?? []),
    scoreAwarded: (j['score'] as num?)?.toDouble() ?? 0,
    sunnahScoreAwarded: (j['sunnahScore'] as num?)?.toDouble() ?? 0,
  );
}

// ─────────────────────────────────────────────────────────────
//  Day Record
// ─────────────────────────────────────────────────────────────
class DayRecord {
  final String dateKey;
  final Map<String, PrayerRecord> prayers; // keyed by prayer name
  double totalScore;

  DayRecord({
    required this.dateKey,
    Map<String, PrayerRecord>? prayers,
    this.totalScore = 0,
  }) : prayers = prayers ?? {};

  Map<String, dynamic> toJson() => {
    'date': dateKey,
    'prayers': prayers.map((k, v) => MapEntry(k, v.toJson())),
    'total': totalScore,
  };

  factory DayRecord.fromJson(Map<String, dynamic> j) {
    final raw = j['prayers'] as Map<String, dynamic>? ?? {};
    return DayRecord(
      dateKey: j['date'] as String,
      prayers: raw.map((k, v) => MapEntry(k, PrayerRecord.fromJson(v as Map<String, dynamic>))),
      totalScore: (j['total'] as num?)?.toDouble() ?? 0,
    );
  }

  PrayerRecord recordFor(PrayerDef p) =>
      prayers.putIfAbsent(p.name, () => PrayerRecord());
}

// ─────────────────────────────────────────────────────────────
//  Helpers
// ─────────────────────────────────────────────────────────────
String _dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _todayKey() => _dateKey(DateTime.now());

// ─────────────────────────────────────────────────────────────
//  Prayer Time Service
// ─────────────────────────────────────────────────────────────
class PrayerTimeService {
  /// Determine state for a prayer at [now]
  static PrayerState computeState({
    required PrayerDef prayer,
    required DateTime now,
    required PrayerState current,
  }) {
    // Final states never change
    if (current.isFinal) return current;
    if (current == PrayerState.oadaPending) return current;

    final today = DateTime(now.year, now.month, now.day);
    final start = prayer.times.start(today);

    // Isha end spans midnight
    DateTime end;
    if (prayer.name == "العشاء") {
      final tomorrow = today.add(const Duration(days: 1));
      end = DateTime(tomorrow.year, tomorrow.month, tomorrow.day,
          prayer.times.endMinutes ~/ 60 - 24, prayer.times.endMinutes % 60);
    } else {
      end = prayer.times.end(today);
    }

    if (now.isBefore(start)) return PrayerState.locked;
    if (now.isBefore(end))   return PrayerState.available;
    return PrayerState.oadaPending; // missed window
  }

  /// Score for a completed fardh state
  static double scoreFor(PrayerState state) {
    switch (state) {
      case PrayerState.completedCongregation: return ScoreConstants.congregation;
      case PrayerState.completedIndividual:   return ScoreConstants.individual;
      case PrayerState.oadaCompleted:         return ScoreConstants.qada;
      default: return 0;
    }
  }

  /// Score for completed sunnah prayers
  static double sunnahScoreFor(int completedCount) =>
      double.parse((completedCount * ScoreConstants.sunnah).toStringAsFixed(2));
}

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
    with TickerProviderStateMixin {

  // Current day
  late DayRecord _today;
  // Historical completed days (last 7)
  List<DayRecord> _history = [];
  // Grand total (historical only) — kept internally, not shown to user
  double _grandTotal = 0;
  // Streak
  int _streak = 0;
  // Banner message
  String _banner = '';

  // Qada-pending prayers that belong to PREVIOUS days (must not be lost)
  List<_QadaEntry> _pendingQada = [];

  late AnimationController _bgCtrl;
  late AnimationController _headerCtrl;
  late Animation<double>   _headerFade;

  // ── Timers ──────────────────────────────────────────────────
  DateTime _lastTick = DateTime.now();

  // ── Computed ────────────────────────────────────────────────
  int get _prayedCount => kPrayers.where((p) {
    final s = _today.recordFor(p).state;
    return s == PrayerState.completedIndividual || s == PrayerState.completedCongregation;
  }).length;

  int get _sunnahDone => kPrayers.fold(0, (a, p) => a + _today.recordFor(p).completedSunnah.length);

  /// Total internal score for today (fardh + sunnah). Used only for
  /// background bookkeeping (history totals, streaks) — never displayed.
  double get _todayLiveScore {
    double s = 0;
    for (final p in kPrayers) {
      final rec = _today.recordFor(p);
      s += PrayerTimeService.scoreFor(rec.state);
      s += rec.sunnahScoreAwarded;
    }
    return double.parse(s.toStringAsFixed(2));
  }

  double get _progress {
    const total = kTotalPrayers + kTotalSunnah;
    return (_prayedCount + _sunnahDone) / total;
  }

  // ── Lifecycle ────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _today = DayRecord(dateKey: _todayKey());
    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
    _headerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _headerFade = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic);
    _headerCtrl.forward();
    _loadData();

    // Tick every 30 seconds to update prayer states
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 30));
      if (!mounted) return false;
      _tick();
      return true;
    });
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _headerCtrl.dispose();
    super.dispose();
  }

  // ── Tick — update states ─────────────────────────────────────
  void _tick() {
    final now = DateTime.now();
    final todayKey = _todayKey();

    // Day rolled over?
    if (_today.dateKey != todayKey) {
      _rolloverDay(now);
      return;
    }

    // Update states for current prayers
    bool changed = false;
    for (final p in kPrayers) {
      final rec = _today.recordFor(p);
      if (rec.state.isFinal) continue;
      final next = PrayerTimeService.computeState(prayer: p, now: now, current: rec.state);
      if (next != rec.state) {
        rec.state = next;
        changed = true;
      }
    }
    if (changed && mounted) {
      setState(() {});
      _saveData();
    }
    _lastTick = now;
  }

  // ── Day rollover ─────────────────────────────────────────────
  void _rolloverDay(DateTime now) {
    DateTime currentDate = DateTime.parse(_today.dateKey);
    final todayDate = DateTime(now.year, now.month, now.day);

    while (currentDate.isBefore(todayDate)) {
      // Finalize the current day record
      double pts = 0;
      for (final p in kPrayers) {
        final rec = _today.recordFor(p);
        if (!rec.state.isFinal && rec.state != PrayerState.oadaPending) {
          rec.state = PrayerState.oadaPending;
        }
        pts += PrayerTimeService.scoreFor(rec.state);
        pts += rec.sunnahScoreAwarded;
      }
      pts = double.parse(pts.toStringAsFixed(2));
      _today.totalScore = pts;
      _grandTotal = double.parse((_grandTotal + pts).toStringAsFixed(2));

      // Move qada-pending to carry-over list
      for (final p in kPrayers) {
        final rec = _today.recordFor(p);
        if (rec.state == PrayerState.oadaPending) {
          _pendingQada.add(_QadaEntry(prayerName: p.name, dateKey: _today.dateKey));
        }
      }

      // Update streak
      int dayPrayedCount = kPrayers.where((p) {
        final s = _today.recordFor(p).state;
        return s == PrayerState.completedIndividual || s == PrayerState.completedCongregation;
      }).length;

      if (dayPrayedCount == kPrayers.length) {
        _streak++;
      } else if (dayPrayedCount == 0) {
        _streak = (_streak - 1).clamp(0, 9999);
      }

      // Add to history
      _history.add(_today);
      if (_history.length > 7) _history.removeAt(0);

      // Start new day
      currentDate = currentDate.add(const Duration(days: 1));
      _today = DayRecord(dateKey: _dateKey(currentDate));

      if (currentDate.isAtSameMomentAs(todayDate)) {
        _initTodayStates(now);
      } else {
        // Intermediate day - lock all states initially (they will be marked as oadaPending in next iteration)
        for (final p in kPrayers) {
          _today.recordFor(p).state = PrayerState.locked;
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

  // ── Init today's prayer states based on current time ─────────
  void _initTodayStates(DateTime now) {
    for (final p in kPrayers) {
      final rec = _today.recordFor(p);
      rec.state = PrayerTimeService.computeState(prayer: p, now: now, current: PrayerState.locked);
    }
  }

  // ── Persistence ──────────────────────────────────────────────
  static const _kPrefToday   = 'pt2_today';
  static const _kPrefHistory = 'pt2_history';
  static const _kPrefTotal   = 'pt2_total';
  static const _kPrefStreak  = 'pt2_streak';
  static const _kPrefQada    = 'pt2_qada';

  Future<void> _saveData() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kPrefToday,   jsonEncode(_today.toJson()));
    await p.setString(_kPrefHistory, jsonEncode(_history.map((d) => d.toJson()).toList()));
    await p.setDouble(_kPrefTotal,   _grandTotal);
    await p.setInt(_kPrefStreak,     _streak);
    await p.setString(_kPrefQada,    jsonEncode(_pendingQada.map((e) => e.toJson()).toList()));
  }

  Future<void> _loadData() async {
    final p   = await SharedPreferences.getInstance();
    final now = DateTime.now();

    _grandTotal = p.getDouble(_kPrefTotal)  ?? 0;
    _streak     = p.getInt(_kPrefStreak)    ?? 0;

    // Load history
    final histJson = p.getString(_kPrefHistory);
    if (histJson != null) {
      final list = jsonDecode(histJson) as List<dynamic>;
      _history = list.map((e) => DayRecord.fromJson(e as Map<String, dynamic>)).toList();
    }

    // Load pending qada
    final qadaJson = p.getString(_kPrefQada);
    if (qadaJson != null) {
      final list = jsonDecode(qadaJson) as List<dynamic>;
      _pendingQada = list.map((e) => _QadaEntry.fromJson(e as Map<String, dynamic>)).toList();
    }

    // Load today
    final todayJson = p.getString(_kPrefToday);
    if (todayJson != null) {
      final saved = DayRecord.fromJson(jsonDecode(todayJson) as Map<String, dynamic>);
      if (saved.dateKey == _todayKey()) {
        _today = saved;
        // Re-evaluate states for non-final prayers
        for (final pr in kPrayers) {
          final rec = _today.recordFor(pr);
          if (!rec.state.isFinal) {
            rec.state = PrayerTimeService.computeState(
                prayer: pr, now: now, current: rec.state);
          }
        }
      } else {
        // App was closed over a day boundary — roll over all skipped days
        _today = saved;
        _rolloverDay(now);
        return;
      }
    } else {
      _initTodayStates(now);
    }

    if (mounted) setState(() {});
    await _saveData();
  }

  // ── Action: Complete prayer ──────────────────────────────────
  void _completePrayer(PrayerDef p, {required bool congregation}) {
    final rec = _today.recordFor(p);
    if (rec.state.isFinal) return; // already done
    if (rec.state == PrayerState.locked) return; // not available

    HapticFeedback.mediumImpact();
    final newState = congregation
        ? PrayerState.completedCongregation
        : PrayerState.completedIndividual;

    setState(() {
      rec.state = newState;
      rec.scoreAwarded = PrayerTimeService.scoreFor(newState);
    });
    _saveData();
  }

  // ── Action: Complete qada (today's prayer that is now qada) ──
  void _completeQada(PrayerDef p) {
    final rec = _today.recordFor(p);
    if (rec.state != PrayerState.oadaPending) return;

    HapticFeedback.mediumImpact();
    setState(() {
      rec.state = PrayerState.oadaCompleted;
      rec.scoreAwarded = ScoreConstants.qada;
    });
    _saveData();
  }

  // ── Action: Complete carried-over qada ──────────────────────
  void _completeCarryQada(_QadaEntry entry) {
    HapticFeedback.mediumImpact();
    setState(() {
      entry.completed = true;
      _grandTotal = double.parse((_grandTotal + ScoreConstants.qada).toStringAsFixed(2));
    });
    _pendingQada.removeWhere((e) => e.completed);
    _saveData();
  }

  // ── Mark sunnah ──────────────────────────────────────────────
  void _markSunnah(PrayerDef p, int i) {
    final rec = _today.recordFor(p);
    if (rec.completedSunnah.contains(i)) return;
    HapticFeedback.selectionClick();
    setState(() {
      rec.completedSunnah.add(i);
      // Recompute sunnah score for this prayer based on completed count
      rec.sunnahScoreAwarded = PrayerTimeService.sunnahScoreFor(rec.completedSunnah.length);
    });
    _saveData();
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
                  SliverToBoxAdapter(child: _BannerWidget(text: _banner)),
                SliverToBoxAdapter(child: _buildHeroCard()),
                const SliverToBoxAdapter(child: SizedBox(height: 14)),
                SliverToBoxAdapter(child: _buildMiniStats()),
                const SliverToBoxAdapter(child: SizedBox(height: 14)),
                SliverToBoxAdapter(child: _buildScoreCard()),
                const SliverToBoxAdapter(child: SizedBox(height: 14)),
                // Pending qada from previous days
                if (_pendingQada.isNotEmpty)
                  SliverToBoxAdapter(child: _buildQadaSection()),
                if (_pendingQada.isNotEmpty)
                  const SliverToBoxAdapter(child: SizedBox(height: 14)),
                // Today's prayers
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (ctx, i) {
                        final pr  = kPrayers[i];
                        final rec = _today.recordFor(pr);
                        return _PrayerCard(
                          prayer:       pr,
                          record:       rec,
                          onComplete:   (cong) => _completePrayer(pr, congregation: cong),
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
      style: TextStyle(color: _T.t1, fontSize: 18, fontWeight: FontWeight.w800),
    ),
  );

  Widget _buildBg() => AnimatedBuilder(
    animation: _bgCtrl,
    builder: (_, __) => CustomPaint(
      painter: _BgPainter(_bgCtrl.value),
      size: MediaQuery.of(context).size,
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
          border: Border.all(color: _T.jade.withValues(alpha: 0.2), width: 1.2),
          boxShadow: [BoxShadow(color: _T.jade.withValues(alpha: 0.1), blurRadius: 32, offset: const Offset(0, 12))],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 88, height: 88,
              child: CustomPaint(
                painter: _ArcProgressPainter(_progress, _T.jade),
                child: Center(
                  child: Text('${(_progress * 100).toInt()}%',
                      style: const TextStyle(color: _T.jadeSoft, fontSize: 18, fontWeight: FontWeight.w900)),
                ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_progressLabel(),
                      style: const TextStyle(color: _T.t1, fontSize: 20, fontWeight: FontWeight.w900, height: 1.2)),
                  const SizedBox(height: 5),
                  Text('$_prayedCount من ${kPrayers.length} صلوات • $_sunnahDone من $kTotalSunnah سنة',
                      style: const TextStyle(color: _T.t2, fontSize: 13, height: 1.5)),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: _progress,
                      minHeight: 6,
                      backgroundColor: _T.t3.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation(_T.jade),
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
        Expanded(child: _MiniStatCard(icon: Icons.local_fire_department_rounded, label: 'السلسلة',
            value: '$_streak يوم', color: _T.flame)),
        const SizedBox(width: 10),
        Expanded(child: _MiniStatCard(icon: Icons.mosque_rounded, label: 'الفروض',
            value: '$_prayedCount / ${kPrayers.length}', color: _T.jade)),
        const SizedBox(width: 10),
        Expanded(child: _MiniStatCard(icon: Icons.auto_awesome_rounded, label: 'السنن',
            value: '$_sunnahDone / $kTotalSunnah', color: _T.gold)),
      ],
    ),
  );

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
                  const Text('سجل الأيام المنتهية', style: TextStyle(color: _T.t2, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6, runSpacing: 6,
                    children: hist.isEmpty
                        ? [const _DayChip(completed: false, isEmpty: true)]
                        : hist.map((d) => _DayChip(completed: d.totalScore >= kMaxDayScore)).toList(),
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
              Icon(Icons.warning_amber_rounded, color: _T.rubyL, size: 18),
              const SizedBox(width: 8),
              const Text('صلوات قضاء متراكمة', style: TextStyle(color: _T.rubyL, fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          ..._pendingQada.map((e) => _QadaCarryCard(
            entry: e,
            onComplete: () => _completeCarryQada(e),
          )),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
//  Qada Carry Entry
// ─────────────────────────────────────────────────────────────
class _QadaEntry {
  final String prayerName;
  final String dateKey;
  bool completed;

  _QadaEntry({required this.prayerName, required this.dateKey, this.completed = false});

  Map<String, dynamic> toJson() => {
    'prayer': prayerName, 'date': dateKey, 'done': completed,
  };
  factory _QadaEntry.fromJson(Map<String, dynamic> j) => _QadaEntry(
    prayerName: j['prayer'] as String,
    dateKey:    j['date'] as String,
    completed:  j['done'] as bool? ?? false,
  );
}

class _QadaCarryCard extends StatelessWidget {
  final _QadaEntry entry;
  final VoidCallback onComplete;
  const _QadaCarryCard({required this.entry, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.schedule_rounded, color: _T.rubyL, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text('${entry.prayerName} (${entry.dateKey})',
                style: const TextStyle(color: _T.t1, fontSize: 13)),
          ),
          GestureDetector(
            onTap: onComplete,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _T.ruby.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _T.ruby.withValues(alpha: 0.4)),
              ),
              child: const Text('قضيتها', style: TextStyle(color: _T.rubyL, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Day Chip
// ─────────────────────────────────────────────────────────────
class _DayChip extends StatelessWidget {
  final bool completed;
  final bool isEmpty;
  const _DayChip({required this.completed, this.isEmpty = false});

  @override
  Widget build(BuildContext context) {
    Color bg, border, text;
    String label;
    IconData icon;
    if (isEmpty) {
      bg = _T.t3.withValues(alpha: 0.1); border = _T.t3.withValues(alpha: 0.25); text = _T.t3;
      label = 'لا يوجد تاريخ'; icon = Icons.calendar_today_rounded;
    } else if (completed) {
      bg = _T.jade.withValues(alpha: 0.12); border = _T.jade.withValues(alpha: 0.35); text = _T.jade;
      label = 'مكتمل'; icon = Icons.check_circle_rounded;
    } else {
      bg = _T.t3.withValues(alpha: 0.1); border = _T.t3.withValues(alpha: 0.25); text = _T.t3;
      label = 'غير مكتمل'; icon = Icons.remove_circle_outline_rounded;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: text, size: 12),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: text, fontSize: 11.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Banner
// ─────────────────────────────────────────────────────────────
class _BannerWidget extends StatelessWidget {
  final String text;
  const _BannerWidget({required this.text});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _T.flame.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _T.flame.withValues(alpha: 0.25)),
      ),
      child: Text(text, textAlign: TextAlign.center,
          style: const TextStyle(color: _T.flameL, fontSize: 13)),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
//  Prayer Card
// ─────────────────────────────────────────────────────────────
class _PrayerCard extends StatefulWidget {
  final PrayerDef prayer;
  final PrayerRecord record;
  final ValueChanged<bool> onComplete;   // bool = congregation
  final VoidCallback onQada;
  final ValueChanged<int> onMarkSunnah;
  final int index;

  const _PrayerCard({
    required this.prayer,
    required this.record,
    required this.onComplete,
    required this.onQada,
    required this.onMarkSunnah,
    required this.index,
  });

  @override
  State<_PrayerCard> createState() => _PrayerCardState();
}

class _PrayerCardState extends State<_PrayerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _fade;
  late Animation<Offset>   _slide;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this,
        duration: Duration(milliseconds: 500 + widget.index * 80));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: widget.index * 70), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  // ── State-derived visuals ────────────────────────────────────
  Color get _stateColor {
    switch (widget.record.state) {
      case PrayerState.locked:               return _T.t3;
      case PrayerState.available:            return widget.prayer.accent;
      case PrayerState.completedIndividual:  return _T.jade;
      case PrayerState.completedCongregation:return _T.gold;
      case PrayerState.oadaPending:          return _T.ruby;
      case PrayerState.oadaCompleted:        return _T.violet;
    }
  }

  Color get _stateBg {
    switch (widget.record.state) {
      case PrayerState.locked:               return _T.card;
      case PrayerState.available:            return widget.prayer.tint;
      case PrayerState.completedIndividual:  return const Color(0xFF0E1E18);
      case PrayerState.completedCongregation:return const Color(0xFF1A160A);
      case PrayerState.oadaPending:          return const Color(0xFF1E0E0E);
      case PrayerState.oadaCompleted:        return const Color(0xFF120E1A);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p     = widget.prayer;
    final rec   = widget.record;
    final state = rec.state;
    final sc    = _stateColor;

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: _stateBg,
              border: Border.all(
                color: sc.withValues(alpha: state == PrayerState.locked ? 0.12 : 0.4),
                width: state == PrayerState.locked ? 1 : 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: sc.withValues(alpha: state == PrayerState.locked ? 0.05 : 0.15),
                  blurRadius: state == PrayerState.locked ? 8 : 24,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                children: [
                  // Accent stripe (right side — RTL)
                  Positioned(
                    right: 0, top: 0, bottom: 0,
                    child: Container(
                      width: 4,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [sc, sc.withValues(alpha: 0.2)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header row
                        Row(
                          children: [
                            _iconBox(p, sc, state),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(p.name,
                                          style: TextStyle(
                                              color: state == PrayerState.locked ? _T.t3 : _T.t1,
                                              fontSize: 18, fontWeight: FontWeight.w900)),
                                      const SizedBox(width: 8),
                                      _stateBadge(state),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      _RakatDots(rakats: p.rakats, accent: sc,
                                          done: state.isCompleted),
                                      const SizedBox(width: 6),
                                      Text('${p.rakats} ركعات',
                                          style: const TextStyle(color: _T.t3, fontSize: 12)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Action area based on state
                        const SizedBox(height: 12),
                        _buildActionArea(state, p, sc),

                        // Sunnah chips (show when available or completed on time)
                        if (p.sunnah.isNotEmpty &&
                            (state == PrayerState.available ||
                                state == PrayerState.completedIndividual ||
                                state == PrayerState.completedCongregation)) ...[
                          const SizedBox(height: 12),
                          _buildSunnahRow(p, sc, rec),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconBox(PrayerDef p, Color sc, PrayerState state) => Container(
    width: 46, height: 46,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(13),
      color: sc.withValues(alpha: state == PrayerState.locked ? 0.05 : 0.12),
      border: Border.all(color: sc.withValues(alpha: state == PrayerState.locked ? 0.15 : 0.3)),
    ),
    child: Icon(
      state == PrayerState.locked ? Icons.lock_outline_rounded : p.icon,
      color: sc.withValues(alpha: state == PrayerState.locked ? 0.4 : 1),
      size: 22,
    ),
  );

  Widget _stateBadge(PrayerState state) {
    String label;
    Color color;
    IconData icon;

    switch (state) {
      case PrayerState.locked:
        label = 'مغلق'; color = _T.t3; icon = Icons.lock_outline_rounded;
      case PrayerState.available:
        label = 'متاحة'; color = widget.prayer.accent; icon = Icons.radio_button_unchecked_rounded;
      case PrayerState.completedIndividual:
        label = 'فردي'; color = _T.jade; icon = Icons.check_circle_rounded;
      case PrayerState.completedCongregation:
        label = 'جماعة'; color = _T.gold; icon = Icons.groups_rounded;
      case PrayerState.oadaPending:
        label = 'قضاء'; color = _T.ruby; icon = Icons.warning_amber_rounded;
      case PrayerState.oadaCompleted:
        label = 'قُضيت'; color = _T.violet; icon = Icons.check_circle_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 11),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildActionArea(PrayerState state, PrayerDef p, Color sc) {
    switch (state) {
      case PrayerState.locked:
        return _lockedMessage();

      case PrayerState.available:
        return _availableActions();

      case PrayerState.completedIndividual:
        return _completedMessage('أديتها فردياً', _T.jade, Icons.person_rounded);

      case PrayerState.completedCongregation:
        return _completedMessage('أديتها في الجماعة', _T.gold, Icons.groups_rounded);

      case PrayerState.oadaPending:
        return _qadaAction();

      case PrayerState.oadaCompleted:
        return _completedMessage('قُضيت', _T.violet, Icons.check_circle_outline_rounded);
    }
  }

  Widget _lockedMessage() => Row(
    children: [
      Icon(Icons.access_time_rounded, color: _T.t3, size: 14),
      const SizedBox(width: 6),
      const Text('لم يحن وقت الصلاة بعد',
          style: TextStyle(color: _T.t3, fontSize: 12)),
    ],
  );

  Widget _availableActions() => Row(
    children: [
      Expanded(child: _ActionBtn(
        label: 'صليتها جماعة',
        icon: Icons.groups_rounded,
        color: _T.gold,
        onTap: () => widget.onComplete(true),
      )),
      const SizedBox(width: 10),
      Expanded(child: _ActionBtn(
        label: 'صليتها فردي',
        icon: Icons.person_rounded,
        color: _T.jade,
        onTap: () => widget.onComplete(false),
      )),
    ],
  );

  Widget _qadaAction() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: _T.rubyL, size: 14),
          const SizedBox(width: 6),
          const Text('فات وقت الصلاة — تبقّى القضاء',
              style: TextStyle(color: _T.rubyL, fontSize: 12)),
        ],
      ),
      const SizedBox(height: 10),
      GestureDetector(
        onTap: widget.onQada,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: _T.ruby.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _T.ruby.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.refresh_rounded, color: _T.rubyL, size: 16),
              const SizedBox(width: 8),
              const Text('قضيتها الآن', style: TextStyle(color: _T.rubyL, fontSize: 13, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _completedMessage(String text, Color color, IconData icon) => Row(
    children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(width: 8),
      Text(text, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
    ],
  );

  Widget _buildSunnahRow(PrayerDef p, Color sc, PrayerRecord rec) =>
      Align(
        alignment: Alignment.centerRight,
        child: Wrap(
          spacing: 8, runSpacing: 8,
          children: List.generate(p.sunnah.length, (i) {
            final sel = rec.completedSunnah.contains(i);
            return GestureDetector(
              onTap: sel ? null : () => widget.onMarkSunnah(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: sel ? sc.withValues(alpha: 0.18) : _T.bg.withValues(alpha: 0.5),
                  border: Border.all(color: sel ? sc : _T.t3.withValues(alpha: 0.3)),
                  boxShadow: sel ? [BoxShadow(color: sc.withValues(alpha: 0.2), blurRadius: 8)] : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (sel) Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Icon(Icons.check_rounded, color: sc, size: 13),
                    ),
                    Text(p.sunnah[i],
                        style: TextStyle(
                          color: sel ? sc : _T.t2,
                          fontSize: 12.5,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                        )),
                  ],
                ),
              ),
            );
          }),
        ),
      );
}

// ─────────────────────────────────────────────────────────────
//  Action Button
// ─────────────────────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
//  Rakat Dots
// ─────────────────────────────────────────────────────────────
class _RakatDots extends StatelessWidget {
  final int rakats;
  final Color accent;
  final bool done;
  const _RakatDots({required this.rakats, required this.accent, required this.done});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(rakats, (i) => Container(
      width: 7, height: 7,
      margin: const EdgeInsets.only(left: 3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? accent : accent.withValues(alpha: 0.3 + i * 0.1),
        boxShadow: done ? [BoxShadow(color: accent.withValues(alpha: 0.4), blurRadius: 4)] : [],
      ),
    )),
  );
}

// ─────────────────────────────────────────────────────────────
//  Mini Stat Card
// ─────────────────────────────────────────────────────────────
class _MiniStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MiniStatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      color: _T.card,
      border: Border.all(color: color.withValues(alpha: 0.2)),
      boxShadow: [BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4))],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: _T.t3, fontSize: 11)),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────
//  Arc Progress Painter
// ─────────────────────────────────────────────────────────────
class _ArcProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  const _ArcProgressPainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 6;

    canvas.drawCircle(center, radius,
        Paint()..color = color.withValues(alpha: 0.1)..style = PaintingStyle.stroke..strokeWidth = 6);

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2, 2 * pi * progress, false,
        Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 6..strokeCap = StrokeCap.round,
      );
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2, 2 * pi * progress, false,
        Paint()
          ..color = color.withValues(alpha: 0.25)..style = PaintingStyle.stroke
          ..strokeWidth = 12..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
    if (progress > 0.02) {
      final angle = -pi / 2 + 2 * pi * progress;
      canvas.drawCircle(
        Offset(center.dx + radius * cos(angle), center.dy + radius * sin(angle)),
        5,
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcProgressPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────
//  Background Painter
// ─────────────────────────────────────────────────────────────
class _BgPainter extends CustomPainter {
  final double t;
  const _BgPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = const LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFF080D12), Color(0xFF0C1520), Color(0xFF080D12)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.08 + sin(t * 2 * pi) * 25),
      200,
      Paint()
        ..color = const Color(0xFF2EC4A0).withValues(alpha: 0.05)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100),
    );
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.85 + cos(t * 2 * pi) * 20),
      180,
      Paint()
        ..color = const Color(0xFFD4A030).withValues(alpha: 0.04)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100),
    );
    final dot = Paint()..color = Colors.white.withValues(alpha: 0.02);
    const s = 36.0;
    for (double x = 0; x < size.width; x += s) {
      for (double y = 0; y < size.height; y += s) {
        canvas.drawCircle(Offset(x, y), 1, dot);
      }
    }
  }

  @override
  bool shouldRepaint(_BgPainter old) => old.t != t;
}