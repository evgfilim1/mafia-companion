import "../../game/log.dart";
import "../errors.dart";
import "../json/from_json.dart";
import "../json/to_json.dart";
import "base.dart";

enum _LegacyGameLogVersion {
  v0(0, "0.3.0-rc.2"),
  ;

  final int value;
  final String lastSupportedAppVersion;

  const _LegacyGameLogVersion(this.value, this.lastSupportedAppVersion);

  factory _LegacyGameLogVersion.byValue(int value) => values.singleWhere(
        (e) => e.value == value,
        orElse: () => throw ArgumentError(
          "Unknown value, must be one of: ${values.map((e) => e.value).join(", ")}",
        ),
      );
}

enum GameLogVersion implements Comparable<GameLogVersion> {
  v0(0, isDeprecated: true),
  v1(1),
  v2(2),
  ;

  static const latest = v2;

  final int value;
  final bool isDeprecated;

  const GameLogVersion(this.value, {this.isDeprecated = false});

  factory GameLogVersion.byValue(int value) => values.singleWhere(
        (e) => e.value == value,
        orElse: () => throw ArgumentError(
          "Unknown value, must be one of: ${values.map((e) => e.value).join(", ")}",
        ),
      );

  @override
  int compareTo(GameLogVersion other) => value.compareTo(other.value);

  bool operator <(GameLogVersion other) => compareTo(other) < 0;

  bool operator <=(GameLogVersion other) => compareTo(other) <= 0;

  bool operator >(GameLogVersion other) => compareTo(other) > 0;

  bool operator >=(GameLogVersion other) => compareTo(other) >= 0;
}

class VersionedGameLog extends Versioned<GameLogVersion, Iterable<BaseGameLogItem>> {
  const VersionedGameLog(
    super.value, {
    super.version = GameLogVersion.latest,
  });

  @override
  String get valueKey => "log";

  @override
  dynamic versionToJson(GameLogVersion value) => value.value;

  @override
  dynamic valueToJson(Iterable<BaseGameLogItem> value) => value.map((e) => e.toJson()).toList();

  static GameLogVersion _versionFromJson(dynamic value) {
    final versionInt = value as int;
    final GameLogVersion version;
    try {
      version = GameLogVersion.byValue(versionInt);
    } on ArgumentError {
      try {
        final legacyVersion = _LegacyGameLogVersion.byValue(versionInt);
        throw RemovedVersion(
          version: versionInt,
          lastSupportedAppVersion: legacyVersion.lastSupportedAppVersion,
        );
      } on ArgumentError {
        throw UnsupportedVersion(version: versionInt);
      }
    }
    return version;
  }

  factory VersionedGameLog.fromJson(dynamic json) {
    if (json is List<dynamic>) {
      /*throw RemovedGameLogVersion(
        version: 0,
        lastSupportedAppVersion: GameLogVersion.v0.lastSupportedVersion!,
      );*/
      return VersionedGameLog(
        json.parseJsonList((e) => gameLogFromJson(e, version: GameLogVersion.v0)),
        version: GameLogVersion.v0,
      );
    }
    if (json is Map<String, dynamic>) {
      return Versioned.fromJsonImpl(
        json,
        valueKey: "log",
        versionFromJson: _versionFromJson,
        valueFromJson: (json, version) =>
            (json as List<dynamic>).parseJsonList((e) => gameLogFromJson(e, version: version)),
        create: VersionedGameLog.new,
      );
    }
    throw ArgumentError.value(
      json,
      "json",
      "Cannot parse ${json.runtimeType} as VersionedGameLog",
    );
  }
}
