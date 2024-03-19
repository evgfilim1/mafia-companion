import "dart:collection";

import "../game/log.dart";
import "../game/player.dart";
import "../game/states.dart";

enum GameLogVersion {
  v0(0),
  v1(1),
  ;

  static const latest = v1;

  final int value;

  const GameLogVersion(this.value);

  factory GameLogVersion.byValue(int value) => values.firstWhere(
        (e) => e.value == value,
        orElse: () => throw ArgumentError(
          "Unknown value, must be one of: ${values.map((e) => e.value).join(", ")}",
        ),
      );
}

extension MapToJson<T> on Map<int, T> {
  Map<String, T> toJson() => map((k, v) => MapEntry(k.toString(), v));
}

extension MapParseJson on Map<String, dynamic> {
  LinkedHashMap<int, VT> parseJsonMap<VT>() =>
      LinkedHashMap.from(cast<String, VT>().map((k, v) => MapEntry(int.parse(k), v)));
}

extension ListPlayerToJson on List<Player> {
  List<Map<String, dynamic>> toJson() => map((e) => e.toJson()).toList();
}

extension ListBaseGameLogItemToJson on List<BaseGameLogItem> {
  List<Map<String, dynamic>> toJson() => map((e) => e.toJson()).toList();
}

extension ListDynamicParseJson on List<dynamic> {
  List<T> parseJsonList<T>(T Function(Map<String, dynamic> json) fromJson) =>
      cast<Map<String, dynamic>>().map(fromJson).toList();
}

extension BaseGameStateJson on BaseGameState {
  Map<String, dynamic> toJson() => switch (this) {
        GameStatePrepare() => {},
        GameStateWithPlayer(:final currentPlayerNumber) => {
            "currentPlayerNumber": currentPlayerNumber,
          },
        GameStateSpeaking(
          :final currentPlayerNumber,
          :final accusations,
          :final canOnlyAccuse,
          :final hasHalfTime,
        ) =>
          {
            "currentPlayerNumber": currentPlayerNumber,
            "accusations": accusations.toJson(),
            "canOnlyAccuse": canOnlyAccuse,
            "hasHalfTime": hasHalfTime,
          },
        GameStateVoting(:final votes, :final currentPlayerNumber, :final currentPlayerVotes) => {
            "votes": votes.toJson(),
            "currentPlayerNumber": currentPlayerNumber,
            "currentPlayerVotes": currentPlayerVotes,
          },
        GameStateKnockoutVoting(:final playerNumbers, :final votes) => {
            "playerNumbers": playerNumbers,
            "votes": votes,
          },
        GameStateWithPlayers(:final playerNumbers) => {
            "playerNumbers": playerNumbers,
          },
        GameStateNightKill(:final thisNightKilledPlayerNumber) => {
            "thisNightKilledPlayerNumber": thisNightKilledPlayerNumber,
          },
        GameStateNightCheck(:final activePlayerNumber) => {
            "activePlayerNumber": activePlayerNumber,
          },
        GameStateBestTurn(:final currentPlayerNumber, :final playerNumbers) => {
            "currentPlayerNumber": currentPlayerNumber,
            "playerNumbers": playerNumbers,
          },
        GameStateWithIterablePlayers(:final playerNumbers, :final currentPlayerIndex) => {
            "playerNumbers": playerNumbers,
            "currentPlayerIndex": currentPlayerIndex,
          },
        GameStateFinish(:final winner) => {
            "winner": winner?.name,
          },
      }
        ..addAll({
          "stage": stage.name,
          "day": day,
          "players": players.map((e) => e.toJson()).toList(),
        });
}

extension BaseGameLogItemJson on BaseGameLogItem {
  Map<String, dynamic> toJson() => switch (this) {
        StateChangeGameLogItem(:final oldState, :final newState) => {
            "oldState": oldState?.toJson(),
            "newState": newState.toJson(),
          },
        PlayerCheckedGameLogItem(:final day, :final playerNumber, :final checkedByRole) => {
            "day": day,
            "playerNumber": playerNumber,
            "checkedByRole": checkedByRole.name,
          },
        PlayerWarnsChangedGameLogItem(
          :final day,
          :final playerNumber,
          :final oldWarns,
          :final currentWarns,
        ) =>
          {
            "day": day,
            "playerNumber": playerNumber,
            "oldWarns": oldWarns,
            "currentWarns": currentWarns,
          },
        PlayerKickedGameLogItem(:final day, :final playerNumber, :final isOtherTeamWin) => {
            "day": day,
            "playerNumber": playerNumber,
            "isOtherTeamWin": isOtherTeamWin,
          },
      };
}

extension PlayerJson on Player {
  Map<String, dynamic> toJson() => {
        "role": role.name,
        "number": number,
        "nickname": nickname,
        "isAlive": isAlive,
        "warns": warns,
      };
}

