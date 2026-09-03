import 'dart:async';

import 'package:adhan/adhan.dart';
import 'package:flutter/widgets.dart';

import 'package:rafiki_app/core/constants/app_constants.dart';
import 'package:rafiki_app/core/di/service_locator.dart';
import 'package:rafiki_app/core/l10n/app_localizations.dart';
import 'package:rafiki_app/core/logging/app_logger.dart';
import 'package:rafiki_app/core/services/location_service.dart';
import 'package:rafiki_app/core/utils/prayer_names.dart';
import 'package:rafiki_app/core/utils/time_format.dart';
import 'package:rafiki_app/features/prayer/data/services/prayer_config.dart';
import 'package:rafiki_app/features/prayer/data/services/prayer_engine.dart';

/// Home shell state: tabs, location, prayer times, countdown, adhan banner.
class HomeController extends ChangeNotifier with WidgetsBindingObserver {
  HomeController({LocationService? locationService})
      : _location = locationService ??
            (sl.isRegistered<LocationService>()
                ? sl<LocationService>()
                : LocationService());

  static const _defaultLat = AppConstants.defaultLatitude;
  static const _defaultLng = AppConstants.defaultLongitude;
  static const _relocateMeters = 5000.0;

  final LocationService _location;

  int _tabIndex = 0;
  bool _showNavBar = true;
  bool _loadingPrayer = true;
  Map<String, String>? _prayerTimes;
  Coordinates _coords = Coordinates(_defaultLat, _defaultLng);

  final ValueNotifier<String> countdown = ValueNotifier<String>('');
  final ValueNotifier<int> alertSeconds = ValueNotifier<int>(
    AppConstants.prayerAlertDurationSeconds,
  );

  Prayer? _activePrayer;
  bool _showPrayerAlert = false;
  bool _alertDismissedByUser = false;

  Timer? _countdownTimer;
  Timer? _alertTimer;
  Timer? _alertTick;
  DateTime? _lastLocationFetch;
  PrayerTimes? _cachedTodayTimes;
  DateTime? _cachedTodayDate;
  AppLocalizations? _loc;

  int get tabIndex => _tabIndex;
  bool get showNavBar => _showNavBar;
  bool get loadingPrayer => _loadingPrayer;
  Map<String, String>? get prayerTimes => _prayerTimes;
  Prayer? get activePrayer => _activePrayer;
  bool get showPrayerAlert => _showPrayerAlert;
  bool get alertDismissedByUser => _alertDismissedByUser;

  /// Kept for widgets that still read a raw int.
  int get alertSecondsLeft => alertSeconds.value;

  bool get isAfterIsha {
    try {
      return _todayTimes().nextPrayer() == Prayer.none;
    } catch (e) {
      AppLogger.warning('Error calculating isAfterIsha', error: e);
      return false;
    }
  }

  bool get hidePrayerChrome => _tabIndex == 3 || _tabIndex == 4;

  Prayer? get currentPrayer {
    try {
      final current = _todayTimes().currentPrayer();
      if (current == Prayer.none || current == Prayer.sunrise) return null;
      return current;
    } catch (e) {
      AppLogger.warning('Error calculating currentPrayer', error: e);
      return null;
    }
  }

  String tomorrowFajrLabel() {
    try {
      final tomorrow = DateComponents.from(
        DateTime.now().add(const Duration(days: 1)),
      );
      final times = PrayerTimes(_coords, tomorrow, PrayerConfig.params);
      return TimeFormat.hhmm(times.fajr);
    } catch (e) {
      AppLogger.warning('Error calculating tomorrowFajrLabel', error: e);
      return '--';
    }
  }

  void bindLocalizations(AppLocalizations loc) => _loc = loc;

