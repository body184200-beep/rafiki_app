import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:http/http.dart' as http;



import '../../Al_Azkar/Azkar_screen.dart';
import '../../Al_quran/Quran_Screen.dart';
import '../../Notification/Notification_screen.dart';
import '../../Prayer/PrayerConfig.dart';
import '../../Prayer/PrayerTaskHandler.dart';
import '../../Setting_Screen/Profile_Screen/Profile_page/Navigation.dart';
import '../Daliley/Daliley_page/dalieley_screen.dart';
import '../Ghazwat/Ghazwat_screen.dart';
import '../Hasanatey/Sebha.dart';
import '../Rasolna/Al_Rasol.dart';
import '../Shabah/Shabah_screen.dart';


// ── Entry point للـ foreground task ───────────────────────────────────────
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(PrayerTaskHandler());
}

class Start extends StatefulWidget {
  const Start({super.key});

  @override
  State<Start> createState() => _StartState();
}

class _StartState extends State<Start> with TickerProviderStateMixin {
  // ── State ─────────────────────────────────────────────────────────────
  int _currentIndex = 0;
  bool _loadingPrayer = true;
  bool _showBottomBar = true;
  Map<String, dynamic>? _prayerTimes;
  String _countdownText = '';
  Timer? _countdownTimer;

  // ── Prayer Alert State ────────────────────────────────────────────────
  Prayer? _activePrayer;
  bool _showPrayerAlert = false;
  bool _alertDismissedByUser = false;
  Timer? _alertTimer;
  int _alertSecondsLeft = 180;
  Timer? _alertCountdownTimer;

  // ── Animation controllers ─────────────────────────────────────────────
  late AnimationController _navBarController;
  late Animation<double> _navBarAnimation;

  // ── Pages ──────────────────────────────────────────────────────────────
  static const List<Widget> _pages = [
    HomeGrid(),
    Sh2(),
    Rasolna(),
    Qu(),
    Hasanatey(),
  ];

  // ── Nav items ─────────────────────────────────────────────────────────
  static const List<_NavItem> _navItems = [
    _NavItem(icon: Icons.groups_rounded,    label: 'الصحابة'),
    _NavItem(icon: Icons.shield_rounded,    label: 'الغزوات'),
    _NavItem(icon: Icons.person_rounded,    label: 'الرسول'),
    _NavItem(icon: Icons.menu_book_rounded, label: 'دليلي'),
    _NavItem(icon: Icons.favorite_rounded,  label: 'حسناتي'),
  ];

  // ── Gradients per tab ─────────────────────────────────────────────────
  static const List<List<Color>> _gradients = [
    [Color(0xff080C12), Color(0xff0F1923)],
    [Color(0xff080C12), Color(0xff101520)],
    [Color(0xff080C12), Color(0xff111520)],
    [Color(0xff0A0C14), Color(0xff0D1320)],
    [Color(0xff080C12), Color(0xff0C1518)],
  ];

  // ── Prayer names ──────────────────────────────────────────────────────
  static const Map<Prayer, String> _prayerNames = {
    Prayer.fajr:    'الفجر',
    Prayer.sunrise: 'الشروق',
    Prayer.dhuhr:   'الظهر',
    Prayer.asr:     'العصر',
    Prayer.maghrib: 'المغرب',
    Prayer.isha:    'العشاء',
  };

  // ── Alert messages ────────────────────────────────────────────────────
  static const Map<Prayer, String> _alertMessages = {
    Prayer.fajr:    'حان وقت صلاة الفجر\nفلا تتأخر في النهوض',
    Prayer.dhuhr:   'حان وقت صلاة الظهر\nأقم الصلاة لله',
    Prayer.asr:     'حان وقت صلاة العصر\nلا تفوِّتها',
    Prayer.maghrib: 'حان وقت صلاة المغرب\nبادر قبل أن يذهب الوقت',
    Prayer.isha:    'حان وقت صلاة العشاء\nأختم يومك بطاعة الله',
  };

