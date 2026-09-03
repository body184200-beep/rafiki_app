import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rafiki_app/features/azkar/presentation/widgets/azkar_widgets.dart';
import 'package:rafiki_app/features/azkar/presentation/widgets/azkar_painters.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:rafiki_app/features/azkar/data/datasources/azkar_data.dart';
import 'package:rafiki_app/features/notification/presentation/pages/notification_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  AzkarPage  –  Morning & Evening Adhkar
// ─────────────────────────────────────────────────────────────────────────────

class AzkarPage extends StatefulWidget {
  const AzkarPage({super.key});

  @override
  State<AzkarPage> createState() => _AzkarPageState();
}

class _AzkarPageState extends State<AzkarPage> with TickerProviderStateMixin, WidgetsBindingObserver {

  // ── Controllers ────────────────────────────────────────────────────────────
  late final TabController     _tabCtrl;
  late final AnimationController _bgCtrl;
  late final AnimationController _entryCtrl;
  late final AnimationController _scoreCtrl;
  late final AnimationController _arcCtrl;

  // ── State ──────────────────────────────────────────────────────────────────
  // totalScore  : cumulative score across all days (persists forever, shown
  //               at the very top of the page).
  // dailyScore  : points earned ONLY today. At the start of a new calendar
  //               day this value is folded into totalScore and reset to 0.
  int  totalScore = 0;
  int  dailyScore = 0;
  // ignore: unused_field
  int  _prevScore = 0; // reference value used by the score-bump animation
  Map<String, Map<String, int>> progress = {};
  DateTime? lastReadDate;
  Timer? _dayCheckTimer;

  // Guards against the day-rollover (azkar reset + score migration) running
  // twice for the same day — e.g. if _load() and the periodic
  // _checkDayChange() timer both detect the date change at nearly the same
  // moment (a classic race condition around midnight).
  bool _rolloverInProgress = false;

  Timer? _saveDebouncer;

  // ── Palette ────────────────────────────────────────────────────────────────
  static const Color _bg       = Color(0xff030810);

  static const Color _surfaceB = Color(0xff0C1828);
  static const Color _gold     = Color(0xffC9A84C);
  static const Color _goldLt   = Color(0xffF0CC70);
  static const Color _goldDim  = Color(0xff7A611C);
  static const Color _teal     = Color(0xff2EB88A);
  static const Color _tealLt   = Color(0xff5EFACC);
  static const Color _tealDim  = Color(0xff0D6E52);
  static const Color _indigo   = Color(0xff6B7FD4);   // new: night-sky accent

  static const Color _textMid  = Color(0xffA8B4C0);
  static const Color _sub      = Color(0xff5A6E7E);
  static const Color _border   = Color(0xff0E1E30);

  // ── Stars ──────────────────────────────────────────────────────────────────
  late final List<Star> _stars;
  final Random _rng = Random(13);

  // ── Data ───────────────────────────────────────────────────────────────────

