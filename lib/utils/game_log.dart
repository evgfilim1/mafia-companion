import "../game/log.dart";
import "errors.dart";
import "json/from_json.dart";
import "json/to_json.dart";

enum GameLogVersion {
  // TODO: remove
  v0(0, isDeprecated: true, lastSupportedVersion: null),
  v1(1),
  ;

  static const latest = v1;

  final int value;
  final bool isDeprecated;
  final String? lastSupportedVersion;

  const GameLogVersion(this.value, {this.isDeprecated = false, this.lastSupportedVersion});

  factory GameLogVersion.byValue(int value) => values.firstWhere(
        (e) => e.value == value,
    orElse: () => throw ArgumentError(
      "Unknown value, must be one of: ${values.map((e) => e.value).join(", ")}",
    ),
  );

  static GameLogVersion detectFromJson(dynamic json) {
    final versionInt = switch (json) {
      Map<String, dynamic>() => json["version"] as int,
      List<dynamic>() => 0,
      _ => throw TypeError(),
    };
    final GameLogVersion version;
    try {
      version = GameLogVersion.byValue(versionInt);
    } on ArgumentError {
      throw UnsupportedGameLogVersion(version: versionInt);
    }
    if (version.lastSupportedVersion != null) {
      throw RemovedGameLogVersion(
        version: version.value,
        lastSupportedAppVersion: version.lastSupportedVersion!,
      );
    }
    return version;
  }
}

class VersionedGameLog {
  final List<BaseGameLogItem> log;
  final GameLogVersion version;

  const VersionedGameLog(
      this.log, {
        this.version = GameLogVersion.latest,
      });

  Map<String, dynamic> toJson() => {
    "version": version.value,
    "log": log.map((e) => e.toJson()).toList(),
  };

  factory VersionedGameLog.fromJson(dynamic json, {GameLogVersion? requiredVersion}) {
    final logVersion = GameLogVersion.detectFromJson(json);
    if (requiredVersion != null && logVersion != requiredVersion) {
      throw StateError("Expected $requiredVersion, but got $logVersion");
    }
    final logData = switch (logVersion) {
      GameLogVersion.v0 => (json as List<dynamic>)
          .parseJsonList((e) => fromJson<BaseGameLogItem>(e, gameLogVersion: logVersion)),
      GameLogVersion.v1 => (json["log"] as List<dynamic>)
          .parseJsonList((e) => fromJson<BaseGameLogItem>(e, gameLogVersion: logVersion)),
    };
    return VersionedGameLog(
      logData,
      version: logVersion,
    );
  }
}
