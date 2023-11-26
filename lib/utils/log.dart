import "logger/log_level.dart";
import "logger/stub.dart"
    if (dart.library.io) "./logger/native.dart"
    if (dart.library.html) "./logger/web.dart";

class Logger {
  final String tag;

  static final _loggers = <String, Logger>{};

  factory Logger(String tag) => _loggers.putIfAbsent(tag, () => Logger._(tag));

  const Logger._(this.tag);

  void _log(LogLevel level, String message) => log(level, message, tag: tag);

  /// Logs a message with [LogLevel.verbose] level.
  void verbose(String message) => _log(LogLevel.verbose, message);

  /// An alias for [verbose].
  void v(String message) => verbose(message);

  /// Logs a message with [LogLevel.debug] level.
  void debug(String message) => _log(LogLevel.debug, message);

  /// An alias for [debug].
  void d(String message) => debug(message);

  /// Logs a message with [LogLevel.info] level.
  void info(String message) => _log(LogLevel.info, message);

  /// An alias for [info].
  void i(String message) => info(message);

  /// Logs a message with [LogLevel.warning] level.
  void warning(String message) => _log(LogLevel.warning, message);

  /// An alias for [warning].
  void warn(String message) => warning(message);

  /// An alias for [warning].
  void w(String message) => warning(message);

  /// Logs a message with [LogLevel.error] level.
  void error(String message) => _log(LogLevel.error, message);

  /// An alias for [error].
  void e(String message) => error(message);

  /// Logs a message with [LogLevel.assert_] level.
  void assert_(String message) => _log(LogLevel.assert_, message);

  /// An alias for [assert_].
  void a(String message) => assert_(message);
}