  // ── Colors ────────────────────────────────────────────────────────────
  static const Color _accent    = Color(0xff4ECCA3);
  static const Color _accentDim = Color(0xff1D9E75);
  static const Color _bg        = Color(0xff080C12);
  static const Color _surface   = Color(0xff111620);
  static const Color _border    = Color(0xff1E2738);
  static const Color _textPri   = Color(0xffEEF0F4);
  static const Color _textSec   = Color(0xff8A94A6);

  // ── Lifecycle ─────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _navBarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      value: 1.0,
    );
    _navBarAnimation = CurvedAnimation(
      parent: _navBarController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _initForegroundTask();
    _fetchPrayerTimes();
    _startPrayerNotification();
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _alertTimer?.cancel();
    _alertCountdownTimer?.cancel();
    _navBarController.dispose();
    super.dispose();
  }

  // ── Foreground service ────────────────────────────────────────────────

  Future<void> _initForegroundTask() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'prayer_channel',
        channelName: 'Prayer Notification',
        channelDescription: 'عداد الصلاة القادمة',
        channelImportance: NotificationChannelImportance.HIGH,
        priority: NotificationPriority.HIGH,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(1000),
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  Future<void> _startPrayerNotification() async {
    await FlutterForegroundTask.requestNotificationPermission();
    final isRunning = await FlutterForegroundTask.isRunningService;
    if (!isRunning) {
      await FlutterForegroundTask.startService(
        notificationTitle: '🕌 الصلاة القادمة',
        notificationText: 'جاري التشغيل...',
        callback: startCallback,
      );
    }
  }

  // ── Countdown + Alert check ───────────────────────────────────────────

  void _startCountdown() {
    _countdownText = _getPrayerCountdown();
    _checkPrayerAlert();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _countdownText = _getPrayerCountdown());
      _checkPrayerAlert();
    });
  }

  // ── الكاونت داون — بعد العشاء يجيب فجر الغد مباشرة ─────────────────

  String _getPrayerCountdown() {
    try {
      final coords = PrayerConfig.coordinates;
      final params = PrayerConfig.params;
      final now    = DateTime.now();
      final times  = PrayerTimes.today(coords, params);

      final nextPrayer = times.nextPrayer();

      // Prayer.none = انتهت العشاء → نحسب فجر الغد مباشرة
      if (nextPrayer == Prayer.none) {
        final tomorrow      = DateComponents.from(now.add(const Duration(days: 1)));
        final tomorrowTimes = PrayerTimes(coords, tomorrow, params);
        final fajrNext      = tomorrowTimes.fajr;
        final diff          = fajrNext.difference(now);
        if (diff.isNegative) return 'جاري الحساب...';
        final h = diff.inHours.toString().padLeft(2, '0');
        final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
        final s = (diff.inSeconds % 60).toString().padLeft(2, '0');
        return 'فجر الغد · $h:$m:$s';
      }

      final nextTime = times.timeForPrayer(nextPrayer);
      if (nextTime == null) return 'جاري الحساب...';
      final diff = nextTime.difference(now);
      if (diff.isNegative) return 'جاري الحساب...';

      final h    = diff.inHours.toString().padLeft(2, '0');
      final m    = (diff.inMinutes % 60).toString().padLeft(2, '0');
      final s    = (diff.inSeconds % 60).toString().padLeft(2, '0');
      final name = _prayerNames[nextPrayer] ?? 'الصلاة';
      return '$name · $h:$m:$s';
    } catch (_) {
      return 'جاري الحساب...';
    }
  }

  // ── فحص دخول وقت الصلاة وعرض التنبيه ───────────────────────────────

  void _checkPrayerAlert() {
    try {
      final coords        = PrayerConfig.coordinates;
      final params        = PrayerConfig.params;
      final times         = PrayerTimes.today(coords, params);
      final currentPrayer = times.currentPrayer();

      if (currentPrayer == Prayer.none || currentPrayer == Prayer.sunrise) return;

      if (currentPrayer != _activePrayer) {
        if (!mounted) return;
        setState(() {
          _activePrayer          = currentPrayer;
          _showPrayerAlert       = true;
          _alertDismissedByUser  = false;
          _alertSecondsLeft      = 180;
        });

        _alertTimer?.cancel();
        _alertCountdownTimer?.cancel();

        _alertCountdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (!mounted) return;
          setState(() {
            _alertSecondsLeft--;
            if (_alertSecondsLeft <= 0) {
              _showPrayerAlert = false;
              _alertCountdownTimer?.cancel();
            }
          });
        });

        _alertTimer = Timer(const Duration(minutes: 3), () {
          if (!mounted) return;
          setState(() => _showPrayerAlert = false);
          _alertCountdownTimer?.cancel();
        });
      }
    } catch (_) {}
  }

  // ── Prayer times API ──────────────────────────────────────────────────

  Future<void> _fetchPrayerTimes() async {
    try {
      final response = await http.get(Uri.parse(
        'https://api.aladhan.com/v1/timingsByCity'
            '?city=${PrayerConfig.apiCity}&country=${PrayerConfig.apiCountry}&method=${PrayerConfig.apiMethod}',
      ));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _prayerTimes   = data['data']['timings'] as Map<String, dynamic>;
            _loadingPrayer = false;
          });
        }
      } else {
        if (mounted) setState(() => _loadingPrayer = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingPrayer = false);
    }
  }

  // ── Nav bar toggle ─────────────────────────────────────────────────────

  void _toggleNavBar() {
    HapticFeedback.lightImpact();
    setState(() => _showBottomBar = !_showBottomBar);
    if (_showBottomBar) {
      _navBarController.forward();
    } else {
      _navBarController.reverse();
    }
  }

  // ── Glass helper ───────────────────────────────────────────────────────

  Widget _glass({
    required Widget child,
    EdgeInsets? padding,
    double radius = 20,
    Color? borderColor,
    Color? bgColor,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding ?? const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bgColor ?? Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: borderColor ?? Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  // ── Top action bar ────────────────────────────────────────────────────

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: _glass(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          children: [
            _topBarBtn(
              icon: Icons.menu_book_rounded,
              tooltip: 'المصحف',
              onTap: () => _push(const MushafPage()),
            ),
            _topBarBtn(
              icon: Icons.auto_awesome_rounded,
              tooltip: 'الأذكار',
              onTap: () => _push(const AzkarPage()),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'الصلاة القادمة',
                    style: TextStyle(
                      color: _textSec,
                      fontSize: 9,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _countdownText.isEmpty ? '...' : _countdownText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _accent,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            _topBarBtn(
              icon: Icons.notifications_rounded,
              tooltip: 'التنبيهات',
              onTap: () => _push(const NotificationPage()),
            ),
            _topBarBtn(
              icon: Icons.person,
              tooltip: 'الإعدادات',
              onTap: () => _push(const Setting()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBarBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: _accent.withValues(alpha: 0.12),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(
              icon,
              color: Colors.white.withValues(alpha: 0.85),
              size: 21,
            ),
          ),
        ),
      ),
    );
  }

  // ── Prayer card ───────────────────────────────────────────────────────

  Widget _prayerCard() {
    if (_loadingPrayer) {
      return _glass(
        child: const SizedBox(
          height: 52,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: _accent),
            ),
          ),
        ),
      );
    }

    // الصلاة الحالية لتمييزها
    Prayer? currentPrayer;
    try {
      final coords = PrayerConfig.coordinates;
      final params = PrayerConfig.params;
      final times  = PrayerTimes.today(coords, params);
      final cp     = times.currentPrayer();
      if (cp != Prayer.none && cp != Prayer.sunrise) currentPrayer = cp;
    } catch (_) {}

    final prayerList = [
      _PrayerEntry(Prayer.fajr,    'فجر',  _prayerTimes?['Fajr']    ?? '--'),
      _PrayerEntry(Prayer.dhuhr,   'ظهر',  _prayerTimes?['Dhuhr']   ?? '--'),
      _PrayerEntry(Prayer.asr,     'عصر',  _prayerTimes?['Asr']     ?? '--'),
      _PrayerEntry(Prayer.maghrib, 'مغرب', _prayerTimes?['Maghrib'] ?? '--'),
      _PrayerEntry(Prayer.isha,    'عشاء', _prayerTimes?['Isha']    ?? '--'),
    ];

    final currentIdx = prayerList.indexWhere((p) => p.prayer == currentPrayer);

    return _glass(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: prayerList.asMap().entries.map((entry) {
          final idx    = entry.key;
          final p      = entry.value;
          final isNow  = p.prayer == currentPrayer;
          final isPast = currentIdx >= 0 && idx < currentIdx;
          return _prayerItem(p.name, p.time, isNow: isNow, isPast: isPast);
        }).toList(),
      ),
    );
  }

  Widget _prayerItem(
      String name,
      String time, {
        bool isNow  = false,
        bool isPast = false,
      }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: isNow ? _accent.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isNow ? _accentDim.withValues(alpha: 0.45) : Colors.transparent,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: TextStyle(
              color: isNow
                  ? _accent
                  : isPast
                  ? _textSec.withValues(alpha: 0.45)
                  : _textSec,
              fontSize: 11,
              fontWeight: isNow ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: TextStyle(
              color: isNow
                  ? _textPri
                  : isPast
                  ? _textPri.withValues(alpha: 0.3)
                  : _textPri.withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          if (isNow) _PulsingDot() else const SizedBox(height: 5),
        ],
      ),
    );
  }

  // ── تنبيه الصلاة — شريط صغير قابل للإغلاق ──────────────────────────

  void _dismissAlert() {
    HapticFeedback.lightImpact();
    _alertTimer?.cancel();
    _alertCountdownTimer?.cancel();
    if (mounted) setState(() {
      _showPrayerAlert = false;
      _alertDismissedByUser = true;
    });
  }

  Widget _prayerAlertCard() {
    final prayer   = _activePrayer!;
    final name     = _prayerNames[prayer] ?? 'الصلاة';
    final msg      = _alertMessages[prayer] ?? 'حان وقت $name';
    final progress = _alertSecondsLeft / 180.0;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      builder: (_, v, child) => Transform.translate(
        offset: Offset(0, -8 * (1 - v)),
        child: Opacity(opacity: v.clamp(0.0, 1.0), child: child),
      ),
      child: Dismissible(
        key: ValueKey('alert_${prayer.name}'),
        direction: DismissDirection.horizontal,
        onDismissed: (_) => _dismissAlert(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.10),
                border: Border.all(color: _accent.withValues(alpha: 0.30)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    child: Row(
                      children: [
                        const Text('🕌', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'حان وقت $name  ',
                                  style: const TextStyle(
                                    color: _accent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                TextSpan(
                                  text: msg.split('\n').last,
                                  style: const TextStyle(
                                    color: _textSec,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: _dismissAlert,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: _textSec,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(12),
                    ),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: _border,
                      valueColor: const AlwaysStoppedAnimation<Color>(_accent),
                      minHeight: 3,
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

  // ── بانر فجر الغد بعد العشاء ─────────────────────────────────────────

  Widget _fajrNextDayBanner() {
    String fajrTime = '--';
    try {
      final coords    = PrayerConfig.coordinates;
      final params    = PrayerConfig.params;
      final now       = DateTime.now();
      final tomorrow  = DateComponents.from(now.add(const Duration(days: 1)));
      final nextTimes = PrayerTimes(coords, tomorrow, params);
      final fajr      = nextTimes.fajr;
      fajrTime        = '${fajr.hour.toString().padLeft(2, '0')}:${fajr.minute.toString().padLeft(2, '0')}';
    } catch (_) {}

    return _glass(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      borderColor: const Color(0xff3A6EA5).withValues(alpha: 0.4),
      child: Row(
        children: [
          const Text('🌙', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'انتهت صلاة العشاء',
                  style: TextStyle(
                    color: Color(0xff7AB4FF),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'الصلاة القادمة: فجر الغد الساعة $fajrTime',
                  style: const TextStyle(color: _textSec, fontSize: 12),
                ),
              ],
            ),
          ),
          const Text('🌅', style: TextStyle(fontSize: 20)),
        ],
      ),
    );
  }

  // ── هل انتهت صلاة العشاء؟ ────────────────────────────────────────────

  bool get _isAfterIsha {
    try {
      final coords = PrayerConfig.coordinates;
      final params = PrayerConfig.params;
      final times  = PrayerTimes.today(coords, params);
      return times.nextPrayer() == Prayer.none;
    } catch (_) {
      return false;
    }
  }

  // ── Custom bottom nav ─────────────────────────────────────────────────

  Widget _bottomNav() {
    return SizeTransition(
      sizeFactor: _navBarAnimation,
      axisAlignment: 1.0,
      child: _glass(
        radius: 0,
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_navItems.length, (i) {
            final item     = _navItems[i];
            final selected = _currentIndex == i;

            return GestureDetector(
              onTap: () {
                if (_currentIndex == i) return;
                HapticFeedback.selectionClick();
                setState(() => _currentIndex = i);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? _accentDim.withValues(alpha: 0.18)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected
                        ? _accentDim.withValues(alpha: 0.45)
                        : Colors.transparent,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      size: 20,
                      color: selected
                          ? _accent
                          : Colors.white.withValues(alpha: 0.45),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.label,
                      style: TextStyle(
                        color: selected
                            ? _accent
                            : Colors.white.withValues(alpha: 0.45),
                        fontSize: 10,
                        fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ── Toggle pill ───────────────────────────────────────────────────────

  Widget _togglePill() {
    return GestureDetector(
      onTap: _toggleNavBar,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
        decoration: BoxDecoration(
          color: _surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: _border),
        ),
        child: Icon(
          _showBottomBar
              ? Icons.keyboard_arrow_down_rounded
              : Icons.keyboard_arrow_up_rounded,
          color: _textSec,
          size: 18,
        ),
      ),
    );
  }

  // ── Navigation helper ─────────────────────────────────────────────────

  void _push(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final gradient       = _gradients[_currentIndex];
    final hidePrayerCard = _currentIndex == 3 || _currentIndex == 4;
    final afterIsha      = _isAfterIsha;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: _bg,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          extendBody: true,
          extendBodyBehindAppBar: true,
          backgroundColor: _bg,
          body: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: gradient,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // ── top bar ──────────────────────────────────────────
                  _topBar(),

                  const SizedBox(height: 10),

                  // ── تنبيه الأذان ─────────────────────────────────────
                  if (_showPrayerAlert && _activePrayer != null && !hidePrayerCard)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: _prayerAlertCard(),
                    ),

                  if (_showPrayerAlert && _activePrayer != null && !hidePrayerCard)
                    const SizedBox(height: 8),

                  // ── بانر فجر الغد بعد العشاء ─────────────────────────
                  if (afterIsha && !_showPrayerAlert && !_alertDismissedByUser && !hidePrayerCard)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: _fajrNextDayBanner(),
                    ),

                  if (afterIsha && !_showPrayerAlert && !_alertDismissedByUser && !hidePrayerCard)
                    const SizedBox(height: 8),

                  // ── prayer card ───────────────────────────────────────
                  if (!hidePrayerCard)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: _prayerCard(),
                    ),

                  if (!hidePrayerCard) const SizedBox(height: 10),

                  // ── page content ──────────────────────────────────────
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.03),
                            end: Offset.zero,
                          ).animate(anim),
                          child: child,
                        ),
                      ),
                      child: KeyedSubtree(
                        key: ValueKey(_currentIndex),
                        child: _pages[_currentIndex],
                      ),
                    ),
                  ),

                  // ── toggle pill ───────────────────────────────────────
                  _togglePill(),

                  // ── bottom nav ────────────────────────────────────────
                  _bottomNav(),

                  SizedBox(height: MediaQuery.of(context).padding.bottom),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── النقطة النابضة ────────────────────────────────────────────────────────
class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.6, end: 1.0).animate(_anim),
        child: Container(
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            color: Color(0xff4ECCA3),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

// ── Helper classes ────────────────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _PrayerEntry {
  final Prayer prayer;
  final String name;
  final String time;
  const _PrayerEntry(this.prayer, this.name, this.time);
}