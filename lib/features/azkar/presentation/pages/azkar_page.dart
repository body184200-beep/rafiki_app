import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static const Color _surface  = Color(0xff08111E);
  static const Color _surfaceB = Color(0xff0C1828);
  static const Color _gold     = Color(0xffC9A84C);
  static const Color _goldLt   = Color(0xffF0CC70);
  static const Color _goldDim  = Color(0xff7A611C);
  static const Color _teal     = Color(0xff2EB88A);
  static const Color _tealLt   = Color(0xff5EFACC);
  static const Color _tealDim  = Color(0xff0D6E52);
  static const Color _indigo   = Color(0xff6B7FD4);   // new: night-sky accent
  static const Color _text     = Color(0xffEDE8D8);
  static const Color _textMid  = Color(0xffA8B4C0);
  static const Color _sub      = Color(0xff5A6E7E);
  static const Color _border   = Color(0xff0E1E30);

  // ── Stars ──────────────────────────────────────────────────────────────────
  late final List<_Star> _stars;
  final Random _rng = Random(13);

  // ── Data ───────────────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> morningAzkar = [
    {"text": "أصبحنا وأصبح الملك لله رب العالمين", "count": 1},
    {"text": "اللهم بك أصبحنا وبك أمسينا وبك نحيا وبك نموت وإليك النشور", "count": 1},
    {"text": "رضيت بالله ربًا وبالإسلام دينًا وبمحمد ﷺ نبيًا", "count": 3},
    {"text": "اللهم إني أصبحت أشهدك وأشهد حملة عرشك وملائكتك وجميع خلقك أنك أنت الله لا إله إلا أنت", "count": 1},
    {"text": "اللهم ما أصبح بي من نعمة أو بأحد من خلقك فمنك وحدك لا شريك لك فلك الحمد ولك الشكر", "count": 1},
    {"text": "أعوذ بكلمات الله التامات من شر ما خلق", "count": 3},
    {"text": "بسم الله الذي لا يضر مع اسمه شيء في الأرض ولا في السماء وهو السميع العليم", "count": 3},
    {"text": "سبحان الله وبحمده", "count": 100},
    {"text": "أستغفر الله وأتوب إليه", "count": 100},
    {"text": "لا إله إلا الله وحده لا شريك له له الملك وله الحمد وهو على كل شيء قدير", "count": 100},
  ];

  final List<Map<String, dynamic>> eveningAzkar = [
    {"text": "أمسينا وأمسى الملك لله رب العالمين", "count": 1},
    {"text": "اللهم بك أمسينا وبك أصبحنا وبك نحيا وبك نموت وإليك المصير", "count": 1},
    {"text": "رضيت بالله ربًا وبالإسلام دينًا وبمحمد ﷺ نبيًا", "count": 3},
    {"text": "اللهم إني أمسيت أشهدك وأشهد حملة عرشك وملائكتك وجميع خلقك أنك أنت الله لا إله إلا أنت", "count": 1},
    {"text": "اللهم ما أمسى بي من نعمة أو بأحد من خلقك فمنك وحدك لا شريك لك فلك الحمد ولك الشكر", "count": 1},
    {"text": "أعوذ بكلمات الله التامات من شر ما خلق", "count": 3},
    {"text": "بسم الله الذي لا يضر مع اسمه شيء في الأرض ولا في السماء وهو السميع العليم", "count": 3},
    {"text": "أمسينا على فطرة الإسلام وعلى كلمة الإخلاص وعلى دين نبينا محمد ﷺ", "count": 1},
    {"text": "سبحان الله وبحمده", "count": 100},
    {"text": "أستغفر الله وأتوب إليه", "count": 100},
    {"text": "اللهم إني أسألك العفو والعافية في الدنيا والآخرة", "count": 1},
  ];

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

    _stars = List.generate(60, (_) => _Star(
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
      builder: (_) => _StyledDialog(
        icon: '💔',
        title: 'انقطع الـ Streak!',
        body: 'لم تقرأ الأذكار لمدة $days أيام.\nتم تصفير النقاط والتقدم.',
        buttonLabel: 'أعود الآن',
      ),
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
                  painter: _StarPainter(stars: _stars, twinkle: _bgCtrl.value),
                ),
              ),

              // ── Nebula blobs ──────────────────────────────────────────────
              Positioned(
                top: -80, left: -80,
                child: _Blob(color: _indigo.withValues(alpha: 0.06), size: 320),
              ),
              Positioned(
                top: 60, right: -100,
                child: _Blob(color: _teal.withValues(alpha: 0.05), size: 260),
              ),
              Positioned(
                bottom: -40, right: -60,
                child: _Blob(color: _gold.withValues(alpha: 0.07), size: 220),
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
                    _AzkarList(
                      azkar: morningAzkar, type: 'morning',
                      progress: progress, onTap: _increase,
                      entryCtrl: _entryCtrl,
                    ),
                    _AzkarList(
                      azkar: eveningAzkar, type: 'evening',
                      progress: progress, onTap: _increase,
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
          _GlassButton(
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
                          painter: _ArcRingPainter(
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
                            child: _ProgressPill(
                              label: '☀️', done: mDone, total: mTotal,
                              color: _gold,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ProgressPill(
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
//  Arc ring painter  — SIGNATURE element
// ─────────────────────────────────────────────────────────────────────────────

class _ArcRingPainter extends CustomPainter {
  final double progress;
  final double animValue;
  final Color  goldColor;
  final Color  tealColor;
  final Color  bgColor;

  const _ArcRingPainter({
    required this.progress,
    required this.animValue,
    required this.goldColor,
    required this.tealColor,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx     = size.width  / 2;
    final cy     = size.height / 2;
    final radius = size.width  / 2 - 5;
    final stroke = 5.0;

    // Track
    canvas.drawCircle(
      Offset(cx, cy),
      radius,
      Paint()
        ..color = bgColor.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );

    // Progress arc (animated)
    final sweepAngle = 2 * pi * progress * animValue;
    if (sweepAngle > 0) {
      final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);
      final arcColor = progress >= 1.0 ? tealColor : goldColor;

      final paint = Paint()
        ..shader = SweepGradient(
          startAngle: -pi / 2,
          endAngle:   -pi / 2 + sweepAngle,
          colors: [
            arcColor.withValues(alpha: 0.4),
            arcColor,
          ],
        ).createShader(rect)
        ..style       = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap   = StrokeCap.round;

      canvas.drawArc(rect, -pi / 2, sweepAngle, false, paint);

      // Glow dot at tip
      if (sweepAngle > 0.1) {
        final tipAngle = -pi / 2 + sweepAngle;
        final tipX     = cx + radius * cos(tipAngle);
        final tipY     = cy + radius * sin(tipAngle);
        canvas.drawCircle(
          Offset(tipX, tipY),
          4.5,
          Paint()
            ..color     = arcColor
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
        canvas.drawCircle(
          Offset(tipX, tipY),
          2.5,
          Paint()..color = Colors.white.withValues(alpha: 0.9),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ArcRingPainter old) =>
      old.progress != progress || old.animValue != animValue;
}

// ─────────────────────────────────────────────────────────────────────────────
//  AzkarList
// ─────────────────────────────────────────────────────────────────────────────

class _AzkarList extends StatelessWidget {
  final List<Map<String, dynamic>>      azkar;
  final String                           type;
  final Map<String, Map<String, int>>   progress;
  final void Function(String, int)       onTap;
  final AnimationController             entryCtrl;

  const _AzkarList({
    required this.azkar,    required this.type,
    required this.progress, required this.onTap,
    required this.entryCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      itemCount: azkar.length,
      itemBuilder: (_, i) {
        final key  = '$type-$i';
        final max  = azkar[i]['count'] as int;
        final cur  = progress[key]?['current'] ?? 0;
        final done = cur >= max;

        final delay = (0.04 + i * 0.07).clamp(0.0, 0.82);
        final end   = (delay + 0.35).clamp(0.0, 1.0);
        final anim  = CurvedAnimation(
          parent: entryCtrl,
          curve: Interval(delay, end, curve: Curves.easeOutCubic),
        );

        return FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 0.12), end: Offset.zero,
            ).animate(anim),
            child: _AzkarCard(
              text: azkar[i]['text'] as String,
              keyId: key, max: max, current: cur, done: done,
              onTap: () => onTap(key, max),
              index: i + 1,
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  AzkarCard
// ─────────────────────────────────────────────────────────────────────────────

class _AzkarCard extends StatefulWidget {
  final String text;
  final String keyId;
  final int    max;
  final int    current;
  final bool   done;
  final VoidCallback onTap;
  final int    index;

  const _AzkarCard({
    required this.text,    required this.keyId,
    required this.max,     required this.current,
    required this.done,    required this.onTap,
    required this.index,
  });

  @override
  State<_AzkarCard> createState() => _AzkarCardState();
}

class _AzkarCardState extends State<_AzkarCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tapCtrl;

  static const Color _teal    = Color(0xff2EB88A);
  static const Color _tealLt  = Color(0xff5EFACC);
  static const Color _tealDim = Color(0xff0D6E52);
  static const Color _gold    = Color(0xffC9A84C);
  static const Color _goldLt  = Color(0xffF0CC70);
  static const Color _text    = Color(0xffEDE8D8);
  static const Color _sub     = Color(0xff5A6E7E);
  static const Color _border  = Color(0xff0E1E30);
  static const Color _surface = Color(0xff08111E);

  @override
  void initState() {
    super.initState();
    _tapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
  }

  @override
  void dispose() { _tapCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final pct = widget.max > 0 ? widget.current / widget.max : 0.0;

    return ScaleTransition(
      scale: Tween(begin: 0.96, end: 1.0).animate(
        CurvedAnimation(parent: _tapCtrl, curve: Curves.easeOut),
      ),
      child: GestureDetector(
        onTapDown:   (_) { if (!widget.done) _tapCtrl.reverse(from: 1); },
        onTapUp:     (_) { _tapCtrl.forward(); if (!widget.done) widget.onTap(); },
        onTapCancel: ()  { _tapCtrl.forward(); },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.done
                  ? [
                _teal.withValues(alpha: 0.12),
                _teal.withValues(alpha: 0.04),
              ]
                  : [
                Colors.white.withValues(alpha: 0.06),
                Colors.white.withValues(alpha: 0.01),
              ],
            ),
            border: Border.all(
              color: widget.done
                  ? _teal.withValues(alpha: 0.38)
                  : Colors.white.withValues(alpha: 0.07),
              width: widget.done ? 1.5 : 1,
            ),
            boxShadow: widget.done
                ? [
              BoxShadow(
                color: _teal.withValues(alpha: 0.10),
                blurRadius: 20, offset: const Offset(0, 6),
              )
            ]
                : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 15, 16, 13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [

                    // ── Top row: index + done tag + count chip ────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Done / index badge
                        widget.done
                            ? _DoneChip()
                            : _IndexBadge(index: widget.index),

                        // Count chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: _gold.withValues(alpha: 0.09),
                            border: Border.all(
                                color: _gold.withValues(alpha: 0.22)),
                          ),
                          child: Text(
                            widget.max == 1 ? 'مرة' : '${widget.max} مرة',
                            style: const TextStyle(
                              color: _gold, fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 13),

                    // ── Dhikr text ────────────────────────────────────────
                    Text(
                      widget.text,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        color: widget.done
                            ? _text.withValues(alpha: 0.55)
                            : _text,
                        fontSize: 15.5,
                        height: 1.8,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ── Bottom row: tap button + progress ─────────────────
                    Row(
                      children: [
                        // Tap button
                        _TapButton(done: widget.done, onTap: widget.onTap),

                        const SizedBox(width: 14),

                        // Progress section
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${(pct * 100).toInt()}%',
                                    style: TextStyle(
                                      color: widget.done
                                          ? _tealLt.withValues(alpha: 0.7)
                                          : _teal.withValues(alpha: 0.8),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    '${widget.current} / ${widget.max}',
                                    style: const TextStyle(
                                        color: _sub, fontSize: 11),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  minHeight: 5,
                                  backgroundColor:
                                  Colors.white.withValues(alpha: 0.06),
                                  valueColor: AlwaysStoppedAnimation(
                                    widget.done ? _tealLt : _teal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Small atomic widgets
// ─────────────────────────────────────────────────────────────────────────────

class _DoneChip extends StatelessWidget {
  const _DoneChip();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xff2EB88A).withValues(alpha: 0.18),
        border: Border.all(color: const Color(0xff2EB88A).withValues(alpha: 0.38)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_rounded, color: Color(0xff5EFACC), size: 13),
          SizedBox(width: 4),
          Text('مكتمل',
              style: TextStyle(
                color: Color(0xff5EFACC), fontSize: 11,
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }
}

class _IndexBadge extends StatelessWidget {
  final int index;
  const _IndexBadge({required this.index});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: Center(
        child: Text(
          '$index',
          style: const TextStyle(
            color: Color(0xff5A6E7E), fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _TapButton extends StatelessWidget {
  final bool done;
  final VoidCallback onTap;
  const _TapButton({required this.done, required this.onTap});

  static const Color _teal    = Color(0xff2EB88A);
  static const Color _tealDim = Color(0xff0D6E52);
  static const Color _tealLt  = Color(0xff5EFACC);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: done ? null : onTap,
      child: Container(
        width: 46, height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: done
              ? null
              : const LinearGradient(colors: [_tealDim, _teal]),
          color: done ? Colors.white.withValues(alpha: 0.04) : null,
          boxShadow: done
              ? []
              : [
            BoxShadow(
              color: _teal.withValues(alpha: 0.4),
              blurRadius: 16, spreadRadius: 0,
            ),
          ],
        ),
        child: Icon(
          done ? Icons.check_rounded : Icons.add_rounded,
          color: done ? _teal.withValues(alpha: 0.5) : Colors.white,
          size: 22,
        ),
      ),
    );
  }
}

class _ProgressPill extends StatelessWidget {
  final String label;
  final int    done;
  final int    total;
  final Color  color;
  const _ProgressPill({
    required this.label, required this.done,
    required this.total, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? done / total : 0.0;
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 6),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct, minHeight: 5,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 5),
        Text('$done/$total',
            style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w700,
            )),
      ],
    );
  }
}

class _GlassButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  const _GlassButton({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.white.withValues(alpha: 0.05),
              border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Dialog
// ─────────────────────────────────────────────────────────────────────────────

class _StyledDialog extends StatelessWidget {
  final String icon, title, body, buttonLabel;
  const _StyledDialog({
    required this.icon,   required this.title,
    required this.body,   required this.buttonLabel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xff08111E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 42)),
          const SizedBox(height: 14),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xffEDE8D8), fontSize: 19,
                fontWeight: FontWeight.w700,
              )),
          const SizedBox(height: 10),
          Text(body,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                color: Color(0xff5A6E7E), height: 1.65, fontSize: 13,
              )),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff2EB88A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(buttonLabel,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Painters
// ─────────────────────────────────────────────────────────────────────────────

class _Star {
  final double x, y, r, phase;
  const _Star({
    required this.x, required this.y,
    required this.r, required this.phase,
  });
}

class _StarPainter extends CustomPainter {
  final List<_Star> stars;
  final double      twinkle;
  const _StarPainter({required this.stars, required this.twinkle});

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in stars) {
      final opacity =
          0.12 + 0.5 * (0.5 + 0.5 * sin((twinkle + s.phase) * 2 * pi));
      canvas.drawCircle(
        Offset(s.x * size.width, s.y * size.height),
        s.r,
        Paint()..color = Colors.white.withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.twinkle != twinkle;
}

class _Blob extends StatelessWidget {
  final Color  color;
  final double size;
  const _Blob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle, color: color,
      boxShadow: [BoxShadow(color: color, blurRadius: size * 0.6)],
    ),
  );
}