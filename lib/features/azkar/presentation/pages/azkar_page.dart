import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rafiki_app/core/theme/theme_provider.dart';
import 'package:rafiki_app/features/azkar/data/datasources/azkar_data.dart';
import 'package:rafiki_app/features/azkar/presentation/widgets/azkar_widgets.dart';
import 'package:rafiki_app/features/notification/presentation/pages/notification_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  AzkarPage  –  Premium, Refined & Lightweight Morning & Evening Adhkar
// ─────────────────────────────────────────────────────────────────────────────

class AzkarPage extends StatefulWidget {
  const AzkarPage({super.key});

  @override
  State<AzkarPage> createState() => _AzkarPageState();
}

class _AzkarPageState extends State<AzkarPage> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final TabController _tabCtrl;

  int totalScore = 0;
  int dailyScore = 0;
  Map<String, Map<String, int>> progress = {};
  DateTime? lastReadDate;
  Timer? _dayCheckTimer;
  Timer? _saveDebouncer;
  bool _rolloverInProgress = false;
  double _fontSize = 16.5;

  static bool get _l => ThemeProvider.instance.isLight;
  static Color get _bg => _l ? const Color(0xFFF8F7F3) : const Color(0xff060A12);
  static Color get _cardBg => _l ? const Color(0xFFFFFFFF) : const Color(0xff0D1524);
  static Color get _cardBorder => _l ? const Color(0xFFE5E7EB) : const Color(0xff182438);
  static Color get _gold => _l ? const Color(0xFF926315) : const Color(0xffD4AF37);
  static Color get _goldLt => _l ? const Color(0xFFFEF3C7) : const Color(0xff2A2312);
  static Color get _teal => _l ? const Color(0xFF0F4A39) : const Color(0xff2EB88A);
  static Color get _tealLt => _l ? const Color(0xFFE6F4EF) : const Color(0xff122E28);
  static Color get _textMain => _l ? const Color(0xFF111827) : const Color(0xffEDE8D8);
  static Color get _textSub => _l ? const Color(0xFF6B7280) : const Color(0xff889BB0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Context-aware initial tab (Morning vs Evening)
    final currentHour = DateTime.now().hour;
    final isMorningTime = currentHour >= 4 && currentHour < 13;
    _tabCtrl = TabController(length: 2, vsync: this, initialIndex: isMorningTime ? 0 : 1);
    _tabCtrl.addListener(() {
      if (mounted) setState(() {});
    });

    _load();

    _dayCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkDayChange();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabCtrl.dispose();
    _dayCheckTimer?.cancel();
    _saveDebouncer?.cancel();
    super.dispose();
  }

  // ── Persistence ────────────────────────────────────────────────────────────
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    totalScore = prefs.getInt('totalScore') ?? prefs.getInt('score') ?? 0;
    dailyScore = prefs.getInt('dailyScore') ?? 0;
    _fontSize = prefs.getDouble('azkar_font_size') ?? 16.5;

    final saved = prefs.getStringList('progress') ?? [];
    progress = {
      for (var e in saved)
        if (e.contains('|'))
          e.split('|')[0]: {
            'current': int.tryParse(e.split('|')[1]) ?? 0,
            'max': int.tryParse(e.split('|')[2]) ?? 1,
          }
    };

    final rawDate = prefs.getString('lastReadDate');
    lastReadDate = rawDate != null ? DateTime.tryParse(rawDate) : null;

    final now = DateTime.now();
    if (lastReadDate != null) {
      final diff = _calendarDayDiff(lastReadDate!, now);
      if (diff >= 1) {
        _rolloverInProgress = true;
        await _performDayRollover(prefs, diff, now);
        _rolloverInProgress = false;
      }
    } else {
      lastReadDate = now;
      await prefs.setString('lastReadDate', now.toIso8601String());
    }

    if (mounted) setState(() {});
  }

  int _calendarDayDiff(DateTime a, DateTime b) {
    final aDate = DateTime(a.year, a.month, a.day);
    final bDate = DateTime(b.year, b.month, b.day);
    return bDate.difference(aDate).inDays;
  }

  Future<void> _checkDayChange() async {
    if (!mounted || _rolloverInProgress) return;
    final now = DateTime.now();
    if (lastReadDate == null) return;

    final diff = _calendarDayDiff(lastReadDate!, now);
    if (diff >= 1) {
      _rolloverInProgress = true;
      final prefs = await SharedPreferences.getInstance();
      await _performDayRollover(prefs, diff, now);
      _rolloverInProgress = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _performDayRollover(
      SharedPreferences prefs, int diff, DateTime now) async {
    progress.clear();
    await prefs.setStringList('progress', []);

    if (diff >= 2) {
      totalScore = 0;
      dailyScore = 0;
      await prefs.setInt('totalScore', 0);
      await prefs.setInt('dailyScore', 0);
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => _showStreakLostDialog(diff));
    } else {
      totalScore += dailyScore;
      dailyScore = 0;
      await prefs.setInt('totalScore', totalScore);
      await prefs.setInt('dailyScore', 0);
    }

    lastReadDate = now;
    await prefs.setString('lastReadDate', now.toIso8601String());
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('totalScore', totalScore);
    await prefs.setInt('dailyScore', dailyScore);
    await prefs.setDouble('azkar_font_size', _fontSize);
    final currentAzkar = totalScore > 0 ? totalScore : dailyScore;
    final highestAzkar = prefs.getInt('highest_azkar_streak') ?? 0;
    if (currentAzkar > highestAzkar) {
      await prefs.setInt('highest_azkar_streak', currentAzkar);
    }
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
        dailyScore += 1;
        lastReadDate = DateTime.now();
        if (progress[key]!['current'] == max) {
          HapticFeedback.heavyImpact();
        }
      }
    });

    _saveDebouncer?.cancel();
    _saveDebouncer = Timer(const Duration(milliseconds: 300), () {
      _save();
    });
  }

  void _resetZekr(String key) {
    HapticFeedback.mediumImpact();
    setState(() {
      if (progress.containsKey(key)) {
        final cur = progress[key]?['current'] ?? 0;
        dailyScore = (dailyScore - cur).clamp(0, 999999);
        progress[key]?['current'] = 0;
      }
    });
    _save();
  }

  void _resetAllInTab(String type, List<Map<String, dynamic>> list) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: _cardBorder)),
        title: Text('إعادة تعيين العدادات', style: TextStyle(color: _textMain, fontWeight: FontWeight.bold, fontSize: 17)),
        content: Text('هل ترغب في تصفير عدادات هذا القسم للبدء من جديد؟', style: TextStyle(color: _textSub, fontSize: 13.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: TextStyle(color: _textSub)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                for (int i = 0; i < list.length; i++) {
                  final k = '$type-$i';
                  if (progress.containsKey(k)) {
                    final cur = progress[k]?['current'] ?? 0;
                    dailyScore = (dailyScore - cur).clamp(0, 999999);
                    progress[k]?['current'] = 0;
                  }
                }
              });
              _save();
            },
            child: const Text('نعم، إعادة التعيين'),
          ),
        ],
      ),
    );
  }

  int _completedCount(List list, String type) {
    int done = 0;
    for (int i = 0; i < list.length; i++) {
      final k = '$type-$i';
      final cur = progress[k]?['current'] ?? 0;
      final max = list[i]['count'] as int;
      if (cur >= max) done++;
    }
    return done;
  }

  void _showStreakLostDialog(int days) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => StyledDialog(
        icon: '💔',
        title: 'انقطع التتابع!',
        body: 'لم تقرأ الأذكار لمدة $days أيام.\nتم تصفير النقاط لتبدأ من جديد بقوة.',
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

  void _changeFontSize(double delta) {
    setState(() {
      _fontSize = (_fontSize + delta).clamp(14.0, 22.0);
    });
    _save();
  }

  @override
  Widget build(BuildContext context) {
    final morningDone = _completedCount(morningAzkar, 'morning');
    final eveningDone = _completedCount(eveningAzkar, 'evening');
    final totalMorning = morningAzkar.length;
    final totalEvening = eveningAzkar.length;

    final isMorningTab = _tabCtrl.index == 0;
    final activeDone = isMorningTab ? morningDone : eveningDone;
    final activeTotal = isMorningTab ? totalMorning : totalEvening;
    final activePercent = activeTotal > 0 ? (activeDone / activeTotal).clamp(0.0, 1.0) : 0.0;
    final allActiveDone = activeDone == activeTotal && activeTotal > 0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'أذكار الصباح والمساء',
            style: TextStyle(
              color: _textMain,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: _textMain, size: 20),
            tooltip: 'رجوع',
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            // Font Size Controls (A- / A+)
            IconButton(
              icon: const Text('أ-', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              tooltip: 'تصغير الخط',
              onPressed: () => _changeFontSize(-1.5),
            ),
            IconButton(
              icon: const Text('أ+', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              tooltip: 'تكبير الخط',
              onPressed: () => _changeFontSize(1.5),
            ),
            // Reminder Notification Button
            IconButton(
              icon: Icon(Icons.alarm_add_rounded, color: _teal, size: 22),
              tooltip: 'تذكير الأذكار',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationPage()),
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // ── Inspiring Islamic Header Card ──────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: _cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: _l ? 0.03 : 0.22),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Circular Progress Indicator
                        SizedBox(
                          width: 58,
                          height: 58,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: activePercent,
                                strokeWidth: 5.5,
                                backgroundColor: _cardBorder,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  allActiveDone ? _gold : _teal,
                                ),
                              ),
                              Text(
                                '${(activePercent * 100).toInt()}%',
                                style: TextStyle(
                                  color: _textMain,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Stats & Motivational Text
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  // Daily Score Pill
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _tealLt,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.bolt_rounded, size: 14, color: _teal),
                                        const SizedBox(width: 3),
                                        Text(
                                          'اليوم: $dailyScore',
                                          style: TextStyle(color: _teal, fontSize: 11.5, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Total Hasanat Pill
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _goldLt,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.stars_rounded, size: 14, color: _gold),
                                        const SizedBox(width: 3),
                                        Text(
                                          'الرصيد: ${totalScore + dailyScore}',
                                          style: TextStyle(color: _gold, fontSize: 11.5, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isMorningTab
                                    ? '☀️ أذكار الصباح حفظٌ وبركة لنشاط يومك'
                                    : '🌙 أذكار المساء سكونٌ وحصنٌ لليلتك',
                                style: TextStyle(
                                  color: _textSub,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Reset All Button
                        if (activeDone > 0)
                          IconButton(
                            icon: Icon(Icons.refresh_rounded, size: 20, color: _textSub),
                            tooltip: 'إعادة تصفير القسم',
                            onPressed: () => _resetAllInTab(
                              isMorningTab ? 'morning' : 'evening',
                              isMorningTab ? morningAzkar : eveningAzkar,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                      decoration: BoxDecoration(
                        color: _l ? const Color(0xFFF9F7F1) : const Color(0xFF090F1C),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          '﴿ أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ ﴾',
                          style: TextStyle(
                            color: _gold,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Modern Tab Bar ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
              child: Container(
                height: 48,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _cardBorder),
                ),
                child: TabBar(
                  controller: _tabCtrl,
                  indicator: BoxDecoration(
                    color: isMorningTab
                        ? (_l ? const Color(0xFFFEF3C7) : const Color(0xFF262012))
                        : (_l ? const Color(0xFFE0F2FE) : const Color(0xFF102538)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isMorningTab ? _gold.withValues(alpha: 0.6) : const Color(0xFF38BDF8),
                      width: 1.2,
                    ),
                  ),
                  labelColor: isMorningTab ? _gold : const Color(0xFF0284C7),
                  unselectedLabelColor: _textSub,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.wb_sunny_rounded, size: 16),
                          const SizedBox(width: 6),
                          Text('أذكار الصباح ($morningDone/$totalMorning)'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.nightlight_round, size: 16),
                          const SizedBox(width: 6),
                          Text('أذكار المساء ($eveningDone/$totalEvening)'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Azkar List ──────────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _buildAzkarList(morningAzkar, 'morning', isMorning: true),
                  _buildAzkarList(eveningAzkar, 'evening', isMorning: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAzkarList(List<Map<String, dynamic>> list, String type, {required bool isMorning}) {
    final completed = _completedCount(list, type);
    final isAllCompleted = completed == list.length && list.isNotEmpty;

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      itemCount: list.length + (isAllCompleted ? 1 : 0),
      itemBuilder: (context, i) {
        // Celebratory Banner at top when 100% completed
        if (isAllCompleted && i == 0) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _tealLt,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _teal.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _teal,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'هنيئاً لك! أتممت الأذكار بالكامل ✨',
                        style: TextStyle(color: _teal, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'تقبّل الله طاعتك وأدام ذكرك وحصنك بحصنه المتين.',
                        style: TextStyle(color: _textSub, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final index = isAllCompleted ? i - 1 : i;
        final item = list[index];
        final text = item['text'] as String? ?? item['zekr'] as String? ?? '';
        final maxCount = item['count'] as int? ?? 1;
        final keyId = '$type-$index';
        final currentCount = progress[keyId]?['current'] ?? 0;
        final isDone = currentCount >= maxCount;

        return _AzkarItemCard(
          text: text,
          index: index + 1,
          currentCount: currentCount,
          maxCount: maxCount,
          isDone: isDone,
          fontSize: _fontSize,
          isLight: _l,
          cardBg: _cardBg,
          cardBorder: _cardBorder,
          teal: _teal,
          tealLt: _tealLt,
          gold: _gold,
          textMain: _textMain,
          textSub: _textSub,
          onTap: isDone ? null : () => _increase(keyId, maxCount),
          onReset: () => _resetZekr(keyId),
          onSetReminder: () => _setReminderForZekr(text, isMorning: isMorning),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Tactile, Animated Dhikr Card Widget
// ─────────────────────────────────────────────────────────────────────────────

class _AzkarItemCard extends StatefulWidget {
  final String text;
  final int index;
  final int currentCount;
  final int maxCount;
  final bool isDone;
  final double fontSize;
  final bool isLight;
  final Color cardBg;
  final Color cardBorder;
  final Color teal;
  final Color tealLt;
  final Color gold;
  final Color textMain;
  final Color textSub;
  final VoidCallback? onTap;
  final VoidCallback onReset;
  final VoidCallback onSetReminder;

  const _AzkarItemCard({
    required this.text,
    required this.index,
    required this.currentCount,
    required this.maxCount,
    required this.isDone,
    required this.fontSize,
    required this.isLight,
    required this.cardBg,
    required this.cardBorder,
    required this.teal,
    required this.tealLt,
    required this.gold,
    required this.textMain,
    required this.textSub,
    required this.onTap,
    required this.onReset,
    required this.onSetReminder,
  });

  @override
  State<_AzkarItemCard> createState() => _AzkarItemCardState();
}

class _AzkarItemCardState extends State<_AzkarItemCard> with SingleTickerProviderStateMixin {
  late final AnimationController _scaleCtrl;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.98,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.onTap == null) return;
    _scaleCtrl.reverse().then((_) {
      if (mounted) _scaleCtrl.forward();
    });
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.maxCount - widget.currentCount;

    return ScaleTransition(
      scale: _scaleCtrl,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: widget.isDone ? widget.tealLt : widget.cardBg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: widget.isDone ? widget.teal.withValues(alpha: 0.45) : widget.cardBorder,
            width: widget.isDone ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: widget.isLight ? 0.03 : 0.16),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: widget.isDone ? null : _handleTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Row: Status badge & Utilities
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: widget.isDone
                              ? widget.teal.withValues(alpha: 0.18)
                              : (widget.isLight ? const Color(0xFFF3F4F6) : const Color(0xFF152033)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.isDone ? Icons.check_circle_rounded : Icons.flare_rounded,
                              size: 14,
                              color: widget.isDone ? widget.teal : widget.gold,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              widget.isDone
                                  ? 'مكتمل بحمد الله'
                                  : 'الذكر ${widget.index} • ${widget.maxCount == 1 ? "مرة واحدة" : "يكرّر ${widget.maxCount} مرات"}',
                              style: TextStyle(
                                color: widget.isDone ? widget.teal : widget.textSub,
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Quick Action Buttons
                      Row(
                        children: [
                          if (widget.currentCount > 0)
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: Icon(Icons.refresh_rounded, size: 18, color: widget.textSub),
                              tooltip: 'إعادة العداد',
                              onPressed: widget.onReset,
                            ),
                          const SizedBox(width: 12),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(Icons.copy_rounded, size: 17, color: widget.textSub),
                            tooltip: 'نسخ الذكر',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: widget.text));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('تم نسخ الذكر بنجاح ✨'),
                                  duration: Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(Icons.notifications_active_outlined, size: 18, color: widget.teal),
                            tooltip: 'تذكير بهذا الذكر',
                            onPressed: widget.onSetReminder,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Dhikr Text (Clean Typography & Size Control)
                  Text(
                    widget.text,
                    style: TextStyle(
                      color: widget.textMain,
                      fontSize: widget.fontSize,
                      height: 1.88,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Bottom Action Row: Progress status & Tactile Tasbih Counter Button
                  Row(
                    children: [
                      // Progress Bar & Count Text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.isDone
                                  ? 'تم إتمام القراءة (${widget.maxCount}/${widget.maxCount})'
                                  : 'التقدم: ${widget.currentCount} من ${widget.maxCount} (بقي $remaining)',
                              style: TextStyle(
                                color: widget.isDone ? widget.teal : widget.textSub,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: widget.maxCount > 0
                                    ? (widget.currentCount / widget.maxCount).clamp(0.0, 1.0)
                                    : 0.0,
                                minHeight: 7,
                                backgroundColor: widget.cardBorder,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  widget.isDone ? widget.teal : const Color(0xFF38BDF8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 18),

                      // Tactile Digital Tasbih Button (Circle with Shadow)
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.isDone ? widget.teal : widget.teal,
                          boxShadow: widget.isDone
                              ? []
                              : [
                                  BoxShadow(
                                    color: widget.teal.withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                        ),
                        child: Center(
                          child: widget.isDone
                              ? const Icon(Icons.check_rounded, color: Colors.white, size: 28)
                              : Text(
                                  '$remaining',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
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
    );
  }
}
