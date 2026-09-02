import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'package:rafiki_app/core/l10n/app_localizations.dart';
import 'package:rafiki_app/core/theme/app_colors.dart';
import 'package:rafiki_app/core/theme/app_theme.dart';
import 'package:rafiki_app/features/battles/presentation/pages/battles_page.dart';
import 'package:rafiki_app/features/companions/presentation/pages/companions_page.dart';
import 'package:rafiki_app/features/deeds/presentation/pages/deeds_page.dart';
import 'package:rafiki_app/features/guide/presentation/pages/guide_page.dart';
import 'package:rafiki_app/features/prayer/data/services/prayer_task_handler.dart';
import 'package:rafiki_app/features/notification/data/services/notification_engine.dart';
import 'package:rafiki_app/features/prophet/presentation/pages/prophet_page.dart';

import 'package:adhan/adhan.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:rafiki_app/core/utils/time_format.dart';
import 'package:rafiki_app/features/prayer/data/services/prayer_config.dart';
import '../controllers/home_controller.dart';
import '../widgets/home_bottom_nav.dart';
import '../widgets/home_prayer_alert.dart';
import '../widgets/home_prayer_strip.dart';
import '../widgets/home_top_bar.dart';

@pragma('vm:entry-point')
void startCallback() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.setTaskHandler(PrayerTaskHandler());
}

class Start extends StatefulWidget {
  const Start({super.key});

  @override
  State<Start> createState() => _StartState();
}