  void attach() {
    WidgetsBinding.instance.addObserver(this);
    _loadCachedPrayerTimes();
    _refreshLocationAndTimes();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    _alertTimer?.cancel();
    _alertTick?.cancel();
    countdown.dispose();
    alertSeconds.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_countdownTimer == null || !_countdownTimer!.isActive) {
        startCountdown();
      }
    } else if (state == AppLifecycleState.paused) {
      _countdownTimer?.cancel();
      _countdownTimer = null;
    }
  }

  void setTab(int index) {
    if (_tabIndex == index) return;
    _tabIndex = index;
    notifyListeners();
  }

  void toggleNavBar() {
    _showNavBar = !_showNavBar;
    notifyListeners();
  }

  void startCountdown() {
    countdown.value = _countdownText();
    _checkPrayerAlert();
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      countdown.value = _countdownText();
      if (DateTime.now().second % 10 == 0) {
        _checkPrayerAlert();
      }
    });
  }

  void dismissAlert() {
    _alertTimer?.cancel();
    _alertTick?.cancel();
    _showPrayerAlert = false;
    _alertDismissedByUser = true;
    notifyListeners();
  }

  PrayerTimes _todayTimes() {
    final now = DateTime.now();

    if (sl.isRegistered<PrayerEngine>()) {
      final engineTimes = sl<PrayerEngine>().todayTimes;
      if (engineTimes != null) {
        _cachedTodayTimes = engineTimes;
        _cachedTodayDate = now;
        return engineTimes;
      }
    }

    if (_cachedTodayTimes != null &&
        _cachedTodayDate != null &&
        _isSameDay(_cachedTodayDate!, now)) {
      return _cachedTodayTimes!;
    }

    _cachedTodayDate = now;
    _cachedTodayTimes = PrayerTimes.today(_coords, PrayerConfig.params);
    return _cachedTodayTimes!;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _countdownText() {
    final loc = _loc;
    if (loc == null) return '...';
    try {
      final now = DateTime.now();
      final times = _todayTimes();
      final next = times.nextPrayer();

      if (next == Prayer.none) {
        final tomorrow = DateComponents.from(now.add(const Duration(days: 1)));
        final tomorrowTimes =
            PrayerTimes(_coords, tomorrow, PrayerConfig.params);
        final diff = tomorrowTimes.fajr.difference(now);
        if (diff.isNegative) return loc.next_prayer_calculating;
        return loc.next_prayer_tomorrow_fajr(TimeFormat.hhmmss(diff));
      }

      final nextTime = times.timeForPrayer(next);
      if (nextTime == null) return loc.next_prayer_calculating;
      final diff = nextTime.difference(now);
      if (diff.isNegative) return loc.next_prayer_calculating;

      return '${PrayerNames.of(loc, next)} · ${TimeFormat.hhmmss(diff)}';
    } catch (e) {
      AppLogger.warning('Error calculating getNextPrayerString', error: e);
      return loc.next_prayer_calculating;
    }
  }

  void _checkPrayerAlert() {
    try {
      final current = _todayTimes().currentPrayer();
      if (current == Prayer.none || current == Prayer.sunrise) return;
      if (current == _activePrayer) return;

      _activePrayer = current;
      _showPrayerAlert = true;
      _alertDismissedByUser = false;
      alertSeconds.value = AppConstants.prayerAlertDurationSeconds;
      notifyListeners();

      _alertTimer?.cancel();
      _alertTick?.cancel();

      _alertTick = Timer.periodic(const Duration(seconds: 1), (_) {
        final next = alertSeconds.value - 1;
        if (next <= 0) {
          _alertTick?.cancel();
          _showPrayerAlert = false;
          notifyListeners();
        } else {
          alertSeconds.value = next;
        }
      });

      _alertTimer = Timer(
        Duration(seconds: AppConstants.prayerAlertDurationSeconds),
        () {
          _alertTick?.cancel();
          _showPrayerAlert = false;
          notifyListeners();
        },
      );
    } catch (e, st) {
      AppLogger.warning(
        'Prayer alert check failed',
        tag: 'Home',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> _loadCachedPrayerTimes() async {
    try {
      final loaded = await PrayerConfig.getCoordinates();
      _applyTimes(loaded);
    } catch (e, st) {
      AppLogger.warning(
        'Failed to load cached prayer times',
        tag: 'Home',
        error: e,
        stackTrace: st,
      );
      _loadingPrayer = false;
      notifyListeners();
    }
  }

  void _applyTimes(Coordinates coords) {
    final times = PrayerTimes.today(coords, PrayerConfig.params);
    _coords = coords;
    _prayerTimes = {
      'Fajr': TimeFormat.hhmm(times.fajr),
      'Dhuhr': TimeFormat.hhmm(times.dhuhr),
      'Asr': TimeFormat.hhmm(times.asr),
      'Maghrib': TimeFormat.hhmm(times.maghrib),
      'Isha': TimeFormat.hhmm(times.isha),
    };
    _loadingPrayer = false;
    notifyListeners();
  }

  Future<void> _refreshLocationAndTimes() async {
    final now = DateTime.now();
    if (_lastLocationFetch != null &&
        now.difference(_lastLocationFetch!).inMinutes < 10 &&
        _prayerTimes != null) {
      await _loadCachedPrayerTimes();
      return;
    }

    final point = await _location.current();
    if (point != null) {
      _lastLocationFetch = now;
      final cached = await PrayerConfig.getCoordinates();
      final distance = _location.distanceMeters(
        GeoPoint(cached.latitude, cached.longitude),
        point,
      );
      final usingDefault =
          _coords.latitude == _defaultLat && _coords.longitude == _defaultLng;
      if (distance > _relocateMeters || usingDefault) {
        await PrayerConfig.saveCoordinates(point.latitude, point.longitude);
        if (sl.isRegistered<PrayerEngine>()) {
          await sl<PrayerEngine>().reloadCoordinates();
        }
      }
    }

    await _loadCachedPrayerTimes();
  }
}
