import "package:flutter/cupertino.dart";

import "../../game/log.dart";
import "../../game/player.dart";
import "../errors.dart";
import "../extensions.dart";
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

@immutable
class GameLogWithPlayers {
  const GameLogWithPlayers({
    required this.log,
    required this.players,
  });

  static List<Player> _extractLegacyPlayers(dynamic json, GameLogVersion version) =>
      (json as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map((e) => playerFromJson(e, version: version))
          .toUnmodifiableList();

  factory GameLogWithPlayers.fromJson(dynamic json, {required GameLogVersion version}) {
    if (json is Map<String, dynamic>) {
      return GameLogWithPlayers(
        log: (json["log"] as List<dynamic>)
            .parseJsonList((e) => gameLogFromJson(e, version: version)),
        players: (json["players"] as List<dynamic>)
            .parseJsonList((e) => playerFromJson(e, version: version)),
      );
    }
    if (json is List<dynamic> && version < GameLogVersion.v2) {
      return GameLogWithPlayers(
        log: json.parseJsonList((e) => gameLogFromJson(e, version: version)),
        players: _extractLegacyPlayers(json[0]["newState"]["players"], version),
      );
    }
    throw ArgumentError.value(
      json,
      "json",
      "Cannot parse ${json.runtimeType} as GameLogWithPlayers",
    );
  }

  final Iterable<BaseGameLogItem> log;
  final Iterable<Player> players;

  Map<String, dynamic> toJson() => {
        "log": log.map((e) => e.toJson()).toList(),
        "players": players.map((e) => e.toJson()).toList(),
      };
}

class VersionedGameLog extends Versioned<GameLogVersion, GameLogWithPlayers> {
  const VersionedGameLog(
    super.value, {
    super.version = GameLogVersion.latest,
  });

  @override
  String get valueKey => "log";

  @override
  dynamic versionToJson(GameLogVersion value) => value.value;

  @override
  dynamic valueToJson(GameLogWithPlayers value) => value.toJson();

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
      /*const v0 = _LegacyGameLogVersion.v0;
      throw RemovedVersion(
        version: v0.value,
        lastSupportedAppVersion: v0.lastSupportedAppVersion,
      );*/
      return VersionedGameLog(
        GameLogWithPlayers.fromJson(json, version: GameLogVersion.v0),
        version: GameLogVersion.v0,
      );
    }
    if (json is Map<String, dynamic>) {
      return Versioned.fromJsonImpl(
        json,
        valueKey: "log",
        versionFromJson: _versionFromJson,
        valueFromJson: (json, version) => switch (version) {
          GameLogVersion.v0 => throw AssertionError("already handled"),
          GameLogVersion.v2 => GameLogWithPlayers.fromJson(json, version: version),
        },
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
