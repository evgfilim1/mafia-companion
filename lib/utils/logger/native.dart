import "package:flutter/services.dart";

import "log_level.dart";

const _methodChannel = MethodChannel("me.evgfilim1.mafia_companion/methods");

const _logLevelMap = <LogLevel, int>{
  LogLevel.verbose: 0,
  LogLevel.debug: 1,
  LogLevel.info: 2,
  LogLevel.warning: 3,
  LogLevel.error: 4,
  LogLevel.assert_: 100,
};

void log(
  LogLevel level,
  String message, {
  required String tag,
}) =>
    _methodChannel.invokeMethod(
      "log",
      {
        "message": message,
        "level": _logLevelMap[level]!,
        "tag": tag,
      },
    );
