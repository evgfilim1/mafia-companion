import "dart:collection";

import "../game/log.dart";
import "../game/player.dart";
import "../game/states.dart";

extension MapToJson<T> on Map<int, T> {
  Map<String, T> toJson() => map((k, v) => MapEntry(k.toString(), v));
}

extension MapParseJson<C, T> on LinkedHashMap<String, T> {
  LinkedHashMap<int, T> parseJsonMap() =>
      LinkedHashMap.from(map((k, v) => MapEntry(int.parse(k), v)));
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
        GameStateSpeaking(:final currentPlayerNumber, :final accusations) => {
            "currentPlayerNumber": currentPlayerNumber,
            "accusations": accusations.toJson(),
          },
        GameStateVoting(:final votes, :final currentPlayerNumber, :final currentPlayerVotes) => {
            "votes": votes.toJson(),
            "currentPlayerNumber": currentPlayerNumber,
            "currentPlayerVotes": currentPlayerVotes,
          },
        GameStateDropTableVoting(:final playerNumbers, :final votesForDropTable) => {
            "playerNumbers": playerNumbers,
            "votesForDropTable": votesForDropTable,
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
        PlayerCheckedGameLogItem(:final playerNumber, :final checkedByRole) => {
            "playerNumber": playerNumber,
            "checkedByRole": checkedByRole.name,
          },
      };
}

extension PlayerJson on Player {
  Map<String, dynamic> toJson() => {
        "role": role.name,
        "number": number,
        "isAlive": isAlive,
        "warns": warns,
      };
}

BaseGameLogItem _gameLogFromJson(Map<String, dynamic> json) => json["newState"] != null
    ? StateChangeGameLogItem(
        oldState:
            json["oldState"] != null ? fromJson(json["oldState"] as Map<String, dynamic>) : null,
        newState: fromJson(json["newState"] as Map<String, dynamic>),
      )
    : PlayerCheckedGameLogItem(
        playerNumber: json["playerNumber"] as int,
        checkedByRole: PlayerRole.byName(json["checkedByRole"] as String),
      );

BaseGameState _gameStateFromJson(Map<String, dynamic> json) {
  final stage = GameStage.byName(json["stage"] as String);
  final day = json["day"] as int;
  final players = (json["players"] as List<dynamic>).parseJsonList(fromJson<Player>);
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
        accusations: (json["accusations"] as LinkedHashMap<String, int>).parseJsonMap(),
      ),
    GameStage.voting || GameStage.finalVoting => GameStateVoting(
        stage: stage,
        day: day,
        players: players,
        votes: (json["votes"] as LinkedHashMap<String, int?>).parseJsonMap(),
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
    GameStage.dropTableVoting => GameStateDropTableVoting(
        day: day,
        players: players,
        playerNumbers: (json["playerNumbers"] as List<dynamic>).cast<int>(),
        votesForDropTable: json["votesForDropTable"] as int,
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
        winner: json["winner"] != null ? PlayerRole.byName(json["winner"]! as String) : null,
      ),
  };
}

Player _playerFromJson(Map<String, dynamic> json) => Player(
      role: PlayerRole.byName(json["role"] as String),
      number: json["number"] as int,
      isAlive: json["isAlive"] as bool,
      warns: json["warns"] as int,
    );

T fromJson<T>(Map<String, dynamic> json) => switch (T) {
      BaseGameLogItem _ => _gameLogFromJson(json) as T,
      BaseGameState _ => _gameStateFromJson(json) as T,
      Player _ => _playerFromJson(json) as T,
      _ => throw UnimplementedError("fromJson for $T"),
    };
