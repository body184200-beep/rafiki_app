import 'dart:async';
import 'dart:ui';

import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:rafiki_app/core/di/service_locator.dart';
import 'package:rafiki_app/features/prayer/data/services/prayer_engine.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rafiki_app/core/l10n/app_localizations.dart';


import 'package:rafiki_app/features/azkar/presentation/pages/azkar_page.dart';
import 'package:rafiki_app/features/quran/presentation/pages/quran_page.dart';
import 'package:rafiki_app/features/settings/presentation/pages/settings_page.dart';
import 'package:rafiki_app/features/guide/presentation/pages/guide_page.dart';
import 'package:rafiki_app/features/battles/presentation/pages/battles_page.dart';
import 'package:rafiki_app/features/deeds/presentation/pages/deeds_page.dart';
import 'package:rafiki_app/features/prophet/presentation/pages/prophet_page.dart';
import 'package:rafiki_app/features/companions/presentation/pages/companions_page.dart';
import 'package:rafiki_app/features/notification/presentation/pages/notification_page.dart';
import 'package:rafiki_app/features/prayer/data/services/prayer_config.dart';
import 'package:rafiki_app/features/prayer/data/services/prayer_task_handler.dart';


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

class _StartState extends State<Start> with TickerProviderStateMixin, WidgetsBindingObserver {
  // ── State ─────────────────────────────────────────────────────────────
  int _currentIndex = 0;
  bool _loadingPrayer = true;
  bool _showBottomBar = true;
  Map<String, dynamic>? _prayerTimes;
  Coordinates _coords = Coordinates(31.4165, 31.8133);
  final ValueNotifier<String> _countdownNotifier = ValueNotifier<String>('');
  Timer? _countdownTimer;
  DateTime? _lastLocationFetchTime;

  PrayerTimes? _cachedTodayTimes;
  DateTime? _cachedTodayTimesDate;

  PrayerTimes _getTodayPrayerTimes() {
    final now = DateTime.now();
    
    // Attempt to use the centralized PrayerEngine first
    final engineTimes = sl<PrayerEngine>().todayTimes;
    if (engineTimes != null) {
      _cachedTodayTimes = engineTimes;
      _cachedTodayTimesDate = now;
      return engineTimes;
    }

    if (_cachedTodayTimes != null && _cachedTodayTimesDate != null) {
      if (_cachedTodayTimesDate!.year == now.year &&
          _cachedTodayTimesDate!.month == now.month &&
          _cachedTodayTimesDate!.day == now.day) {
        return _cachedTodayTimes!;
      }
    }
    _cachedTodayTimesDate = now;
    _cachedTodayTimes = PrayerTimes.today(_coords, PrayerConfig.params);
    return _cachedTodayTimes!;
  }

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
  static final List<Widget> _pages = [
    CompanionsPage(),
    BattlesPage(),
    ProphetPage(),
    GuidePage(),
    DeedsPage(),
  ];

  // ── Nav items ─────────────────────────────────────────────────────────
  List<_NavItem> _getNavItems(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return [
      _NavItem(icon: Icons.shield_rounded,    label: loc.nav_companions),
      _NavItem(icon: Icons.shield_rounded,    label: loc.nav_battles),
      _NavItem(icon: Icons.person_rounded,    label: loc.nav_prophet),
      _NavItem(icon: Icons.menu_book_rounded, label: loc.nav_guide),
      _NavItem(icon: Icons.favorite_rounded,  label: loc.nav_deeds),
    ];
  }

  // ── Gradients per tab ─────────────────────────────────────────────────
  static const List<List<Color>> _gradients = [
    [Color(0xff080C12), Color(0xff0F1923)],
    [Color(0xff080C12), Color(0xff101520)],
    [Color(0xff080C12), Color(0xff111520)],
    [Color(0xff0A0C14), Color(0xff0D1320)],
    [Color(0xff080C12), Color(0xff0C1518)],
  ];

  // ── Prayer names ──────────────────────────────────────────────────────
  Map<Prayer, String> _getPrayerNames(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return {
      Prayer.fajr:    loc.prayer_fajr,
      Prayer.sunrise: loc.prayer_sunrise,
      Prayer.dhuhr:   loc.prayer_dhuhr,
      Prayer.asr:     loc.prayer_asr,
      Prayer.maghrib: loc.prayer_maghrib,
      Prayer.isha:    loc.prayer_isha,
    };
  }

