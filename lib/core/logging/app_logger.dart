import 'package:logger/logger.dart';

/// Centralized logging system for the application
///
/// Replaces all print() statements with proper logging levels.
/// Logs are automatically formatted and can be filtered by level.
///
/// Usage:
/// ```dart
/// AppLogger.debug('User tapped button');
/// AppLogger.info('Task created successfully');
/// AppLogger.warning('Network connection unstable');
/// AppLogger.error('Failed to save task', error, stackTrace);
/// ```
class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2, // Number of method calls to be displayed
      errorMethodCount: 8, // Number of method calls if stacktrace is provided
      lineLength: 120, // Width of the output
      colors: true, // Colorful log messages
      printEmojis: true, // Print an emoji for each log message
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart, // Timestamp format
    ),
    level: Level.debug, // Default log level
  );

  /// Log a debug message
  ///
  /// Use for detailed information useful during development.
  /// Example: "User navigated to documents page"
  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Log an info message
  ///
  /// Use for general informational messages.
  /// Example: "Task created successfully", "Syncing data"
  static void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Log a warning message
  ///
  /// Use for potentially harmful situations.
  /// Example: "Network connection slow", "Cache miss"
  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Log an error message
  ///
  /// Use for error events that might still allow the app to continue.
  /// Example: "Failed to save task", "API request failed"
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Log a fatal error message
  ///
  /// Use for very severe error events that will presumably lead the app to crash.
  /// Example: "Critical data corruption", "Unrecoverable state"
  static void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  /// Set the minimum log level
  ///
  /// Messages below this level will not be logged.
  /// Useful for production builds to reduce noise.
  static void setLevel(Level level) {
    Logger.level = level;
  }

  /// Check if a certain log level is enabled
  static bool isLevelEnabled(Level level) {
    return Logger.level.index <= level.index;
  }
}
