import 'dart:convert';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Design Tokens
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  static const bg       = Color(0xff06080D);
  static const surf     = Color(0xff0D1117);
  static const surf2    = Color(0xff131A24);
  static const surf3    = Color(0xff1B2332);
  static const acc      = Color(0xff4ECBA8);
  static const acc2     = Color(0xff2E9E7A);
  static const acc3     = Color(0xff1B6B53);
  static const txt      = Color(0xffECF0F8);
  static const txt2     = Color(0xff8896AB);
  static const txt3     = Color(0xff4D5A6C);
  static const border   = Color(0xff1E2A38);
  static const border2  = Color(0xff253040);
  static const errorBg  = Color(0xff1E0808);
  static const errorAcc = Color(0xffE24B4A);
}

// ─────────────────────────────────────────────────────────────────────────────
//  Constants
// ─────────────────────────────────────────────────────────────────────────────
const _readyAzkar = <String>[
  'سبحان الله وبحمده سبحان الله العظيم',
  'لا إله إلا الله وحده لا شريك له',
  'اللهم صل وسلم على نبينا محمد',
  'أستغفر الله العظيم وأتوب إليه',
  'لا حول ولا قوة إلا بالله',
  'حسبي الله ونعم الوكيل',
  'اللهم اغفر لي ولوالدي',
  'اللهم ارزقني الجنة وأجرني من النار',
];

const _days = <Map<String, String>>[
  {'label': 'السبت',    'short': 'سبت'},
  {'label': 'الأحد',    'short': 'أحد'},
  {'label': 'الاثنين',  'short': 'إثن'},
  {'label': 'الثلاثاء', 'short': 'ثلا'},
  {'label': 'الأربعاء', 'short': 'أرب'},
  {'label': 'الخميس',   'short': 'خمس'},
  {'label': 'الجمعة',   'short': 'جمع'},
];

const _dayMap = <String, int>{
  'السبت':    DateTime.saturday,
  'الأحد':    DateTime.sunday,
  'الاثنين':  DateTime.monday,
  'الثلاثاء': DateTime.tuesday,
  'الأربعاء': DateTime.wednesday,
  'الخميس':   DateTime.thursday,
  'الجمعة':   DateTime.friday,
};