  // ── Alert messages ────────────────────────────────────────────────────
  Map<Prayer, String> _getAlertMessages(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return {
      Prayer.fajr:    loc.alert_fajr,
      Prayer.dhuhr:   loc.alert_dhuhr,
      Prayer.asr:     loc.alert_asr,
      Prayer.maghrib: loc.alert_maghrib,
      Prayer.isha:    loc.alert_isha,
    };
  }

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
    WidgetsBinding.instance.addObserver(this);

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
    _loadCachedPrayerTimes();
    _fetchPrayerTimes();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startPrayerNotification();
        _startCountdown();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownNotifier.dispose();
    _countdownTimer?.cancel();
    _alertTimer?.cancel();
    _alertCountdownTimer?.cancel();
    _navBarController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_countdownTimer == null || !_countdownTimer!.isActive) {
        _startCountdown();
      }
    } else if (state == AppLifecycleState.paused) {
      _countdownTimer?.cancel();
      _countdownTimer = null;
    }
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
    final loc = AppLocalizations.of(context)!;
    await FlutterForegroundTask.requestNotificationPermission();
    final isRunning = await FlutterForegroundTask.isRunningService;
    if (!isRunning) {
      await FlutterForegroundTask.startService(
        notificationTitle: loc.next_prayer_title,
        notificationText: loc.next_prayer_calculating,
        callback: startCallback,
      );
    }
  }

  // ── Countdown + Alert check ───────────────────────────────────────────

  void _startCountdown() {
    _countdownNotifier.value = _getPrayerCountdown(context);
    _checkPrayerAlert();
    
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _countdownNotifier.value = _getPrayerCountdown(context);
      
      // Only check for alert every 10 seconds to save CPU, 
      // or at the top of the minute
      final now = DateTime.now();
      if (now.second % 10 == 0) {
        _checkPrayerAlert();
      }
    });
  }

  // ── الكاونت داون — بعد العشاء يجيب فجر الغد مباشرة ─────────────────

  String _getPrayerCountdown(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    try {
      final now    = DateTime.now();
      final times  = _getTodayPrayerTimes();

      final nextPrayer = times.nextPrayer();

      // Prayer.none = انتهت العشاء → نحسب فجر الغد مباشرة
      if (nextPrayer == Prayer.none) {
        final tomorrow      = DateComponents.from(now.add(const Duration(days: 1)));
        final tomorrowTimes = PrayerTimes(_coords, tomorrow, PrayerConfig.params);
        final fajrNext      = tomorrowTimes.fajr;
        final diff          = fajrNext.difference(now);
        if (diff.isNegative) return loc.next_prayer_calculating;
        final h = diff.inHours.toString().padLeft(2, '0');
        final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
        final s = (diff.inSeconds % 60).toString().padLeft(2, '0');
        return loc.next_prayer_tomorrow_fajr('$h:$m:$s');
      }

      final nextTime = times.timeForPrayer(nextPrayer);
      if (nextTime == null) return loc.next_prayer_calculating;
      final diff = nextTime.difference(now);
      if (diff.isNegative) return loc.next_prayer_calculating;

      final h    = diff.inHours.toString().padLeft(2, '0');
      final m    = (diff.inMinutes % 60).toString().padLeft(2, '0');
      final s    = (diff.inSeconds % 60).toString().padLeft(2, '0');
      final name = _getPrayerNames(context)[nextPrayer] ?? loc.tooltip_next_prayer;
      return '$name · $h:$m:$s';
    } catch (_) {
      return loc.next_prayer_calculating;
    }
  }

  // ── فحص دخول وقت الصلاة وعرض التنبيه ───────────────────────────────

  void _checkPrayerAlert() {
    try {
      final times         = _getTodayPrayerTimes();
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

  // ── Prayer times (Computed locally offline-first) ─────────────────────

  String _formatTime(DateTime time) {
    final localTime = time.toLocal();
    final hour = localTime.hour.toString().padLeft(2, '0');
    final minute = localTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _loadCachedPrayerTimes() async {
    try {
      final coords = await PrayerConfig.getCoordinates();
      final params = PrayerConfig.params;
      final times = PrayerTimes.today(coords, params);

      if (mounted) {
        setState(() {
          _coords = coords;
          _prayerTimes = {
            'Fajr': _formatTime(times.fajr),
            'Dhuhr': _formatTime(times.dhuhr),
            'Asr': _formatTime(times.asr),
            'Maghrib': _formatTime(times.maghrib),
            'Isha': _formatTime(times.isha),
          };
          _loadingPrayer = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingPrayer = false);
    }
  }

  Future<void> _fetchPrayerTimes() async {
    final now = DateTime.now();

    // Throttling: only fetch location if it has been at least 10 minutes since last check,
    // or if we have no prayer times calculated yet.
    if (_lastLocationFetchTime != null &&
        now.difference(_lastLocationFetchTime!).inMinutes < 10 &&
        _prayerTimes != null) {
      await _loadCachedPrayerTimes();
      return;
    }

    if (_prayerTimes == null && _loadingPrayer) {
      if (mounted) setState(() => _loadingPrayer = true);
    }

    Position? position;
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          // Request permission exactly once on startup
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low,
            timeLimit: const Duration(seconds: 4),
          );
        }
      }
    } catch (_) {
      // Fallback silently
    }

    if (position != null) {
      _lastLocationFetchTime = now;
      final cachedCoords = await PrayerConfig.getCoordinates();

      // Calculate distance between cached coordinates and new position
      final distance = Geolocator.distanceBetween(
        cachedCoords.latitude,
        cachedCoords.longitude,
        position.latitude,
        position.longitude,
      );

      // Only save and trigger updates if location change is significant (> 5000m / 5km)
      // or if we do not have coordinates saved yet
      if (distance > 5000 || _coords.latitude == 31.4165 && _coords.longitude == 31.8133) {
        await PrayerConfig.saveCoordinates(position.latitude, position.longitude);
        if (sl.isRegistered<PrayerEngine>()) {
          await sl<PrayerEngine>().reloadCoordinates();
        }
      }
    }

    await _loadCachedPrayerTimes();
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
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: _glass(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          children: [
            _topBarBtn(
              icon: Icons.menu_book_rounded,
              tooltip: loc.tooltip_quran,
              onTap: () => _push(const MushafPage()),
            ),
            _topBarBtn(
              icon: Icons.auto_awesome_rounded,
              tooltip: loc.tooltip_azkar,
              onTap: () => _push(const AzkarPage()),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    loc.tooltip_next_prayer,
                    style: TextStyle(
                      color: _textSec,
                      fontSize: 9,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  ValueListenableBuilder<String>(
                    valueListenable: _countdownNotifier,
                    builder: (context, value, child) {
                      return Text(
                        value.isEmpty ? '...' : value,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _accent,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            _topBarBtn(
              icon: Icons.notifications_rounded,
              tooltip: loc.tooltip_notifications,
              onTap: () => _push(const NotificationPage()),
            ),
            _topBarBtn(
              icon: Icons.person,
              tooltip: loc.tooltip_settings,
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
      final coords = _coords;
      final params = PrayerConfig.params;
      final times  = PrayerTimes.today(coords, params);
      final cp     = times.currentPrayer();
      if (cp != Prayer.none && cp != Prayer.sunrise) currentPrayer = cp;
    } catch (_) {}

    final loc = AppLocalizations.of(context)!;
    final prayerList = [
      _PrayerEntry(Prayer.fajr,    loc.prayer_fajr,  _prayerTimes?['Fajr']    ?? '--'),
      _PrayerEntry(Prayer.dhuhr,   loc.prayer_dhuhr,  _prayerTimes?['Dhuhr']   ?? '--'),
      _PrayerEntry(Prayer.asr,     loc.prayer_asr,  _prayerTimes?['Asr']     ?? '--'),
      _PrayerEntry(Prayer.maghrib, loc.prayer_maghrib, _prayerTimes?['Maghrib'] ?? '--'),
      _PrayerEntry(Prayer.isha,    loc.prayer_isha,    _prayerTimes?['Isha']    ?? '--'),
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
    final loc = AppLocalizations.of(context)!;
    final prayer   = _activePrayer!;
    final name     = _getPrayerNames(context)[prayer] ?? loc.tooltip_next_prayer;
    final msg      = _getAlertMessages(context)[prayer] ?? loc.alert_now(name);
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
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
                                  text: '${loc.alert_now(name)}  ',
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
    final loc = AppLocalizations.of(context)!;
    String fajrTime = '--';
    try {
      final coords    = _coords;
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
                Text(
                  loc.banner_isha_ended,
                  style: const TextStyle(
                    color: Color(0xff7AB4FF),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  loc.banner_next_tomorrow_fajr(fajrTime),
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
      final coords = _coords;
      final params = PrayerConfig.params;
      final times  = PrayerTimes.today(coords, params);
      return times.nextPrayer() == Prayer.none;
    } catch (_) {
      return false;
    }
  }

  // ── Custom bottom nav ─────────────────────────────────────────────────

  Widget _bottomNav() {
    final navItems = _getNavItems(context);
    return SizeTransition(
      sizeFactor: _navBarAnimation,
      axisAlignment: 1.0,
      child: _glass(
        radius: 0,
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(navItems.length, (i) {
            final item     = navItems[i];
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
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_ctrl.isAnimating) _ctrl.repeat(reverse: true);
    } else if (state == AppLifecycleState.paused) {
      _ctrl.stop();
    }
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