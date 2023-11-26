// ignore: avoid_web_libraries_in_flutter
import "dart:js" as js;

import "log_level.dart";

void log(LogLevel level, String message, {required String tag}) {
  final logFn = switch (level) {
    LogLevel.verbose => "log",
    LogLevel.debug => "log",
    LogLevel.info => "info",
    LogLevel.warning => "warn",
    LogLevel.error => "error",
    LogLevel.assert_ => "error",
  };
  js.context["console"].callMethod(logFn, ["[$tag] $message"]);
}