// ─────────────────────────────────────────────────────────────────────────────
//  Page
// ─────────────────────────────────────────────────────────────────────────────
class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage>
    with TickerProviderStateMixin {
  // Controllers
  final _zekrController = TextEditingController();
  final _scrollController = ScrollController();

  // State
  TimeOfDay _selectedTime = const TimeOfDay(hour: 5, minute: 30);
  final List<String> _selectedDays = [];
  bool _isSaving = false;

  // Animations
  late final AnimationController _headerAnim;
  late final Animation<double> _headerFade;

  // ── Lifecycle ────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _headerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _headerFade = CurvedAnimation(
      parent: _headerAnim,
      curve: Curves.easeOut,
    );
    _headerAnim.forward();

    _zekrController.text = _readyAzkar.first;
    _initNotifications();
    _requestPermission();
    _loadData();
  }

  @override
  void dispose() {
    _zekrController.dispose();
    _scrollController.dispose();
    _headerAnim.dispose();
    super.dispose();
  }

  // ── Notifications ────────────────────────────────────────────────────

  Future<void> _initNotifications() async {
    await AwesomeNotifications().initialize(null, [
      NotificationChannel(
        channelKey: 'azkar_channel',
        channelName: 'Azkar Notifications',
        channelDescription: 'Daily Azkar Reminder',
        importance: NotificationImportance.Max,
        defaultColor: _T.acc,
        channelShowBadge: true,
      ),
    ]);
  }

  Future<void> _requestPermission() async {
    final allowed = await AwesomeNotifications().isNotificationAllowed();
    if (!allowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  Future<void> _scheduleNotifications() async {
    await AwesomeNotifications().cancelAll();
    for (var i = 0; i < _selectedDays.length; i++) {
      final weekday = _dayMap[_selectedDays[i]] ?? DateTime.monday;
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: i + 1,
          channelKey: 'azkar_channel',
          title: '🤍 ذكر لطيف ليومك',
          body: _zekrController.text.trim(),
          notificationLayout: NotificationLayout.BigText,
        ),
        schedule: NotificationCalendar(
          weekday: weekday,
          hour: _selectedTime.hour,
          minute: _selectedTime.minute,
          second: 0,
          repeats: true,
          allowWhileIdle: true,
        ),
      );
    }
  }

  // ── Persistence ──────────────────────────────────────────────────────

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'notification_data',
      jsonEncode({
        'zekr': _zekrController.text.trim(),
        'hour': _selectedTime.hour,
        'minute': _selectedTime.minute,
        'days': _selectedDays,
      }),
    );
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('notification_data');
    if (raw == null) return;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _zekrController.text = m['zekr'] as String? ?? _readyAzkar.first;
        _selectedTime = TimeOfDay(
          hour: (m['hour'] as num).toInt(),
          minute: (m['minute'] as num).toInt(),
        );
        _selectedDays
          ..clear()
          ..addAll(List<String>.from(m['days'] as List? ?? []));
      });
    } catch (_) {}
  }

  // ── Actions ──────────────────────────────────────────────────────────

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _T.acc,
            onPrimary: _T.bg,
            surface: _T.surf3,
            onSurface: _T.txt,
          ),
          timePickerTheme: TimePickerThemeData(
            backgroundColor: _T.surf,
            hourMinuteColor: _T.surf3,
            hourMinuteTextColor: _T.txt,
            dialBackgroundColor: _T.surf3,
            dialHandColor: _T.acc,
            entryModeIconColor: _T.txt2,
            dialTextColor: WidgetStateColor.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                  ? _T.bg
                  : _T.txt,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _onSave() async {
    final text = _zekrController.text.trim();
    if (text.isEmpty) {
      _showSnack('يرجى كتابة أو اختيار ذكر أولاً', isError: true);
      return;
    }
    if (_selectedDays.isEmpty) {
      _showSnack('يرجى اختيار يوم واحد على الأقل', isError: true);
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);
    try {
      await _saveData();
      await _scheduleNotifications();
      _showSnack('تم تفعيل التذكير بنجاح ✨');
    } catch (_) {
      _showSnack('حدث خطأ أثناء الحفظ', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                color: isError ? _T.errorAcc : _T.acc,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  msg,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(color: _T.txt, fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: isError ? _T.errorBg : _T.surf3,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isError
                  ? _T.errorAcc.withValues(alpha: 0.4)
                  : _T.acc2.withValues(alpha: 0.35),
            ),
          ),
          duration: const Duration(seconds: 3),
          elevation: 0,
        ),
      );
  }

  // ── Widget Helpers ───────────────────────────────────────────────────

  /// Section label
  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Text(
      text,
      style: const TextStyle(
        color: _T.txt3,
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
      ),
    ),
  );

  /// Glassmorphic card container
  Widget _card({required Widget child, VoidCallback? onTap}) {
    Widget inner = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _T.surf,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _T.border),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff0D1117), Color(0xff0A0F18)],
        ),
      ),
      child: child,
    );
    if (onTap != null) {
      inner = GestureDetector(onTap: onTap, child: inner);
    }
    return inner;
  }

  // ─────────────────────────────────────────────────────────────────────
  //  Sections
  // ─────────────────────────────────────────────────────────────────────

  Widget _readyAzkarSection() => _card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('اختر ذكراً جاهزاً'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _readyAzkar.map((z) {
            final isActive = _zekrController.text == z;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _zekrController.text = z);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? _T.acc3.withValues(alpha: 0.22)
                      : _T.surf2,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isActive ? _T.acc2 : _T.border2,
                    width: isActive ? 1.5 : 1,
                  ),
                  boxShadow: isActive
                      ? [
                    BoxShadow(
                      color: _T.acc.withValues(alpha: 0.12),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ]
                      : null,
                ),
                child: Text(
                  z,
                  style: TextStyle(
                    color: isActive ? _T.acc : _T.txt2,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    ),
  );

  Widget _customZekrSection() => _card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('أو اكتب ذكراً مخصصاً'),
        AnimatedBuilder(
          animation: _zekrController,
          builder: (_, __) => TextField(
            controller: _zekrController,
            maxLines: 3,
            style: const TextStyle(
              color: _T.txt,
              fontSize: 15,
              height: 1.8,
            ),
            cursorColor: _T.acc,
            cursorRadius: const Radius.circular(2),
            decoration: InputDecoration(
              hintText: 'اكتب ذكرك هنا...',
              hintStyle: const TextStyle(color: _T.txt3, fontSize: 14),
              filled: true,
              fillColor: _T.surf2,
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _T.border2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _T.acc2, width: 1.5),
              ),
              // char counter styled subtly
              counterStyle: const TextStyle(color: _T.txt3, fontSize: 11),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    ),
  );

  Widget _timeSection() => _card(
    onTap: _pickTime,
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _T.acc3.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.access_time_rounded,
            color: _T.acc,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('وقت التذكير'),
            Builder(
              builder: (ctx) {
                final timeStr = _selectedTime.format(ctx);
                return Text(
                  timeStr,
                  style: const TextStyle(
                    color: _T.txt,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                    height: 1,
                  ),
                );
              },
            ),
          ],
        ),
        const Spacer(),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _T.surf2,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _T.border2),
          ),
          child: const Icon(
            Icons.chevron_left_rounded,
            color: _T.txt3,
            size: 20,
          ),
        ),
      ],
    ),
  );

  Widget _daysSection() => _card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('أيام التذكير'),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: _days.map((d) {
            final label = d['label']!;
            final short = d['short']!;
            final isSel = _selectedDays.contains(label);
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  if (isSel) {
                    _selectedDays.remove(label);
                  } else {
                    _selectedDays.add(label);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSel ? _T.acc3.withValues(alpha: 0.22) : _T.surf2,
                  border: Border.all(
                    color: isSel ? _T.acc : _T.border2,
                    width: isSel ? 1.8 : 1,
                  ),
                  boxShadow: isSel
                      ? [
                    BoxShadow(
                      color: _T.acc.withValues(alpha: 0.18),
                      blurRadius: 10,
                    ),
                  ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    short,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      color: isSel ? _T.acc : _T.txt2,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        // Summary bar
        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
          child: _selectedDays.isNotEmpty
              ? Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: _T.acc3.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _T.acc2.withValues(alpha: 0.28),
                ),
              ),
              child: Text(
                _selectedDays.join('  •  '),
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                  color: _T.acc,
                  fontSize: 12.5,
                  height: 1.6,
                ),
              ),
            ),
          )
              : const SizedBox.shrink(),
        ),
      ],
    ),
  );

  Widget _saveButton() => SizedBox(
    width: double.infinity,
    height: 58,
    child: ElevatedButton(
      onPressed: _isSaving ? null : _onSave,
      style: ElevatedButton.styleFrom(
        backgroundColor: _T.acc,
        disabledBackgroundColor: _T.acc3.withValues(alpha: 0.4),
        foregroundColor: _T.bg,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        overlayColor: Colors.black.withValues(alpha: 0.12),
      ),
      child: _isSaving
          ? const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(_T.bg),
        ),
      )
          : const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_active_rounded, size: 20),
          SizedBox(width: 10),
          Text(
            'حفظ التذكير',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    ),
  );

  // ─────────────────────────────────────────────────────────────────────
  //  Build
  // ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: _T.bg,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: _T.bg,
          body: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── App Bar ──────────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 140,
                pinned: true,
                elevation: 0,
                backgroundColor: _T.bg,
                surfaceTintColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  title: FadeTransition(
                    opacity: _headerFade,
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          color: _T.txt,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          letterSpacing: -0.3,
                        ),
                        children: [
                          TextSpan(text: 'تذكير '),
                          TextSpan(
                            text: 'الأذكار',
                            style: TextStyle(color: _T.acc),
                          ),
                        ],
                      ),
                    ),
                  ),
                  background: Container(
                    color: _T.bg,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
                        child: FadeTransition(
                          opacity: _headerFade,
                          child: const Text(
                            'اضبط وقت ذكرك اليومي',
                            style: TextStyle(
                              color: _T.txt2,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(height: 1, color: _T.border),
                ),
              ),

              // ── Content ──────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 48),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _readyAzkarSection(),
                    const SizedBox(height: 12),
                    _customZekrSection(),
                    const SizedBox(height: 12),
                    _timeSection(),
                    const SizedBox(height: 12),
                    _daysSection(),
                    const SizedBox(height: 24),
                    _saveButton(),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}