  // ── Init ───────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _tabCtrl  = TabController(length: 2, vsync: this);
    _bgCtrl   = AnimationController(
        vsync: this, duration: const Duration(seconds: 18))
      ..repeat(reverse: true);
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 950))
      ..forward();
    _scoreCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _arcCtrl   = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..forward();

    _stars = List.generate(60, (_) => Star(
      x:     _rng.nextDouble(),
      y:     _rng.nextDouble(),
      r:     0.4 + _rng.nextDouble() * 1.6,
      phase: _rng.nextDouble(),
    ));

    _load();

    // Check for day/midnight changes every 30 seconds
    _dayCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkDayChange();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabCtrl.dispose();
    _bgCtrl.dispose();
    _entryCtrl.dispose();
    _scoreCtrl.dispose();
    _arcCtrl.dispose();
    _dayCheckTimer?.cancel();
    _saveDebouncer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_bgCtrl.isAnimating) _bgCtrl.repeat(reverse: true);
    } else if (state == AppLifecycleState.paused) {
      _bgCtrl.stop();
    }
  }

  // ── Persistence ────────────────────────────────────────────────────────────
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    // One-time migration: older versions of the app stored a single
    // cumulative value under the 'score' key. We preserve that value as the
    // new totalScore so no historical points are ever lost, and the new
    // dailyScore counter starts fresh at 0.
    totalScore = prefs.getInt('totalScore') ?? prefs.getInt('score') ?? 0;
    dailyScore = prefs.getInt('dailyScore') ?? 0;
    _prevScore = dailyScore;

    final saved = prefs.getStringList('progress') ?? [];
    progress = {
      for (var e in saved)
        if (e.contains('|'))
          e.split('|')[0]: {
            'current': int.tryParse(e.split('|')[1]) ?? 0,
            'max':     int.tryParse(e.split('|')[2]) ?? 1,
          }
    };

    final lastStr = prefs.getString('lastReadDate');
    if (lastStr != null) lastReadDate = DateTime.tryParse(lastStr);

    if (lastReadDate != null && !_rolloverInProgress) {
      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day);
      final lastReadDateOnly = DateTime(lastReadDate!.year, lastReadDate!.month, lastReadDate!.day);
      final diff = todayDate.difference(lastReadDateOnly).inDays;

      if (diff >= 1) {
        _rolloverInProgress = true;
        await _performDayRollover(prefs, diff, now);
        _rolloverInProgress = false;
      }
    }

    if (mounted) {
      setState(() {});
      _arcCtrl.forward(from: 0);
    }
  }

  Future<void> _checkDayChange() async {
    if (lastReadDate == null || _rolloverInProgress) return;

    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final lastReadDateOnly = DateTime(lastReadDate!.year, lastReadDate!.month, lastReadDate!.day);
    final diff = todayDate.difference(lastReadDateOnly).inDays;

    if (diff >= 1) {
      _rolloverInProgress = true;
      final prefs = await SharedPreferences.getInstance();
      await _performDayRollover(prefs, diff, now);
      if (mounted) setState(() {});
      _rolloverInProgress = false;
    }
  }

  /// Centralized day-rollover handler — the single source of truth for what
  /// happens when a new calendar day starts. Called from BOTH _load()
  /// (covers the "app was closed across midnight" case) and the periodic
  /// _checkDayChange() timer (covers the "app stayed open across midnight"
  /// case), so the logic only ever lives in one place.
  ///
  /// Behaviour:
  ///  • diff == 1 (a normal new day): the daily azkar ticks are cleared,
  ///    today's dailyScore is folded into totalScore, then dailyScore is
  ///    reset to 0. No points are lost — they simply move from "today" to
  ///    "total".
  ///  • diff >= 2 (the user missed at least one full day → streak broken):
  ///    preserves the existing app behaviour of wiping totalScore and
  ///    dailyScore back to 0 and showing the "streak lost" dialog, in
  ///    addition to clearing the daily azkar ticks.
  ///
  /// `lastReadDate` is updated and persisted to disk as the very last step,
  /// which is what prevents this from ever running twice for the same day:
  /// once it succeeds, `diff` will be 0 until the next calendar day begins.
  Future<void> _performDayRollover(
      SharedPreferences prefs, int diff, DateTime now) async {
    // Daily azkar completion state always belongs to the day that just
    // ended — reset it for the new day. The azkar texts/settings themselves
    // are untouched; only today's tick progress is cleared.
    progress.clear();
    await prefs.setStringList('progress', []);

    if (diff >= 2) {
      // Streak broken — existing app behaviour: reset everything to 0.
      totalScore = 0;
      dailyScore = 0;
      await prefs.setInt('totalScore', 0);
      await prefs.setInt('dailyScore', 0);
      WidgetsBinding.instance.addPostFrameCallback(
              (_) => _showStreakLostDialog(diff));
    } else {
      // Normal new day: migrate yesterday's daily score into the running
      // total, then start the daily counter fresh at 0.
      totalScore += dailyScore;
      dailyScore = 0;
      await prefs.setInt('totalScore', totalScore);
      await prefs.setInt('dailyScore', 0);
    }

    // Mark "now" as processed so neither _load() nor _checkDayChange() can
    // trigger another rollover until the next real calendar day begins.
    lastReadDate = now;
    await prefs.setString('lastReadDate', now.toIso8601String());
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('totalScore', totalScore);
    await prefs.setInt('dailyScore', dailyScore);
    await prefs.setStringList(
      'progress',
      progress.entries
          .map((e) => '${e.key}|${e.value["current"]}|${e.value["max"]}')
          .toList(),
    );
    if (lastReadDate != null) {
      await prefs.setString('lastReadDate', lastReadDate!.toIso8601String());
    }
  }

  void _increase(String key, int max) {
    HapticFeedback.lightImpact();
    setState(() {
      progress[key] ??= {'current': 0, 'max': max};
      if (progress[key]!['current']! < max) {
        progress[key]!['current'] = progress[key]!['current']! + 1;
        _prevScore  = dailyScore;
        dailyScore += 1;
        lastReadDate = DateTime.now();
        _scoreCtrl.forward(from: 0);
        _arcCtrl.forward(from: 0);
        if (progress[key]!['current'] == max) {
          HapticFeedback.mediumImpact();
        }
      }
    });
    
    _saveDebouncer?.cancel();
    _saveDebouncer = Timer(const Duration(milliseconds: 300), () {
      _save();
    });
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  int _completedCount(List list, String type) {
    int done = 0;
    for (int i = 0; i < list.length; i++) {
      final k   = '$type-$i';
      final cur = progress[k]?['current'] ?? 0;
      final max = list[i]['count'] as int;
      if (cur >= max) done++;
    }
    return done;
  }

  double get _totalProgress {
    final total  = morningAzkar.length + eveningAzkar.length;
    final mDone  = _completedCount(morningAzkar, 'morning');
    final eDone  = _completedCount(eveningAzkar, 'evening');
    return total > 0 ? (mDone + eDone) / total : 0.0;
  }

  bool get _isMorning => DateTime.now().hour < 13;

  String get _greeting {
    return _isMorning ? 'صباح النور' : 'مساء الخير';
  }

  void _showStreakLostDialog(int days) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => StyledDialog(
        icon: '💔',
        title: 'انقطع الـ Streak!',
        body: 'لم تقرأ الأذكار لمدة $days أيام.\nتم تصفير النقاط والتقدم.',
        buttonLabel: 'أعود الآن',
      ),
    );
  }

  void _setReminderForZekr(String text, {required bool isMorning}) {
    NotificationFormSheet.show(
      context,
      initialZekr: text,
      initialTitle: isMorning ? 'أذكار الصباح' : 'أذكار المساء',
      initialTime: isMorning
          ? const TimeOfDay(hour: 7, minute: 0)
          : const TimeOfDay(hour: 17, minute: 0),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      extendBodyBehindAppBar: true,
      body: AnimatedBuilder(
        animation: Listenable.merge([_bgCtrl, _scoreCtrl, _arcCtrl]),
        builder: (ctx, child) {
          return Stack(
            children: [
              // ── Deep space gradient ───────────────────────────────────────
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topCenter,
                      radius: 1.4,
                      colors: [
                        Color.lerp(
                          const Color(0xff060D1A),
                          const Color(0xff0A1530),
                          _bgCtrl.value,
                        )!,
                        _bg,
                      ],
                    ),
                  ),
                ),
              ),

              // ── Stars ─────────────────────────────────────────────────────
              Positioned.fill(
                child: CustomPaint(
                  painter: StarPainter(stars: _stars, twinkle: _bgCtrl.value),
                ),
              ),

              // ── Nebula blobs ──────────────────────────────────────────────
              Positioned(
                top: -80, left: -80,
                child: Blob(color: _indigo.withValues(alpha: 0.06), size: 320),
              ),
              Positioned(
                top: 60, right: -100,
                child: Blob(color: _teal.withValues(alpha: 0.05), size: 260),
              ),
              Positioned(
                bottom: -40, right: -60,
                child: Blob(color: _gold.withValues(alpha: 0.07), size: 220),
              ),

              child!,
            ],
          );
        },
        child: SafeArea(
          child: Column(
            children: [
              // Total score is now the FIRST element the user sees on the page.
              _buildTotalScoreBar(),
              _buildTopBar(),
              const SizedBox(height: 4),
              _buildScoreHeader(),
              const SizedBox(height: 12),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabCtrl,
                  children: [
                    AzkarList(
                      azkar: morningAzkar,
                      type: 'morning',
                      progress: progress,
                      onTap: _increase,
                      onSetReminder: (text) => _setReminderForZekr(text, isMorning: true),
                      entryCtrl: _entryCtrl,
                    ),
                    AzkarList(
                      azkar: eveningAzkar,
                      type: 'evening',
                      progress: progress,
                      onTap: _increase,
                      onSetReminder: (text) => _setReminderForZekr(text, isMorning: false),
                      entryCtrl: _entryCtrl,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Total score bar (NEW – always the first visible element) ───────────────
  Widget _buildTotalScoreBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _gold.withValues(alpha: 0.18),
                  _gold.withValues(alpha: 0.05),
                ],
              ),
              border: Border.all(color: _gold.withValues(alpha: 0.28)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.workspace_premium_rounded,
                        color: _goldLt, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'إجمالي النقاط',
                      style: TextStyle(
                        color: _textMid, fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                ShaderMask(
                  shaderCallback: (r) => const LinearGradient(
                    colors: [_gold, _goldLt],
                  ).createShader(r),
                  child: Text(
                    '$totalScore',
                    style: const TextStyle(
                      color: Colors.white, fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Top bar ────────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GlassButton(
            onTap: () => Navigator.maybePop(context),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white70, size: 16),
          ),
          Column(
            children: [
              ShaderMask(
                shaderCallback: (r) => const LinearGradient(
                  colors: [_gold, _goldLt],
                ).createShader(r),
                child: const Text(
                  '✦  الأذكار  ✦',
                  style: TextStyle(
                    color: Colors.white, fontSize: 18,
                    fontWeight: FontWeight.w700, letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _greeting,
                style: const TextStyle(
                  color: _sub, fontSize: 11, letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  // ── Score header with arc ring (shows TODAY'S score) ────────────────────────
  Widget _buildScoreHeader() {
    final mDone  = _completedCount(morningAzkar, 'morning');
    final eDone  = _completedCount(eveningAzkar, 'evening');
    final mTotal = morningAzkar.length;
    final eTotal = eveningAzkar.length;
    final pct    = _totalProgress;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.07),
                  Colors.white.withValues(alpha: 0.02),
                ],
              ),
              border: Border.all(color: _gold.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                // ── Arc Score Badge (today's score) ─────────────────────
                AnimatedBuilder(
                  animation: Listenable.merge([_scoreCtrl, _arcCtrl]),
                  builder: (_, __) {
                    final bounce = 1.0 + 0.12 * sin(_scoreCtrl.value * pi).clamp(0.0, 1.0);
                    return Transform.scale(
                      scale: bounce,
                      child: SizedBox(
                        width: 72,
                        height: 72,
                        child: CustomPaint(
                          painter: ArcRingPainter(
                            progress: pct,
                            animValue: _arcCtrl.value,
                            goldColor: _gold,
                            tealColor: _teal,
                            bgColor: _border,
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$dailyScore',
                                  style: const TextStyle(
                                    color: _goldLt,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                    height: 1,
                                  ),
                                ),
                                const Text(
                                  'اليوم',
                                  style: TextStyle(
                                    color: _goldDim,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(width: 18),

                // ── Right side info ──────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Total progress text
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${(pct * 100).toInt()}% مكتمل',
                            style: TextStyle(
                              color: pct >= 1.0 ? _tealLt : _textMid,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (pct >= 1.0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _teal.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: _teal.withValues(alpha: 0.3)),
                              ),
                              child: const Text('أحسنت! 🌟',
                                  style: TextStyle(
                                    color: _tealLt, fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  )),
                            ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Progress pills
                      Row(
                        children: [
                          Expanded(
                            child: ProgressPill(
                              label: '☀️', done: mDone, total: mTotal,
                              color: _gold,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ProgressPill(
                              label: '🌙', done: eDone, total: eTotal,
                              color: _teal,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Horizon thin line
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 3,
                          backgroundColor: _border,
                          valueColor: AlwaysStoppedAnimation(
                            pct >= 1.0 ? _teal : _gold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Tab bar ────────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: _surfaceB.withValues(alpha: 0.7),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: TabBar(
              controller: _tabCtrl,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  colors: [_tealDim, _teal],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _teal.withValues(alpha: 0.25),
                    blurRadius: 14,
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: _sub,
              labelStyle: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('☀️', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 7),
                      const Text('الصباح'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🌙', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 7),
                      const Text('المساء'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