BaseGameLogItem _gameLogFromJson(Map<String, dynamic> json, {required GameLogVersion version}) {
  if (json.containsKey("newState")) {
    return StateChangeGameLogItem(
      oldState: json["oldState"] != null
          ? fromJson<BaseGameState>(
              json["oldState"] as Map<String, dynamic>,
              gameLogVersion: version,
            )
          : null,
      newState: fromJson(
        json["newState"] as Map<String, dynamic>,
        gameLogVersion: version,
      ),
    );
  }
  if (json.containsKey("checkedByRole")) {
    return PlayerCheckedGameLogItem(
      day: switch (version) {
        GameLogVersion.v0 => 0,
        GameLogVersion.v1 => json["day"] as int,
      },
      playerNumber: json["playerNumber"] as int,
      checkedByRole: PlayerRole.byName(json["checkedByRole"] as String),
    );
  }
  if (json.containsKey("isOtherTeamWin")) {
    return PlayerKickedGameLogItem(
      day: json["day"] as int,
      playerNumber: json["playerNumber"] as int,
      isOtherTeamWin: json["isOtherTeamWin"] as bool,
    );
  }
  if (json.containsKey("oldWarns")) {
    return PlayerWarnsChangedGameLogItem(
      day: json["day"] as int,
      playerNumber: json["playerNumber"] as int,
      oldWarns: json["oldWarns"] as int,
      currentWarns: json["currentWarns"] as int,
    );
  }
  throw ArgumentError.value(json, "json", "Unknown game log item");
}

BaseGameState _gameStateFromJson(Map<String, dynamic> json, {required GameLogVersion version}) {
  var stageString = json["stage"] as String;
  if (version == GameLogVersion.v0 && stageString == "dropTableVoting") {
    stageString = GameStage.knockoutVoting.name; // compatibility for old logs
  }
  final stage = GameStage.byName(stageString);
  final day = json["day"] as int;
  final players = (json["players"] as List<dynamic>)
      .parseJsonList((e) => fromJson<Player>(e, gameLogVersion: version));
  return switch (stage) {
    GameStage.prepare => GameStatePrepare(players: players),
    GameStage.night0 || GameStage.preVoting || GameStage.preFinalVoting => GameStateWithPlayers(
        stage: stage,
        day: day,
        players: players,
        playerNumbers: (json["playerNumbers"] as List<dynamic>).cast<int>(),
      ),
    GameStage.night0SheriffCheck || GameStage.nightLastWords => GameStateWithPlayer(
        stage: stage,
        day: day,
        players: players,
        currentPlayerNumber: json["currentPlayerNumber"] as int,
      ),
    GameStage.speaking => GameStateSpeaking(
        day: day,
        players: players,
        currentPlayerNumber: json["currentPlayerNumber"] as int,
        accusations: (json["accusations"] as Map<String, dynamic>).parseJsonMap(),
        canOnlyAccuse: switch (version) {
          GameLogVersion.v0 => false,
          GameLogVersion.v1 => json["canOnlyAccuse"] as bool,
        },
        hasHalfTime: switch (version) {
          GameLogVersion.v0 => false,
          GameLogVersion.v1 => json["hasHalfTime"] as bool,
        },
      ),
    GameStage.voting || GameStage.finalVoting => GameStateVoting(
        stage: stage,
        day: day,
        players: players,
        votes: (json["votes"] as Map<String, dynamic>).parseJsonMap(),
        currentPlayerNumber: json["currentPlayerNumber"] as int,
        currentPlayerVotes: json["currentPlayerVotes"] as int?,
      ),
    GameStage.excuse || GameStage.dayLastWords => GameStateWithIterablePlayers(
        stage: stage,
        day: day,
        players: players,
        playerNumbers: (json["playerNumbers"] as List<dynamic>).cast<int>(),
        currentPlayerIndex: json["currentPlayerIndex"] as int,
      ),
    GameStage.knockoutVoting => GameStateKnockoutVoting(
        day: day,
        players: players,
        playerNumbers: (json["playerNumbers"] as List<dynamic>).cast<int>(),
        votes: switch (version) {
          GameLogVersion.v0 => json["votesForDropTable"] as int,
          GameLogVersion.v1 => json["votes"] as int,
        },
      ),
    GameStage.nightKill => GameStateNightKill(
        day: day,
        players: players,
        thisNightKilledPlayerNumber: json["thisNightKilledPlayerNumber"] as int?,
      ),
    GameStage.nightCheck => GameStateNightCheck(
        day: day,
        players: players,
        activePlayerNumber: json["activePlayerNumber"] as int,
      ),
    GameStage.bestTurn => GameStateBestTurn(
        day: day,
        players: players,
        currentPlayerNumber: json["currentPlayerNumber"] as int,
        playerNumbers: (json["playerNumbers"] as List<dynamic>).cast<int>(),
      ),
    GameStage.finish => GameStateFinish(
        day: day,
        players: players,
        winner: json["winner"] != null ? RoleTeam.byName(json["winner"]! as String) : null,
      ),
  };
}

Player _playerFromJson(Map<String, dynamic> json, {required GameLogVersion version}) => Player(
      role: PlayerRole.byName(json["role"] as String),
      number: json["number"] as int,
      nickname: json["nickname"] as String?,
      isAlive: json["isAlive"] as bool,
      warns: json["warns"] as int,
    );

T fromJson<T>(Map<String, dynamic> json, {required GameLogVersion gameLogVersion}) => switch (T) {
      const (BaseGameLogItem) => _gameLogFromJson(json, version: gameLogVersion) as T,
      const (BaseGameState) => _gameStateFromJson(json, version: gameLogVersion) as T,
      const (Player) => _playerFromJson(json, version: gameLogVersion) as T,
      _ => throw UnimplementedError("fromJson for $T"),
    };

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
    final logVersionInt = switch (json) {
      Map<String, dynamic>() => json["version"] as int,
      List<dynamic>() => 0,
      _ => throw UnsupportedError("Unexpected type: ${json.runtimeType}"),
    };
    final logVersion = GameLogVersion.byValue(logVersionInt);
    if (requiredVersion != null && logVersion != requiredVersion) {
      throw ArgumentError.value(
        logVersion,
        "logVersion",
        "Expected $requiredVersion, but got $logVersion",
      );
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
