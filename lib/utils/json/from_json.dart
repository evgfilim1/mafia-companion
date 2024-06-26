import "dart:collection";

import "../../game/log.dart";
import "../../game/player.dart";
import "../../game/states.dart";
import "../db/models.dart" as db_models;
import "../versioned/db_players.dart";
import "../versioned/game_log.dart";

extension MapParseJson on Map<String, dynamic> {
  LinkedHashMap<int, VT> parseJsonIntToIntMap<VT extends int?>() =>
      LinkedHashMap.from(cast<String, VT>().map((k, v) => MapEntry(int.parse(k), v)));

  Map<String, VT> parseJsonMap<VT>(VT Function(dynamic json) fromJson) =>
      map((k, v) => MapEntry(k, fromJson(v)));
}

extension ListDynamicParseJson on List<dynamic> {
  List<T> parseJsonList<T>(T Function(Map<String, dynamic> json) fromJson) =>
      cast<Map<String, dynamic>>().map(fromJson).toList();
}

BaseGameLogItem gameLogFromJson(Map<String, dynamic> json, {required GameLogVersion version}) {
  if (json.containsKey("newState")) {
    return StateChangeGameLogItem(
      newState: gameStateFromJson(
        json["newState"] as Map<String, dynamic>,
        version: version,
      ),
    );
  }
  if (json.containsKey("checkedByRole")) {
    return PlayerCheckedGameLogItem(
      day: switch (version) {
        GameLogVersion.v0 => 0,
        GameLogVersion.v2 => json["day"] as int,
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

BaseGameState gameStateFromJson(Map<String, dynamic> json, {required GameLogVersion version}) {
  var stageString = json["stage"] as String;
  if (version == GameLogVersion.v0 && stageString == "dropTableVoting") {
    stageString = GameStage.knockoutVoting.name;
  }
  if (version < GameLogVersion.v2) {
    switch (stageString) {
      case "night0":
        stageString = GameStage.firstNight.name;
      case "night0SheriffCheck":
        stageString = GameStage.firstNightWakeUps.name;
    }
  }
  final stage = GameStage.byName(stageString);
  final day = json["day"] as int;
  final playerStatesKey = switch (version) {
    GameLogVersion.v0 => "players",
    GameLogVersion.v2 => "playerStates",
  };
  final playerStates = (json[playerStatesKey] as List<dynamic>)
      .parseJsonList((e) => playerStateFromJson(e, version: version));
  final playerRoles = <int, PlayerRole>{};
  if (playerStatesKey == "players") {
    playerRoles.addAll(
      (json["players"] as List<dynamic>)
          .parseJsonList((e) => playerFromJson(e, version: version).role)
          .asMap(),
    );
  }
  return switch (stage) {
    GameStage.prepare => GameStatePrepare(playerStates: playerStates),
    GameStage.firstNight ||
    GameStage.preVoting ||
    GameStage.preExcuse ||
    GameStage.preFinalVoting =>
      GameStateWithPlayers(
        stage: stage,
        day: day,
        playerStates: playerStates,
        playerNumbers: (json["playerNumbers"] as List<dynamic>).cast<int>(),
      ),
    GameStage.firstNightWakeUps || GameStage.nightLastWords => GameStateWithPlayer(
        stage: stage,
        day: day,
        playerStates: playerStates,
        currentPlayerNumber: json["currentPlayerNumber"] as int,
      ),
    GameStage.firstNightRest => GameStateNightRest(playerStates: playerStates),
    GameStage.speaking => GameStateSpeaking(
        day: day,
        playerStates: playerStates,
        currentPlayerNumber: json["currentPlayerNumber"] as int,
        accusations: (json["accusations"] as Map<String, dynamic>).parseJsonIntToIntMap(),
        canOnlyAccuse: switch (version) {
          GameLogVersion.v0 => false,
          GameLogVersion.v2 => json["canOnlyAccuse"] as bool,
        },
        hasHalfTime: switch (version) {
          GameLogVersion.v0 => false,
          GameLogVersion.v2 => json["hasHalfTime"] as bool,
        },
      ),
    GameStage.voting || GameStage.finalVoting => GameStateVoting(
        stage: stage,
        day: day,
        playerStates: playerStates,
        votes: (json["votes"] as Map<String, dynamic>).parseJsonIntToIntMap(),
        currentPlayerNumber: json["currentPlayerNumber"] as int,
        currentPlayerVotes: json["currentPlayerVotes"] as int?,
      ),
    GameStage.excuse || GameStage.dayLastWords => GameStateWithIterablePlayers(
        stage: stage,
        day: day,
        playerStates: playerStates,
        playerNumbers: (json["playerNumbers"] as List<dynamic>).cast<int>(),
        currentPlayerIndex: json["currentPlayerIndex"] as int,
      ),
    GameStage.knockoutVoting => GameStateKnockoutVoting(
        day: day,
        playerStates: playerStates,
        playerNumbers: (json["playerNumbers"] as List<dynamic>).cast<int>(),
        votes: switch (version) {
          GameLogVersion.v0 =>
            json[json.containsKey("votes") ? "votes" : "votesForDropTable"] as int,
          GameLogVersion.v2 => json["votes"] as int,
        },
      ),
    GameStage.nightKill => GameStateNightKill(
        day: day,
        playerStates: playerStates,
        thisNightKilledPlayerNumber: json["thisNightKilledPlayerNumber"] as int?,
      ),
    GameStage.nightCheck => GameStateNightCheck(
        day: day,
        playerStates: playerStates,
        activePlayerNumber: json["activePlayerNumber"] as int,
        activePlayerTeam: switch (version) {
          GameLogVersion.v0 => playerRoles[json["activePlayerNumber"] as int]!.team,
          GameLogVersion.v2 => RoleTeam.byName(json["activePlayerTeam"] as String)
        },
      ),
    GameStage.bestTurn => GameStateBestTurn(
        day: day,
        playerStates: playerStates,
        currentPlayerNumber: json["currentPlayerNumber"] as int,
        playerNumbers: (json["playerNumbers"] as List<dynamic>).cast<int>(),
      ),
    GameStage.finish => GameStateFinish(
        day: day,
        playerStates: playerStates,
        winner: json["winner"] != null ? RoleTeam.byName(json["winner"]! as String) : null,
      ),
  };
}

Player playerFromJson(Map<String, dynamic> json, {required GameLogVersion version}) => Player(
      role: PlayerRole.byName(json["role"] as String),
      number: json["number"] as int,
      nickname: json["nickname"] as String?,
    );

PlayerState playerStateFromJson(Map<String, dynamic> json, {required GameLogVersion version}) =>
    PlayerState(
      isAlive: json["isAlive"] as bool,
      warns: json["warns"] as int,
      isKicked: switch (version) {
        GameLogVersion.v0 => json["warns"] as int >= 4,
        GameLogVersion.v2 => json["isKicked"] as bool,
      },
    );

db_models.PlayerWithStats dbPlayerFromJson(
  Map<String, dynamic> json, {
  required DBPlayerVersion version,
}) =>
    switch (version) {
      DBPlayerVersion.v1 || DBPlayerVersion.v2 => db_models.PlayerWithStats(
          db_models.Player(
            nickname: json["nickname"] as String,
            realName: json["realName"] as String? ?? "",
          ),
          json["stats"] != null
              ? dbPlayerStatsFromJson(
                  json["stats"] as Map<String, dynamic>,
                  version: version,
                )
              : const db_models.PlayerStats.defaults(),
        ),
    };

db_models.PlayerStats dbPlayerStatsFromJson(
  Map<String, dynamic> json, {
  required DBPlayerVersion version,
}) =>
    db_models.PlayerStats(
      gamesByRole: {
        for (final entry in (json["gamesByRole"] as Map<String, dynamic>).entries)
          PlayerRole.byName(entry.key): entry.value as int,
      },
      winsByRole: {
        for (final entry in (json["winsByRole"] as Map<String, dynamic>).entries)
          PlayerRole.byName(entry.key): entry.value as int,
      },
      totalWarns: json["totalWarns"] as int,
      totalKicks: json["totalKicks"] as int,
      totalOtherTeamWins: json["totalOtherTeamWins"] as int,
      totalGuessedMafia: json["totalGuessedMafia"] as int,
      totalFoundMafia: json["totalFoundMafia"] as int,
      totalFoundSheriff: json["totalFoundSheriff"] as int,
      totalWasKilledFirstNight: json["totalWasKilledFirstNight"] as int,
    );
