import 'dart:math';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Tahdey  –  Islamic Companions Challenge Tracker  (enhanced)
// ─────────────────────────────────────────────────────────────────────────────

class Tahdey extends StatefulWidget {
  const Tahdey({super.key});

  @override
  State<Tahdey> createState() => _TahdeyState();
}

class _TahdeyState extends State<Tahdey> with TickerProviderStateMixin {

  // ── Controllers ────────────────────────────────────────────────────────────
  late final ConfettiController _confetti;
  late final AnimationController _bgCtrl;
  late final AnimationController _entryCtrl;
  late final AnimationController _xpPulseCtrl;
  late final ScrollController _chipScroll;

  // ── State ──────────────────────────────────────────────────────────────────
  int selectedIndex = 0;
  int xp = 0;
  int level = 1;
  int streak = 0;
  Map<String, Set<int>> doneTasks = {};
  List<String> badges = [];
  String lastDay = "";

  // ── Palette ────────────────────────────────────────────────────────────────
  static const Color _bg      = Color(0xff040A10);
  static const Color _surface = Color(0xff0C1820);
  static const Color _gold    = Color(0xffC9A84C);
  static const Color _goldLt  = Color(0xffF5D882);
  static const Color _jade    = Color(0xff2EB88A);
  static const Color _jadeLt  = Color(0xff5EFACC);
  static const Color _amber   = Color(0xffE8943A);
  static const Color _text    = Color(0xffEEE8D5);
  static const Color _sub     = Color(0xff6E8594);

  // ── Stars ──────────────────────────────────────────────────────────────────
  late final List<_Star> _stars;
  final Random _rng = Random(13);

