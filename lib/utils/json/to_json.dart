import "../../game/log.dart";
import "../../game/player.dart";
import "../../game/states.dart";
import "../db/models.dart" as db_models;

extension MapJson<T> on Map<int, T> {
  Map<String, T> toJson() => map((k, v) => MapEntry(k.toString(), v));
}

extension ListPlayerStateJson on List<PlayerState> {
  List<Map<String, dynamic>> toJson() => map((e) => e.toJson()).toList();
}

extension ListBaseGameLogItemJson on List<BaseGameLogItem> {
  List<Map<String, dynamic>> toJson() => map((e) => e.toJson()).toList();
}

extension BaseGameStateJson on BaseGameState {
  Map<String, dynamic> toJson() => switch (this) {
        GameStatePrepare() || GameStateNightRest() => {},
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
        GameStateNightCheck(:final activePlayerNumber, :final activePlayerTeam) => {
            "activePlayerNumber": activePlayerNumber,
            "activePlayerTeam": activePlayerTeam.name,
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
          "playerStates": playerStates.map((e) => e.toJson()).toList(),
        });
}

extension BaseGameLogItemJson on BaseGameLogItem {
  Map<String, dynamic> toJson() => switch (this) {
        StateChangeGameLogItem(:final newState) => {
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
        "number": number,
        "role": role.name,
        "nickname": nickname,
      };
}

extension PlayerStateJson on PlayerState {
  Map<String, dynamic> toJson() => {
        "isAlive": isAlive,
        "warns": warns,
        "isKicked": isKicked,
      };
}

extension MapRoleJson on Map<PlayerRole, int> {
  Map<String, int> toJson() => map((k, v) => MapEntry(k.name, v));
}

extension PlayerStatsJson on db_models.PlayerStats {
  Map<String, dynamic> toJson() => {
        "gamesByRole": gamesByRole.toJson(),
        "winsByRole": winsByRole.toJson(),
        "totalWarns": totalWarns,
        "totalKicks": totalKicks,
        "totalOtherTeamWins": totalOtherTeamWins,
        "totalGuessedMafia": totalGuessedMafia,
        "totalFoundMafia": totalFoundMafia,
        "totalFoundSheriff": totalFoundSheriff,
        "totalWasKilledFirstNight": totalWasKilledFirstNight,
      };
}

extension DbPlayerJson on db_models.PlayerWithStats {
  Map<String, dynamic> toJson() => {
        "nickname": player.nickname,
        "realName": player.realName,
        "stats": stats.toJson(),
      };
}
