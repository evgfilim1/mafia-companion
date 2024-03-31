import "package:hive_flutter/hive_flutter.dart";
import "package:meta/meta.dart";

import "../../game/player.dart";

part "models.g.dart";

@HiveType(typeId: 1)
@immutable
class Player {
  @HiveField(0)
  final String nickname;

  @HiveField(1, defaultValue: "")
  final String realName;

  @HiveField(2, defaultValue: PlayerStats.defaults())
  final PlayerStats stats;

  const Player({
    required this.nickname,
    required this.realName,
    this.stats = const PlayerStats.defaults(),
  });

  @useResult
  Player copyWith({
    String? nickname,
    String? realName,
    PlayerStats? stats,
  }) =>
      Player(
        nickname: nickname ?? this.nickname,
        realName: realName ?? this.realName,
        stats: stats ?? this.stats,
      );
}

@HiveType(typeId: 2)
@immutable
class PlayerStats {
  /// The number of games played by role.
  @HiveField(
    0,
    defaultValue: {
      PlayerRole.citizen: 0,
      PlayerRole.sheriff: 0,
      PlayerRole.mafia: 0,
      PlayerRole.don: 0,
    },
  )
  final Map<PlayerRole, int> gamesByRole;

  /// The number of games won by role.
  @HiveField(
    1,
    defaultValue: {
      PlayerRole.citizen: 0,
      PlayerRole.sheriff: 0,
      PlayerRole.mafia: 0,
      PlayerRole.don: 0,
    },
  )
  final Map<PlayerRole, int> winsByRole;

  /// The total number of warns/fouls received.
  @HiveField(2, defaultValue: 0)
  final int totalWarns;

  /// The total number of times kicked from the game.
  @HiveField(3, defaultValue: 0)
  final int totalKicks;

  /// The total number of times guessed mafia correctly on "best turn".
  @HiveField(4, defaultValue: 0)
  final int totalGuessedMafia;

  /// The total number of times the player playing as a sheriff guessed mafia.
  @HiveField(5, defaultValue: 0)
  final int totalFoundMafia;

  /// The total number of times the player playing as a don guessed sheriff.
  @HiveField(6, defaultValue: 0)
  final int totalFoundSheriff;

  /// The total number of times the player was killed on the first night.
  @HiveField(7, defaultValue: 0)
  final int totalWasKilledFirstNight;

  @HiveField(8, defaultValue: 0)
  final int totalOtherTeamWins;

  const PlayerStats({
    required this.gamesByRole,
    required this.winsByRole,
    required this.totalWarns,
    required this.totalKicks,
    required this.totalOtherTeamWins,
    required this.totalGuessedMafia,
    required this.totalFoundMafia,
    required this.totalFoundSheriff,
    required this.totalWasKilledFirstNight,
  });

  const PlayerStats.defaults()
      : this(
          gamesByRole: const {
            PlayerRole.citizen: 0,
            PlayerRole.sheriff: 0,
            PlayerRole.mafia: 0,
            PlayerRole.don: 0,
          },
          winsByRole: const {
            PlayerRole.citizen: 0,
            PlayerRole.sheriff: 0,
            PlayerRole.mafia: 0,
            PlayerRole.don: 0,
          },
          totalWarns: 0,
          totalKicks: 0,
          totalOtherTeamWins: 0,
          totalGuessedMafia: 0,
          totalFoundMafia: 0,
          totalFoundSheriff: 0,
          totalWasKilledFirstNight: 0,
        );

  @useResult
  PlayerStats copyWithUpdated({
    required PlayerRole playedAs,
    required bool won,
    required int warnCount,
    required bool wasKicked,
    required bool hasOtherTeamWon,
    required int guessedMafiaCount,
    required int foundMafiaCount,
    required bool foundSheriff,
    required bool wasKilledFirstNight,
  }) {
    if (playedAs != PlayerRole.sheriff && foundMafiaCount != 0) {
      throw ArgumentError.value(
        foundMafiaCount,
        "foundMafiaCount",
        "Must be 0 for non-sheriff roles",
      );
    }
    if (playedAs != PlayerRole.don && foundSheriff) {
      throw ArgumentError.value(foundSheriff, "foundSheriff", "Must be false for non-don roles");
    }
    if (!wasKilledFirstNight && guessedMafiaCount != 0) {
      throw ArgumentError.value(
        guessedMafiaCount,
        "guessedMafiaCount",
        "Must be 0 for players who weren't killed first night",
      );
    }
    if (hasOtherTeamWon && won) {
      throw ArgumentError.value(
        hasOtherTeamWon,
        "hasOtherTeamWon",
        "Can't be true if the player's team won",
      );
    }
    final newGamesByRole = Map.of(gamesByRole)..update(playedAs, (value) => value + 1);
    final newWinsByRole = Map.of(winsByRole);
    if (won) {
      newWinsByRole.update(playedAs, (value) => value + 1);
    }
    return PlayerStats(
      gamesByRole: newGamesByRole,
      winsByRole: newWinsByRole,
      totalWarns: totalWarns + warnCount,
      totalKicks: totalKicks + (wasKicked ? 1 : 0),
      totalOtherTeamWins: totalOtherTeamWins + (hasOtherTeamWon ? 1 : 0),
      totalGuessedMafia: totalGuessedMafia + guessedMafiaCount,
      totalFoundMafia: totalFoundMafia + foundMafiaCount,
      totalFoundSheriff: totalFoundSheriff + (foundSheriff ? 1 : 0),
      totalWasKilledFirstNight: totalWasKilledFirstNight + (wasKilledFirstNight ? 1 : 0),
    );
  }
}