  // ── Companions data ────────────────────────────────────────────────────────
  final Map<String, Map<String, dynamic>> days = {
    "النبي ﷺ": {
      "emoji": "☪️",
      "color": const Color(0xffC9A84C),
      "tasks": [
        {"title": "قيام الليل",          "icon": Icons.nightlight_round},
        {"title": "صلاة الفجر جماعة",    "icon": Icons.wb_sunny},
        {"title": "أذكار الصباح والمساء","icon": Icons.auto_stories},
        {"title": "الدعوة إلى الله",     "icon": Icons.campaign},
        {"title": "الصدقة",             "icon": Icons.volunteer_activism},
        {"title": "صلة الرحم",          "icon": Icons.family_restroom},
      ],
    },
    "أبو بكر الصديق": {
      "emoji": "🌟",
      "color": const Color(0xff5B8EE8),
      "tasks": [
        {"title": "صلاة الفجر",         "icon": Icons.wb_sunny},
        {"title": "الصدقة السرية",      "icon": Icons.volunteer_activism},
        {"title": "الدفاع عن الإسلام",  "icon": Icons.shield},
        {"title": "ذكر الله",           "icon": Icons.auto_stories},
        {"title": "صحبة النبي ﷺ",       "icon": Icons.person},
      ],
    },
    "عمر بن الخطاب": {
      "emoji": "⚖️",
      "color": const Color(0xffE84343),
      "tasks": [
        {"title": "العدل بين الناس",    "icon": Icons.gavel},
        {"title": "تفقد الرعية",        "icon": Icons.people},
        {"title": "صلاة الفجر",         "icon": Icons.wb_sunny},
        {"title": "قوة الحق",           "icon": Icons.security},
        {"title": "إقامة الدولة",       "icon": Icons.account_balance},
      ],
    },
    "عثمان بن عفان": {
      "emoji": "📖",
      "color": const Color(0xff2EB88A),
      "tasks": [
        {"title": "قراءة القرآن",         "icon": Icons.menu_book},
        {"title": "تجهيز جيش العسرة",    "icon": Icons.sports_martial_arts},
        {"title": "الحياء",              "icon": Icons.self_improvement},
        {"title": "الصدقة",             "icon": Icons.volunteer_activism},
        {"title": "نسخ المصحف",          "icon": Icons.book},
      ],
    },
    "علي بن أبي طالب": {
      "emoji": "🏅",
      "color": const Color(0xffA855F7),
      "tasks": [
        {"title": "العلم والقضاء",       "icon": Icons.school},
        {"title": "الشجاعة في المعارك", "icon": Icons.shield},
        {"title": "الذكر",              "icon": Icons.auto_stories},
        {"title": "الزهد والتقوى",      "icon": Icons.favorite},
        {"title": "نصرة الحق",          "icon": Icons.gavel},
      ],
    },
    "طلحة بن عبيد الله": {
      "emoji": "🛡️",
      "color": const Color(0xffE8943A),
      "tasks": [
        {"title": "حماية النبي ﷺ",      "icon": Icons.shield},
        {"title": "الكرم والجود",        "icon": Icons.volunteer_activism},
        {"title": "نصرة المسلمين",      "icon": Icons.handshake},
        {"title": "الجهاد",             "icon": Icons.sports_martial_arts},
      ],
    },
    "الزبير بن العوام": {
      "emoji": "⚔️",
      "color": const Color(0xff64748B),
      "tasks": [
        {"title": "الجهاد",             "icon": Icons.sports_martial_arts},
        {"title": "الصلاة",             "icon": Icons.mosque},
        {"title": "نصرة الدين",         "icon": Icons.shield},
        {"title": "الشجاعة",            "icon": Icons.security},
      ],
    },
    "عبد الرحمن بن عوف": {
      "emoji": "💼",
      "color": const Color(0xff0EA5E9),
      "tasks": [
        {"title": "التجارة الحلال",     "icon": Icons.business_center},
        {"title": "الصدقة الكبيرة",    "icon": Icons.volunteer_activism},
        {"title": "دعم المسلمين",       "icon": Icons.handshake},
        {"title": "الزهد في المال",     "icon": Icons.savings},
      ],
    },
    "سعد بن أبي وقاص": {
      "emoji": "🏹",
      "color": const Color(0xff16A34A),
      "tasks": [
        {"title": "الدعاء",             "icon": Icons.auto_stories},
        {"title": "قيادة الجيوش",       "icon": Icons.sports_martial_arts},
        {"title": "الرمية الأولى",      "icon": Icons.emoji_events},
        {"title": "الجهاد",             "icon": Icons.shield},
      ],
    },
    "خالد بن الوليد": {
      "emoji": "🗡️",
      "color": const Color(0xffDC2626),
      "tasks": [
        {"title": "قيادة المعارك",      "icon": Icons.sports_martial_arts},
        {"title": "الجهاد",             "icon": Icons.shield},
        {"title": "الانتصارات",         "icon": Icons.emoji_events},
      ],
    },
    "بلال بن رباح": {
      "emoji": "🔔",
      "color": const Color(0xff7C3AED),
      "tasks": [
        {"title": "رفع الأذان",         "icon": Icons.volume_up},
        {"title": "الصبر على التعذيب",  "icon": Icons.favorite},
        {"title": "الثبات على الإسلام","icon": Icons.shield},
      ],
    },
    "سلمان الفارسي": {
      "emoji": "🌍",
      "color": const Color(0xff059669),
      "tasks": [
        {"title": "طلب العلم",          "icon": Icons.menu_book},
        {"title": "الحكمة",             "icon": Icons.psychology},
        {"title": "حفر الخندق",         "icon": Icons.construction},
      ],
    },
    "أنس بن مالك": {
      "emoji": "📜",
      "color": const Color(0xffD97706),
      "tasks": [
        {"title": "خدمة النبي ﷺ",       "icon": Icons.person},
        {"title": "حفظ الحديث",         "icon": Icons.auto_stories},
        {"title": "نقل السنة",          "icon": Icons.menu_book},
      ],
    },
  };

  // ── Init / Dispose ─────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    _confetti = ConfettiController(duration: const Duration(seconds: 2));

    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat(reverse: true);

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _xpPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _chipScroll = ScrollController();

    _stars = List.generate(60, (_) => _Star(
      x: _rng.nextDouble(),
      y: _rng.nextDouble(),
      r: 0.5 + _rng.nextDouble() * 1.6,
      phase: _rng.nextDouble(),
    ));

