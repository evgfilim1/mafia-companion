import "dart:collection";

import "../../game/log.dart";
import "../../game/player.dart";
import "../../game/states.dart";
import "../db/models.dart" as db_models;
import "../game_log.dart";

extension MapParseJson on Map<String, dynamic> {
  LinkedHashMap<int, VT> parseJsonMap<VT>() =>
      LinkedHashMap.from(cast<String, VT>().map((k, v) => MapEntry(int.parse(k), v)));
}

extension ListDynamicParseJson on List<dynamic> {
  List<T> parseJsonList<T>(T Function(Map<String, dynamic> json) fromJson) =>
      cast<Map<String, dynamic>>().map(fromJson).toList();
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

db_models.Player _dbPlayerFromJson(
  Map<String, dynamic> json, {
  required GameLogVersion version,
}) =>
    db_models.Player(
      nickname: json["nickname"] as String,
    );

T fromJson<T>(Map<String, dynamic> json, {required GameLogVersion gameLogVersion}) => switch (T) {
  const (BaseGameLogItem) => _gameLogFromJson(json, version: gameLogVersion) as T,
  const (BaseGameState) => _gameStateFromJson(json, version: gameLogVersion) as T,
  const (Player) => _playerFromJson(json, version: gameLogVersion) as T,
  const (db_models.Player) => _dbPlayerFromJson(json, version: gameLogVersion) as T,
  _ => throw UnimplementedError("fromJson for $T"),
};
