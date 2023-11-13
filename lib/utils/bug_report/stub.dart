import "package:flutter/material.dart";

import "../../game/log.dart";
import "../../game/player.dart";
import "../../game/states.dart";

extension MapJson<T> on Map<int, T> {
  Map<String, T> get json => {for (final e in entries) e.key.toString(): e.value};
}

extension PlayerData on Player {
  Map<String, dynamic> get data => {
        "role": role.name,
        "number": number,
        "isAlive": isAlive,
        "warns": warns,
      };
}

extension StateData on BaseGameState {
  Map<String, dynamic> get data => switch (this) {
        GameStatePrepare() => {},
        GameStateWithPlayer(:final currentPlayerNumber) => {
            "currentPlayerNumber": currentPlayerNumber,
          },
        GameStateSpeaking(:final currentPlayerNumber, :final accusations) => {
            "currentPlayerNumber": currentPlayerNumber,
            "accusations": accusations.json,
          },
        GameStateVoting(:final votes, :final currentPlayerNumber, :final currentPlayerVotes) => {
            "votes": votes.json,
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
          "players": players.map((e) => e.data).toList(),
        });
}

extension GameLogItemData on BaseGameLogItem {
  Map<String, dynamic> get data => switch (this) {
        StateChangeGameLogItem(:final oldState, :final newState) => {
            "oldState": oldState?.data,
            "newState": newState.data,
          },
        PlayerCheckedGameLogItem(:final playerNumber, :final checkedByRole) => {
            "playerNumber": playerNumber,
            "checkedByRole": checkedByRole,
          },
      };
}

Future<void> reportBug(BuildContext context) async {
  throw UnimplementedError("stub");
}