    _loadData();
  }

  @override
  void dispose() {
    _confetti.dispose();
    _bgCtrl.dispose();
    _entryCtrl.dispose();
    _xpPulseCtrl.dispose();
    _chipScroll.dispose();
    super.dispose();
  }

  // ── Persistence Keys ───────────────────────────────────────────────────────
  static const _kPrefXP = 'tahdey_xp';
  static const _kPrefLevel = 'tahdey_level';
  static const _kPrefStreak = 'tahdey_streak';
  static const _kPrefDoneTasks = 'tahdey_done_tasks';
  static const _kPrefBadges = 'tahdey_badges';
  static const _kPrefLastDay = 'tahdey_last_day';

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      xp = prefs.getInt(_kPrefXP) ?? 0;
      level = prefs.getInt(_kPrefLevel) ?? 1;
      streak = prefs.getInt(_kPrefStreak) ?? 0;
      badges = prefs.getStringList(_kPrefBadges) ?? [];
      lastDay = prefs.getString(_kPrefLastDay) ?? "";

      final tasksJson = prefs.getString(_kPrefDoneTasks);
      if (tasksJson != null) {
        final decoded = jsonDecode(tasksJson) as Map<String, dynamic>;
        doneTasks = decoded.map((k, v) => MapEntry(k, Set<int>.from(v as List)));
      } else {
        doneTasks = {};
      }
    });
    _checkDailyReset();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kPrefXP, xp);
    await prefs.setInt(_kPrefLevel, level);
    await prefs.setInt(_kPrefStreak, streak);
    await prefs.setStringList(_kPrefBadges, badges);
    await prefs.setString(_kPrefLastDay, lastDay);

    final encodedTasks = doneTasks.map((k, v) => MapEntry(k, v.toList()));
    await prefs.setString(_kPrefDoneTasks, jsonEncode(encodedTasks));
  }

  // ── Logic ──────────────────────────────────────────────────────────────────
  String _today() => DateTime.now().toString().substring(0, 10);
  double get _xpProgress => (xp % 5) / 5;

  void _checkDailyReset() {
    final todayStr = _today();
    if (lastDay != todayStr) {
      setState(() {
        if (doneTasks.isNotEmpty) {
          streak++;
        } else {
          if (lastDay.isNotEmpty) {
            streak = 0;
          }
        }
        doneTasks.clear();
        lastDay = todayStr;
      });
      _saveData();
    }
  }

  void _updateLevel() {
    final newLevel = (xp / 5).floor() + 1;
    if (newLevel > level) {
      level = newLevel;
      HapticFeedback.mediumImpact();
      _confetti.play();
      if (level == 2 && !badges.contains("🥉 مبتدئ"))   badges.add("🥉 مبتدئ");
      if (level == 5 && !badges.contains("🥈 قوي"))     badges.add("🥈 قوي");
      if (level == 10 && !badges.contains("🏆 أسطورة")) badges.add("🏆 أسطورة");
    }
  }

  void _toggleTask(String name, int i) {
    doneTasks.putIfAbsent(name, () => {});
    setState(() {
      if (doneTasks[name]!.contains(i)) {
        doneTasks[name]!.remove(i);
        xp = max(0, xp - 2);
      } else {
        doneTasks[name]!.add(i);
        xp += 2;
        HapticFeedback.lightImpact();
        _confetti.play();
        _xpPulseCtrl.forward(from: 0);
      }
      _updateLevel();
    });
    _saveData();
  }

  void _resetAll() {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (_) => _ConfirmDialog(
        onConfirm: () => setState(() {
          xp = 0; level = 1; streak = 0;
          doneTasks.clear(); badges.clear();
          _saveData();
        }),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final keys      = days.keys.toList();
    final current   = keys[selectedIndex];
    final data      = days[current]!;
    final tasks     = data["tasks"] as List;
    final accent    = data["color"] as Color;
    final doneCount = doneTasks[current]?.length ?? 0;

    return Scaffold(
      backgroundColor: _bg,
      extendBodyBehindAppBar: true,
      body: AnimatedBuilder(
        animation: _bgCtrl,
        builder: (ctx, child) {
          return Stack(
            children: [
              // ── Background ──────────────────────────────────────────────
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _bg,
                        Color.lerp(_surface,
                            accent.withOpacity(0.08), _bgCtrl.value)!,
                        _bg,
                      ],
                    ),
                  ),
                ),
              ),

              // ── Stars ───────────────────────────────────────────────────
              Positioned.fill(
                child: CustomPaint(
                  painter: _StarPainter(
                    stars: _stars,
                    twinkle: _bgCtrl.value,
                  ),
                ),
              ),

              // ── Glow blobs ───────────────────────────────────────────────
              Positioned(
                top: -80, left: -60,
                child: _Blob(color: accent.withOpacity(0.08), size: 300),
              ),
              Positioned(
                bottom: 20, right: -70,
                child: _Blob(color: _gold.withOpacity(0.07), size: 260),
              ),

              // ── Confetti ─────────────────────────────────────────────────
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confetti,
                  blastDirectionality: BlastDirectionality.explosive,
                  numberOfParticles: 20,
                  colors: [_gold, _goldLt, accent, Colors.white],
                ),
              ),

              child!,
            ],
          );
        },
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(accent),
              _buildHeroStats(accent),
              const SizedBox(height: 12),
              _buildCompanionChips(keys, accent),
              const SizedBox(height: 12),
              _buildSessionHeader(current, data, doneCount, tasks.length, accent),
              const SizedBox(height: 8),
              Expanded(child: _buildTaskList(tasks, current, accent)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top bar ────────────────────────────────────────────────────────────────
  Widget _buildTopBar(Color accent) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _GlassButton(
            onTap: () => Navigator.maybePop(context),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white70, size: 16),
          ),
          ShaderMask(
            shaderCallback: (r) => const LinearGradient(
              colors: [_gold, _goldLt],
            ).createShader(r),
            child: const Text(
              "✦  تحدي الصحابة  ✦",
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.8,
              ),
            ),
          ),
          _GlassButton(
            onTap: _resetAll,
            child: const Icon(Icons.restart_alt_rounded,
                color: Colors.redAccent, size: 18),
          ),
        ],
      ),
    );
  }

  // ── Hero stats card ────────────────────────────────────────────────────────
  Widget _buildHeroStats(Color accent) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.08),
                  Colors.white.withOpacity(0.03),
                ],
              ),
              border: Border.all(color: _gold.withOpacity(0.18)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // XP badge
                    AnimatedBuilder(
                      animation: _xpPulseCtrl,
                      builder: (_, __) {
                        final s = 1.0 + 0.12 *
                            sin(_xpPulseCtrl.value * pi).clamp(0.0, 1.0);
                        return Transform.scale(
                          scale: s,
                          child: _StatBadge(
                            value: "$xp",
                            label: "XP",
                            colorA: _gold,
                            colorB: _goldLt,
                          ),
                        );
                      },
                    ),

                    const SizedBox(width: 12),

                    // Level badge
                    _StatBadge(
                      value: "$level",
                      label: "LVL",
                      colorA: accent,
                      colorB: accent.withOpacity(0.6),
                    ),

                    const SizedBox(width: 12),

                    // Streak badge
                    _StatBadge(
                      value: "$streak",
                      label: "🔥",
                      colorA: _amber,
                      colorB: _amber.withOpacity(0.6),
                    ),

                    const Spacer(),

                    // Badges
                    if (badges.isNotEmpty)
                      Wrap(
                        spacing: 4,
                        children: badges.map((b) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: _gold.withOpacity(0.12),
                            border: Border.all(
                                color: _gold.withOpacity(0.3)),
                          ),
                          child: Text(b,
                              style: const TextStyle(
                                  fontSize: 10, color: _goldLt)),
                        )).toList(),
                      ),
                  ],
                ),

                const SizedBox(height: 14),

                // XP progress bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "المستوى ${level + 1} — ${(xp % 5 * 2).toInt()}/10 XP",
                          style: const TextStyle(
                              color: _sub, fontSize: 10),
                        ),
                        Text(
                          "${(_xpProgress * 100).toInt()}%",
                          style: TextStyle(
                              color: accent, fontSize: 10,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _xpProgress,
                        minHeight: 7,
                        backgroundColor: Colors.white.withOpacity(0.07),
                        valueColor: AlwaysStoppedAnimation(accent),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Companion chips ────────────────────────────────────────────────────────
  Widget _buildCompanionChips(List<String> keys, Color accent) {
    return SizedBox(
      height: 46,
      child: ListView.builder(
        controller: _chipScroll,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: keys.length,
        itemBuilder: (context, i) {
          final selected = i == selectedIndex;
          final chipColor = days[keys[i]]!["color"] as Color;
          final emoji     = days[keys[i]]!["emoji"] as String;
          final done      = doneTasks[keys[i]];
          final allDone   = done != null &&
              done.length ==
                  (days[keys[i]]!["tasks"] as List).length;

          return GestureDetector(
            onTap: () {
              setState(() => selectedIndex = i);
              _entryCtrl.forward(from: 0);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(23),
                gradient: selected
                    ? LinearGradient(colors: [
                  chipColor,
                  chipColor.withOpacity(0.65)
                ])
                    : null,
                color: selected ? null : Colors.white.withOpacity(0.07),
                border: Border.all(
                  color: selected
                      ? chipColor
                      : allDone
                      ? chipColor.withOpacity(0.4)
                      : Colors.white.withOpacity(0.10),
                  width: selected ? 1.5 : 1,
                ),
                boxShadow: selected
                    ? [
                  BoxShadow(
                    color: chipColor.withOpacity(0.35),
                    blurRadius: 12,
                    spreadRadius: 1,
                  )
                ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 5),
                  Text(
                    keys[i],
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : _sub,
                      fontSize: 12.5,
                      fontWeight: selected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                  if (allDone) ...[
                    const SizedBox(width: 5),
                    const Icon(Icons.check_circle_rounded,
                        color: Colors.white70, size: 13),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Session header ─────────────────────────────────────────────────────────
  Widget _buildSessionHeader(
      String name, Map data, int done, int total, Color accent) {
    final pct = total > 0 ? done / total : 0.0;
    final emoji = data["emoji"] as String;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: accent.withOpacity(0.08),
              border: Border.all(color: accent.withOpacity(0.22)),
            ),
            child: Row(
              children: [
                // Big emoji
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withOpacity(0.15),
                    border: Border.all(color: accent.withOpacity(0.35)),
                  ),
                  child: Center(
                    child: Text(emoji,
                        style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: _text,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: pct,
                                minHeight: 5,
                                backgroundColor:
                                Colors.white.withOpacity(0.08),
                                valueColor:
                                AlwaysStoppedAnimation(accent),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "$done/$total",
                            style: TextStyle(
                              color: accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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

  // ── Task list ──────────────────────────────────────────────────────────────
  Widget _buildTaskList(List tasks, String current, Color accent) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: tasks.length,
      itemBuilder: (context, i) {
        final done = doneTasks[current]?.contains(i) ?? false;
        final delay = (i * 0.08).clamp(0.0, 0.7);
        final end   = (delay + 0.4).clamp(0.0, 1.0);

        final anim = CurvedAnimation(
          parent: _entryCtrl,
          curve: Interval(delay, end, curve: Curves.easeOutCubic),
        );

        return FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0.05, 0),
              end: Offset.zero,
            ).animate(anim),
            child: _TaskCard(
              title: tasks[i]["title"] as String,
              icon:  tasks[i]["icon"]  as IconData,
              done:  done,
              accent: accent,
              index: i + 1,
              onTap: () => _toggleTask(current, i),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TaskCard
// ─────────────────────────────────────────────────────────────────────────────

class _TaskCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final bool done;
  final Color accent;
  final int index;
  final VoidCallback onTap;

  const _TaskCard({
    required this.title,
    required this.icon,
    required this.done,
    required this.accent,
    required this.index,
    required this.onTap,
  });

  @override
  State<_TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<_TaskCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 110));
    _scale = Tween(begin: 1.0, end: 0.96)
        .animate(CurvedAnimation(parent: _press, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final acc = widget.accent;

    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: (_) => _press.forward(),
        onTapUp: (_) { _press.reverse(); widget.onTap(); },
        onTapCancel: () => _press.reverse(),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.done
                  ? [
                acc.withOpacity(0.18),
                acc.withOpacity(0.07),
              ]
                  : [
                Colors.white.withOpacity(0.07),
                Colors.white.withOpacity(0.02),
              ],
            ),
            border: Border.all(
              color: widget.done
                  ? acc.withOpacity(0.50)
                  : Colors.white.withOpacity(0.09),
              width: widget.done ? 1.5 : 1,
            ),
            boxShadow: widget.done
                ? [
              BoxShadow(
                color: acc.withOpacity(0.16),
                blurRadius: 14,
                offset: const Offset(0, 4),
              )
            ]
                : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    // Icon bubble
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.done
                            ? acc.withOpacity(0.25)
                            : Colors.white.withOpacity(0.07),
                        border: Border.all(
                          color: widget.done
                              ? acc.withOpacity(0.50)
                              : Colors.white.withOpacity(0.10),
                        ),
                      ),
                      child: Icon(
                        widget.icon,
                        color: widget.done ? acc : const Color(0xff6E8594),
                        size: 20,
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Text(
                        widget.title,
                        style: TextStyle(
                          color: widget.done
                              ? const Color(0xffEEE8D5)
                              : const Color(0xffB0C4CE),
                          fontSize: 15,
                          fontWeight: widget.done
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Check indicator
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.done
                            ? acc.withOpacity(0.2)
                            : Colors.transparent,
                        border: Border.all(
                          color: widget.done
                              ? acc
                              : Colors.white.withOpacity(0.20),
                          width: 1.5,
                        ),
                      ),
                      child: widget.done
                          ? Icon(Icons.check_rounded,
                          color: acc, size: 16)
                          : null,
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
//  Reusable widgets & painters
// ─────────────────────────────────────────────────────────────────────────────

class _StatBadge extends StatelessWidget {
  final String value, label;
  final Color colorA, colorB;
  const _StatBadge({
    required this.value,
    required this.label,
    required this.colorA,
    required this.colorB,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54, height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorA, colorB],
        ),
        boxShadow: [
          BoxShadow(
            color: colorA.withOpacity(0.35),
            blurRadius: 14,
            spreadRadius: 1,
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  height: 1)),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 9,
                  fontWeight: FontWeight.w600)),
        ],
      ),
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
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.white.withOpacity(0.06),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final Color color;
  final double size;
  const _Blob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color,
      boxShadow: [BoxShadow(color: color, blurRadius: size * 0.5)],
    ),
  );
}

class _ConfirmDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  const _ConfirmDialog({required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xff0C1820),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("🔄", style: TextStyle(fontSize: 36)),
          const SizedBox(height: 12),
          const Text(
            "تصفير كل التقدم؟",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xffEEE8D5),
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "سيتم حذف XP والمستوى والـ Streak",
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xff6E8594), fontSize: 13),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: BorderSide(
                        color: Colors.white.withOpacity(0.15)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("إلغاء"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    onConfirm();
                  },
                  child: const Text("تصفير"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Star {
  final double x, y, r, phase;
  const _Star(
      {required this.x,
        required this.y,
        required this.r,
        required this.phase});
}

class _StarPainter extends CustomPainter {
  final List<_Star> stars;
  final double twinkle;
  _StarPainter({required this.stars, required this.twinkle});

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in stars) {
      final opacity =
          0.12 + 0.45 * (0.5 + 0.5 * sin((twinkle + s.phase) * 2 * pi));
      canvas.drawCircle(
        Offset(s.x * size.width, s.y * size.height),
        s.r,
        Paint()..color = Colors.white.withOpacity(opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.twinkle != twinkle;
}