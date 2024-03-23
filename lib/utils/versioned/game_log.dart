import "../../game/log.dart";
import "../errors.dart";
import "../json/from_json.dart";
import "../json/to_json.dart";
import "base.dart";

enum GameLogVersion {
  v0(0, isDeprecated: true, lastSupportedVersion: null),
  v1(1),
  ;

  static const latest = v1;

  final int value;
  final bool isDeprecated;
  final String? lastSupportedVersion;

  const GameLogVersion(this.value, {this.isDeprecated = false, this.lastSupportedVersion});

  factory GameLogVersion.byValue(int value) => values.singleWhere(
        (e) => e.value == value,
        orElse: () => throw ArgumentError(
          "Unknown value, must be one of: ${values.map((e) => e.value).join(", ")}",
        ),
      );
}

class VersionedGameLog extends Versioned<GameLogVersion, List<BaseGameLogItem>> {
  const VersionedGameLog(
    super.value, {
    super.version = GameLogVersion.latest,
  });

  @override
  String get valueKey => "log";

  @override
  dynamic versionToJson(GameLogVersion value) => value.value;

  @override
  dynamic valueToJson(List<BaseGameLogItem> value) => value.map((e) => e.toJson()).toList();

  static GameLogVersion _versionFromJson(dynamic value) {
    final versionInt = value as int;
    final GameLogVersion version;
    try {
      version = GameLogVersion.byValue(versionInt);
    } on ArgumentError {
      throw UnsupportedVersion(version: versionInt);
    }
    if (version.lastSupportedVersion != null) {
      throw RemovedVersion(
        version: versionInt,
        lastSupportedAppVersion: version.lastSupportedVersion!,
      );
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
