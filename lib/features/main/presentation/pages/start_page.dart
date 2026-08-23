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
import 'package:rafiki_app/features/prophet/presentation/pages/prophet_page.dart';

import '../controllers/home_controller.dart';
import '../widgets/home_bottom_nav.dart';
import '../widgets/home_prayer_alert.dart';
import '../widgets/home_prayer_strip.dart';
import '../widgets/home_top_bar.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _home.bindLocalizations(AppLocalizations.of(context)!);
      _home.startCountdown();
      _startPrayerNotification();
    });
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
    _home.removeListener(_onHomeChanged);
    _home.dispose();
    _navCtrl.dispose();
    super.dispose();
  }

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
