import 'dart:async';
import 'package:adhan/adhan.dart';
import 'package:flutter/widgets.dart';
import 'package:rafiki_app/core/logging/app_logger.dart';
import 'package:rafiki_app/core/di/service_locator.dart';
import 'bonus_engine.dart';
import 'prayer_streak_engine.dart';
import 'prayer_rule_engine.dart';
import 'package:rafiki_app/features/prayer/data/services/prayer_config.dart';

enum PrayerEvent {
  prayerStarted,
  prayerEnded,
  midnight,
}

class PrayerEngine with WidgetsBindingObserver {
  PrayerEngine._internal();
  static final PrayerEngine instance = PrayerEngine._internal();

  final StreamController<PrayerEvent> _eventController = StreamController<PrayerEvent>.broadcast();
  Stream<PrayerEvent> get eventStream => _eventController.stream;

  PrayerTimes? _todayTimes;
  DateTime? _lastComputedDate;
  Timer? _tickTimer;
  
  Prayer _currentPrayer = Prayer.none;
  Prayer get currentPrayer => _currentPrayer;

  Prayer _nextPrayer = Prayer.none;
  Prayer get nextPrayer => _nextPrayer;

  void initialize() {
    WidgetsBinding.instance.addObserver(this);
    _updatePrayerTimesIfNeeded();
    _evaluatePrayerWindows();
    _startTicker();
  }

  Future<void> reloadCoordinates() async {
    final coords = await PrayerConfig.getCoordinates();
    _todayTimes = PrayerTimes.today(coords, PrayerConfig.params);
    if (sl.isRegistered<PrayerRuleEngine>()) {
      sl<PrayerRuleEngine>().times = _todayTimes!;
    }
    AppLogger.info('Reloaded prayer times for new coordinates: ${coords.latitude}, ${coords.longitude}', tag: 'PrayerEngine');
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tickTimer?.cancel();
    _eventController.close();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updatePrayerTimesIfNeeded();
      _evaluatePrayerWindows();
      if (_tickTimer == null || !_tickTimer!.isActive) {
        _startTicker();
      }
    } else if (state == AppLifecycleState.paused) {
      _tickTimer?.cancel();
      _tickTimer = null;
    }
  }

  void _startTicker() {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _updatePrayerTimesIfNeeded();
      _evaluatePrayerWindows();
    });
  }

  Future<void> _updatePrayerTimesIfNeeded() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    if (_lastComputedDate == null || _lastComputedDate != today) {
      final oldDate = _lastComputedDate;
      _lastComputedDate = today;
      final coords = await PrayerConfig.getCoordinates();
      _todayTimes = PrayerTimes.today(coords, PrayerConfig.params);
      
      // If we crossed midnight
      if (oldDate != null && oldDate.isBefore(today)) {
        AppLogger.info('Midnight date boundary crossed. Emitting midnight event.', tag: 'PrayerEngine');
        _eventController.add(PrayerEvent.midnight);
      }
    }
  }

  void _evaluatePrayerWindows() {
    if (_todayTimes == null) return;
    
    final times = _todayTimes!;
    
    final current = times.currentPrayer();
    final next = times.nextPrayer();
    
    bool changed = false;

    // Check if current prayer has changed
    if (current != _currentPrayer) {
      _currentPrayer = current;
      changed = true;
      AppLogger.info('Current prayer changed to: $current', tag: 'PrayerEngine');
    }
    
    if (next != _nextPrayer) {
      _nextPrayer = next;
      changed = true;
    }
    
    if (changed) {
      if (_currentPrayer != Prayer.none && _currentPrayer != Prayer.sunrise) {
        _eventController.add(PrayerEvent.prayerStarted);
      } else {
        _eventController.add(PrayerEvent.prayerEnded);
      }
    }
  }
  
  PrayerTimes? get todayTimes => _todayTimes;

  Prayer getActiveFardhPrayer(DateTime now) {
    if (_todayTimes == null) return Prayer.none;
    final times = _todayTimes!;
    
    if (now.isAfter(times.fajr) && now.isBefore(times.sunrise)) {
      return Prayer.fajr;
    } else if (now.isAfter(times.dhuhr) && now.isBefore(times.asr)) {
      return Prayer.dhuhr;
    } else if (now.isAfter(times.asr) && now.isBefore(times.maghrib)) {
      return Prayer.asr;
    } else if (now.isAfter(times.maghrib) && now.isBefore(times.isha)) {
      return Prayer.maghrib;
    } else {
      if (now.isAfter(times.isha)) {
        return Prayer.isha;
      }
      if (now.isBefore(times.fajr)) {
        return Prayer.none;
      }
    }
    return Prayer.none;
  }

  Future<bool> addPrayerEvent(Prayer prayer, CustomPrayerEventType type, {double score = 0.0, int? sunnahIndex}) async {
    AppLogger.info('addPrayerEvent: prayer=$prayer, type=$type, score=$score, sunnahIndex=$sunnahIndex', tag: 'PrayerEngine');

    bool success = false;
    if (type == CustomPrayerEventType.sunnah) {
      if (sunnahIndex != null) {
        success = await sl<BonusEngine>().completeSunnah(prayer, sunnahIndex, score);
      }
    } else if (type == CustomPrayerEventType.onTime) {
      success = await sl<PrayerStreakEngine>().completePrayer(prayer, score, isQada: false);
      if (success) {
        await sl<BonusEngine>().checkAndApplyConsistencyBonus();
      }
    } else if (type == CustomPrayerEventType.jamaah) {
      success = await sl<PrayerStreakEngine>().completePrayer(prayer, score, isQada: false);
      if (success) {
        await sl<BonusEngine>().checkAndApplyCongregationBonus();
        await sl<BonusEngine>().checkAndApplyConsistencyBonus();
      }
    } else if (type == CustomPrayerEventType.qada) {
      success = await sl<PrayerStreakEngine>().completePrayer(prayer, score, isQada: true);
      if (success) {
        await sl<BonusEngine>().checkAndApplyCongregationBonus();
        await sl<BonusEngine>().checkAndApplyConsistencyBonus();
      }
    } else if (type == CustomPrayerEventType.missed) {
      // Missed prayer
      AppLogger.info('Prayer $prayer marked as missed.', tag: 'PrayerEngine');
      success = true;
    }

    return success;
  }
}

enum CustomPrayerEventType {
  onTime,
  missed,
  qada,
  jamaah,
  sunnah,
}
