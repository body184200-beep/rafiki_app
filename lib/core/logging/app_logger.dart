/// Centralised logging system for the app.
///
/// Provides structured logging with severity levels, timestamps,
/// and category tags. Designed to be extended later with crash
/// reporting services (e.g. Firebase Crashlytics, Sentry).
///
/// Usage:
/// ```dart
/// AppLogger.info('Prayer transition', tag: 'PrayerEngine');
/// AppLogger.error('Failed to save', error: e, stackTrace: st, tag: 'Hive');
/// ```
library;

import 'package:flutter/foundation.dart';

/// Log severity levels, ordered by increasing importance.
enum LogLevel {
  debug,
  info,
  warning,
  error,
  fatal,
}

/// A single structured log entry.
class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String? tag;
  final Object? error;
  final StackTrace? stackTrace;

  const LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.tag,
    this.error,
    this.stackTrace,
  });

  @override
  String toString() {
    final buf = StringBuffer()
      ..write('[${timestamp.toIso8601String()}]')
      ..write(' ${level.name.toUpperCase()}');
    if (tag != null) buf.write(' [$tag]');
    buf.write(': $message');
    if (error != null) buf.write('\n  Error: $error');
    if (stackTrace != null) buf.write('\n  StackTrace: $stackTrace');
    return buf.toString();
  }
}

/// Callback type for external log consumers (crash reporting, analytics).
typedef LogListener = void Function(LogEntry entry);

/// Centralised logger – singleton accessed via static methods.
///
/// In debug mode, all messages are printed to console.
/// In release mode, only warning+ are kept (configurable).
/// External listeners can be added for crash-reporting hooks.
class AppLogger {
  AppLogger._();

  static LogLevel _minLevel = kDebugMode ? LogLevel.debug : LogLevel.warning;

  /// In-memory ring buffer of recent logs (last 200).
  /// Useful for on-device diagnostics / export.
  static final List<LogEntry> _recentLogs = [];
  static const int _maxRecentLogs = 200;

  /// External listeners (e.g. Crashlytics, Sentry).
  static final List<LogListener> _listeners = [];

  // ── Configuration ─────────────────────────────────────────

  /// Set the minimum level that will be logged.
  static void setMinLevel(LogLevel level) => _minLevel = level;

  /// Register an external listener for log entries.
  static void addListener(LogListener listener) => _listeners.add(listener);

  /// Remove a previously registered listener.
  static void removeListener(LogListener listener) =>
      _listeners.remove(listener);

  /// Get a copy of recent log entries.
  static List<LogEntry> get recentLogs => List.unmodifiable(_recentLogs);

  /// Clear the in-memory log buffer.
  static void clearLogs() => _recentLogs.clear();

  // ── Logging Methods ───────────────────────────────────────

  static void debug(String message, {String? tag}) =>
      _log(LogLevel.debug, message, tag: tag);

  static void info(String message, {String? tag}) =>
      _log(LogLevel.info, message, tag: tag);

  static void warning(String message,
          {String? tag, Object? error, StackTrace? stackTrace}) =>
      _log(LogLevel.warning, message,
          tag: tag, error: error, stackTrace: stackTrace);

  static void error(String message,
          {String? tag, Object? error, StackTrace? stackTrace}) =>
      _log(LogLevel.error, message,
          tag: tag, error: error, stackTrace: stackTrace);

  static void fatal(String message,
          {String? tag, Object? error, StackTrace? stackTrace}) =>
      _log(LogLevel.fatal, message,
          tag: tag, error: error, stackTrace: stackTrace);

  // ── Internal ──────────────────────────────────────────────

  static void _log(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (level.index < _minLevel.index) return;

    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
    );

    // Store in ring buffer.
    _recentLogs.add(entry);
    if (_recentLogs.length > _maxRecentLogs) {
      _recentLogs.removeAt(0);
    }

    // Console output in debug mode.
    if (kDebugMode) {
      debugPrint(entry.toString());
    }

    // Notify external listeners.
    for (final listener in _listeners) {
      try {
        listener(entry);
      } catch (_) {
        // Never let a listener crash the app.
      }
    }
  }
}
