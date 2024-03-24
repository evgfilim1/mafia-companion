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
  @HiveField(0)
  final Map<PlayerRole, int> gamesByRole;

  @HiveField(1)
  final Map<PlayerRole, int> winsByRole;

  @HiveField(2)
  final int totalWarns;

  @HiveField(3)
  final int totalKicks;

  @HiveField(4)
  final int totalGuessedMafia;

  const PlayerStats({
    required this.gamesByRole,
    required this.winsByRole,
    required this.totalWarns,
    required this.totalKicks,
    required this.totalGuessedMafia,
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
          totalGuessedMafia: 0,
        );

  @useResult
  PlayerStats copyWithUpdated({
    required PlayerRole playedAs,
    required bool won,
    required int warnCount,
    required bool wasKicked,
    required int guessedMafiaCount,
  }) {
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
      totalGuessedMafia: totalGuessedMafia + guessedMafiaCount,
    );
  }
}