class _StartState extends State<Start>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final HomeController _home = HomeController();
  late final AnimationController _navCtrl;
  late final Animation<double> _navAnim;

  static const _pages = <Widget>[
    CompanionsPage(),
    BattlesPage(),
    ProphetPage(),
    GuidePage(),
    DeedsPage(),
  ];

  static const _gradients = <List<Color>>[
    [Color(0xFF080C12), Color(0xFF0F1923)],
    [Color(0xFF080C12), Color(0xFF101520)],
    [Color(0xFF080C12), Color(0xFF111520)],
    [Color(0xFF0A0C14), Color(0xFF0D1320)],
    [Color(0xFF080C12), Color(0xFF0C1518)],
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NotificationEngine.instance.onEnsureForegroundService = ensureForegroundServiceRunning;
    _navCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      value: 1,
    );
    _navAnim = CurvedAnimation(
      parent: _navCtrl,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _home.addListener(_onHomeChanged);
    _home.attach();
    _initForegroundTask();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      _home.bindLocalizations(AppLocalizations.of(context)!);
      _home.startCountdown();

      final isAllowed = await AwesomeNotifications().isNotificationAllowed();
      if (isAllowed) {
        if (mounted) {
          await ensureForegroundServiceRunning();
          if (!mounted) return;
          await NotificationEngine.instance.checkAndRequestExactAlarmPermission(context: context);
        }
      } else {
        if (mounted) {
          await _checkAndPromptNotificationPermission();
        }
      }
    });
  }

  DateTime? _lastResumeTimestamp;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final now = DateTime.now();
      if (_lastResumeTimestamp != null &&
          now.difference(_lastResumeTimestamp!).inMilliseconds < 3000) {
        return;
      }
      _lastResumeTimestamp = now;
      debugPrint('🔔 [StartPage] App resumed — checking notification & foreground service...');
      NotificationEngine.instance.checkAndHandleAppResume(context: context);
      ensureForegroundServiceRunning();
    }
  }

  void _onHomeChanged() {
    if (!mounted) return;
    if (_home.showNavBar) {
      _navCtrl.forward();
    } else {
      _navCtrl.reverse();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NotificationEngine.instance.onEnsureForegroundService = null;
    _home.removeListener(_onHomeChanged);
    _home.dispose();
    _navCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkAndPromptNotificationPermission() async {
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    debugPrint('🔔 [StartPage] Cold start permission check: isAllowed=$isAllowed');

    if (isAllowed) {
      // General notifications are allowed. Now verify if Android 12+ exact alarm
      // permission is also granted, and prompt if missing.
      if (mounted) {
        await NotificationEngine.instance.checkAndRequestExactAlarmPermission(context: context);
      }
      return;
    }

    if (!mounted) return;

    // Show respectful dialog requesting user gesture
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F1520),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF1E2A3E), width: 0.8),
        ),
        title: const Row(
          children: [
            Icon(Icons.notifications_active_rounded, color: Color(0xFF4ECCA3), size: 26),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'تفعيل تنبيهات الأذان',
                style: TextStyle(
                  color: Color(0xFFEEF2F8),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'ليتمكن رفيقي من تذكيرك بمواقيت الصلاة، وإطلاق الأذان في موعده، ومتابعة العداد المباشر بدقة، يلزم السماح بإرسال الإشعارات.',
          style: TextStyle(
            color: Color(0xFF8A96AA),
            fontSize: 14,
            height: 1.6,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'لاحقاً',
              style: TextStyle(color: Color(0xFF8A96AA)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4ECCA3),
              foregroundColor: const Color(0xFF060A10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              // Direct user gesture
              final granted = await NotificationEngine.instance.requestAllNotificationPermissions(context: context);
              debugPrint('🔔 [StartPage] User gesture permission request completed: granted=$granted');
              if (granted && mounted) {
                await ensureForegroundServiceRunning();
              }
            },
            child: const Text(
              'تفعيل الإشعارات الآن',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _initForegroundTask() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        id: 1000,
        channelId: 'prayer_countdown_channel',
        channelName: 'مواقيت الصلاة (العداد الحي)',
        channelDescription: 'متابعة حية للوقت المتبقي حتى الصلاة القادمة',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        onlyAlertOnce: true,
        playSound: false,
        enableVibration: false,
        showWhen: false,
        showBadge: false,
        visibility: NotificationVisibility.VISIBILITY_PUBLIC,
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

  (String, String) _computeInitialPrayerNotification() {
    try {
      final now = DateTime.now();
      final coords = Coordinates(PrayerConfig.defaultLatitude, PrayerConfig.defaultLongitude);
      final params = PrayerConfig.params;
      final todayTimes = PrayerTimes.today(coords, params);
      final tomorrowComponents = DateComponents.from(now.add(const Duration(days: 1)));
      final tomorrowTimes = PrayerTimes(coords, tomorrowComponents, params);

      final todayPrayers = [
        MapEntry(Prayer.fajr, todayTimes.fajr),
        MapEntry(Prayer.dhuhr, todayTimes.dhuhr),
        MapEntry(Prayer.asr, todayTimes.asr),
        MapEntry(Prayer.maghrib, todayTimes.maghrib),
        MapEntry(Prayer.isha, todayTimes.isha),
      ];

      Prayer nextPrayer = Prayer.none;
      DateTime? nextPrayerTime;
      bool isTomorrow = false;

      for (final entry in todayPrayers) {
        if (entry.value.isAfter(now)) {
          nextPrayer = entry.key;
          nextPrayerTime = entry.value;
          break;
        }
      }

      if (nextPrayer == Prayer.none || nextPrayerTime == null) {
        nextPrayer = Prayer.fajr;
        nextPrayerTime = tomorrowTimes.fajr;
        isTomorrow = true;
      }

      final diff = nextPrayerTime.difference(now);
      final safeDiff = diff.isNegative ? Duration.zero : diff;
      final prayerName = _getPrayerName(nextPrayer);
      final prayerTimeStr = TimeFormat.format12h(nextPrayerTime);
      final countdownStr = TimeFormat.hhmmss(safeDiff);

      final title = isTomorrow
          ? 'الصلاة القادمة: $prayerName (غداً)'
          : 'الصلاة القادمة: $prayerName';
      final text = '$prayerTimeStr   •   $countdownStr';
      return (title, text);
    } catch (_) {
      return ('الصلاة القادمة: الفجر', '04:30 ص   •   00:00:00');
    }
  }

  String _getPrayerName(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return 'الفجر';
      case Prayer.dhuhr:
        return 'الظهر';
      case Prayer.asr:
        return 'العصر';
      case Prayer.maghrib:
        return 'المغرب';
      case Prayer.isha:
        return 'العشاء';
      default:
        return 'الفجر';
    }
  }

  /// Central, idempotent method to ensure the prayer foreground service is running.
  /// 1. Checks if notifications are permitted.
  /// 2. Checks if service is already running (returns true without duplicating).
  /// 3. Starts service if stopped.
  Future<bool> ensureForegroundServiceRunning() async {
    try {
      final isAllowed = await AwesomeNotifications().isNotificationAllowed();
      if (!isAllowed) {
        debugPrint('🔔 [StartPage] ensureForegroundServiceRunning: Notifications not allowed, skipping.');
        return false;
      }

      final isRunning = await FlutterForegroundTask.isRunningService;
      if (isRunning) {
        debugPrint('🔔 [StartPage] ensureForegroundServiceRunning: Service is already running.');
        return true;
      }

      final (initialTitle, initialText) = _computeInitialPrayerNotification();
      debugPrint('🚀 [StartPage] Starting foreground service: title="$initialTitle", text="$initialText"');

      final serviceResult = await FlutterForegroundTask.startService(
        serviceId: 1000,
        notificationTitle: initialTitle,
        notificationText: initialText,
        notificationIcon: const NotificationIcon(
          metaDataName: 'com.pravera.flutter_foreground_task.notification_icon',
          backgroundColor: Color(0xFF4ECCA3),
        ),
        callback: startCallback,
      );
      debugPrint('🚀 [StartPage] FlutterForegroundTask.startService result = $serviceResult');
      return true;
    } catch (e, st) {
      debugPrint('❌ [StartPage] Error starting foreground service: $e\n$st');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _home,
      builder: (context, _) {
        _home.bindLocalizations(AppLocalizations.of(context)!);
        final hideChrome = _home.hidePrayerChrome;
        final showAlert =
            _home.showPrayerAlert && _home.activePrayer != null && !hideChrome;
        final showFajr = _home.isAfterIsha &&
            !_home.showPrayerAlert &&
            !_home.alertDismissedByUser &&
            !hideChrome;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: AppTheme.systemUi,
          child: Scaffold(
            extendBody: true,
            backgroundColor: AppColors.bg,
            body: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _gradients[_home.tabIndex],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    HomeTopBar(controller: _home),
                    const SizedBox(height: 10),
                    if (showAlert)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: HomePrayerAlert(controller: _home),
                      ),
                    if (showAlert) const SizedBox(height: 8),
                    if (showFajr)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: HomeFajrBanner(controller: _home),
                      ),
                    if (showFajr) const SizedBox(height: 8),
                    if (!hideChrome)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: HomePrayerStrip(controller: _home),
                      ),
                    if (!hideChrome) const SizedBox(height: 10),
                    Expanded(
                      child: IndexedStack(
                        index: _home.tabIndex,
                        children: _pages,
                      ),
                    ),
                    HomeNavToggle(controller: _home),
                    HomeBottomNav(controller: _home, sizeFactor: _navAnim),
                    SizedBox(height: MediaQuery.paddingOf(context).bottom),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
