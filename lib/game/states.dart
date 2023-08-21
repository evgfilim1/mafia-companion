import "dart:collection";

import "package:flutter/foundation.dart";

import "player.dart";

enum GameStage {
  /// Initial stage, game is not started yet, giving roles
  prepare,

  /// First night, nobody dies
  night0,

  /// Sheriff wakes up and looks on the players, but doesn't check anyone
  night0SheriffCheck,

  /// Players speak during day and make accusations
  speaking,

  /// Players are announced about vote order before voting
  preVoting,

  /// Players vote for accused players they want to kill
  voting,

  /// Accused players can speak more (if the voting is tied)
  excuse,

  /// Players are announced about vote order before final voting
  preFinalVoting,

  /// Final voting for accused players
  finalVoting,

  /// Ask players if they want to kill all accused players
  dropTableVoting,

  /// Last words of players who were killed during day
  dayLastWords,

  /// Further nights, mafia kills
  nightKill,

  /// Further nights, don and sheriff check
  nightCheck,

  /// Last words of player who was killed during night
  nightLastWords,

  /// Final stage, game is over
  finish,
  ;
}

/// Base class for all game states. Contains only [stage] field.
sealed class BaseGameState {
  final GameStage stage;
  final int day;

  const BaseGameState({
    required this.stage,
    required this.day,
  });
}

/// Represents sole game state without any additional data.
///
/// [stage] is always [GameStage.prepare].
@immutable
class GameState extends BaseGameState {
  const GameState({
    required super.stage,
    required super.day,
  })  : assert(stage == GameStage.prepare, "Invalid stage for GameState: $stage"),
        assert(day >= 0, "Invalid day for GameState: $day");

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameState &&
          runtimeType == other.runtimeType &&
          stage == other.stage &&
          day == other.day;

  @override
  int get hashCode => Object.hash(stage, day);
}

/// Represents game state with related [currentPlayerNumber].
///
/// [stage] can be [GameStage.night0SheriffCheck] or [GameStage.nightLastWords].
@immutable
class GameStateWithPlayer extends BaseGameState {
  final int currentPlayerNumber;

  const GameStateWithPlayer({
    required super.stage,
    required super.day,
    required this.currentPlayerNumber,
  }) : assert(
          stage == GameStage.night0SheriffCheck || stage == GameStage.nightLastWords,
          "Invalid stage for GameStateWithPlayer: $stage",
        );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameStateWithPlayer &&
          runtimeType == other.runtimeType &&
          stage == other.stage &&
          day == other.day &&
          currentPlayerNumber == other.currentPlayerNumber;

  @override
  int get hashCode => Object.hash(stage, day, currentPlayerNumber);
}

/// Represents state with [currentPlayerNumber] and [accusations].
/// Accusations are a map from accuser number to accused number.
///
/// [stage] is always [GameStage.speaking].
@immutable
class GameStateSpeaking extends BaseGameState {
  final int currentPlayerNumber;
  final LinkedHashMap<int, int> accusations;

  const GameStateSpeaking({
    required super.day,
    required this.currentPlayerNumber,
    required this.accusations,
  }) : super(stage: GameStage.speaking);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameStateSpeaking &&
          runtimeType == other.runtimeType &&
          stage == other.stage &&
          day == other.day &&
          currentPlayerNumber == other.currentPlayerNumber &&
          accusations == other.accusations;

  @override
  int get hashCode => Object.hash(stage, day, currentPlayerNumber, accusations);
}

/// Represents state with [currentPlayerNumber], [currentPlayerVotes] and total [votes].
/// [votes] is a count of votes for each player, or `null` if player wasn't voted against yet.
///
/// [stage] can be [GameStage.voting] or [GameStage.finalVoting].
@immutable
class GameStateVoting extends BaseGameState {
  final LinkedHashMap<int, int?> votes;
  final int currentPlayerNumber;
  final int? currentPlayerVotes;

  const GameStateVoting({
    required super.stage,
    required super.day,
    required this.votes,
    required this.currentPlayerNumber,
    required this.currentPlayerVotes,
  }) : assert(
          stage == GameStage.voting || stage == GameStage.finalVoting,
          "Invalid stage for GameStateVoting: $stage",
        );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameStateVoting &&
          runtimeType == other.runtimeType &&
          stage == other.stage &&
          day == other.day &&
          votes == other.votes &&
          currentPlayerNumber == other.currentPlayerNumber &&
          currentPlayerVotes == other.currentPlayerVotes;

  @override
  int get hashCode => Object.hash(stage, day, votes, currentPlayerNumber, currentPlayerVotes);
}

/// Represents state with [playerNumbers] and [votesForDropTable].
///
/// [stage] is always [GameStage.dropTableVoting].
@immutable
class GameStateDropTableVoting extends BaseGameState {
  final List<int> playerNumbers;
  final int votesForDropTable;

  const GameStateDropTableVoting({
    required super.day,
    required this.playerNumbers,
    required this.votesForDropTable,
  }) : super(stage: GameStage.dropTableVoting);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameStateDropTableVoting &&
          runtimeType == other.runtimeType &&
          stage == other.stage &&
          day == other.day &&
          playerNumbers == other.playerNumbers &&
          votesForDropTable == other.votesForDropTable;

  @override
  int get hashCode => Object.hash(stage, day, playerNumbers, votesForDropTable);
}

/// Represents game state with related [playerNumbers].
///
/// [stage] can be [GameStage.night0], [GameStage.preVoting] or [GameStage.preFinalVoting].
@immutable
class GameStateWithPlayers extends BaseGameState {
  final List<int> playerNumbers;

  const GameStateWithPlayers({
    required super.stage,
    required super.day,
    required this.playerNumbers,
  }) : assert(
          stage == GameStage.night0 ||
              stage == GameStage.preVoting ||
              stage == GameStage.preFinalVoting,
          "Invalid stage for GameStateWithPlayers: $stage",
        );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameStateWithPlayers &&
          runtimeType == other.runtimeType &&
          stage == other.stage &&
          day == other.day &&
          playerNumbers == other.playerNumbers;

  @override
  int get hashCode => Object.hash(stage, day, playerNumbers);
}

/// Represents night kill game state.
///
/// [stage] is always [GameStage.nightKill].
@immutable
class GameStateNightKill extends BaseGameState {
  final List<int> mafiaTeam;
  final int? thisNightKilledPlayerNumber;

  const GameStateNightKill({
    required super.day,
    required this.mafiaTeam,
    required this.thisNightKilledPlayerNumber,
  }) : super(stage: GameStage.nightKill);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameStateNightKill &&
          runtimeType == other.runtimeType &&
          stage == other.stage &&
          day == other.day &&
          mafiaTeam == other.mafiaTeam &&
          thisNightKilledPlayerNumber == other.thisNightKilledPlayerNumber;

  @override
  int get hashCode => Object.hash(stage, day, mafiaTeam, thisNightKilledPlayerNumber);
}

/// Represents night check game state.
///
/// [stage] is always [GameStage.nightCheck].
@immutable
class GameStateNightCheck extends BaseGameState {
  final int activePlayerNumber;
  final PlayerRole activePlayerRole;
  final int? thisNightKilledPlayerNumber;

  const GameStateNightCheck({
    required super.day,
    required this.activePlayerNumber,
    required this.activePlayerRole,
    required this.thisNightKilledPlayerNumber,
  }) : super(stage: GameStage.nightCheck);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameStateNightCheck &&
          runtimeType == other.runtimeType &&
          stage == other.stage &&
          day == other.day &&
          activePlayerNumber == other.activePlayerNumber &&
          activePlayerRole == other.activePlayerRole &&
          thisNightKilledPlayerNumber == other.thisNightKilledPlayerNumber;

  @override
  int get hashCode =>
      Object.hash(stage, day, activePlayerNumber, activePlayerRole, thisNightKilledPlayerNumber);
}

/// Represents game state with related [playerNumbers] and current [currentPlayerIndex].
///
/// [stage] can be [GameStage.excuse] or [GameStage.dayLastWords].
@immutable
class GameStateWithCurrentPlayer extends BaseGameState {
  final List<int> playerNumbers;
  final int currentPlayerIndex;

  const GameStateWithCurrentPlayer({
    required super.stage,
    required super.day,
    required this.playerNumbers,
    required this.currentPlayerIndex,
  })  : assert(
          stage == GameStage.excuse || stage == GameStage.dayLastWords,
          "Invalid stage for GameStateWithCurrentPlayer: $stage",
        ),
        assert(
          0 <= currentPlayerIndex && currentPlayerIndex < playerNumbers.length,
          "Invalid playerIndex for GameStateWithCurrentPlayer: $currentPlayerIndex",
        );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameStateWithCurrentPlayer &&
          runtimeType == other.runtimeType &&
          stage == other.stage &&
          day == other.day &&
          playerNumbers == other.playerNumbers &&
          currentPlayerIndex == other.currentPlayerIndex;

  @override
  int get hashCode => Object.hash(stage, day, playerNumbers, currentPlayerIndex);

  int get currentPlayerNumber => playerNumbers[currentPlayerIndex];
}

/// Represents finished game state. Contains [winner] team, which is one of [PlayerRole.mafia],
/// [PlayerRole.citizen] or `null` if the game is tied.
///
/// [stage] is always [GameStage.finish].
@immutable
class GameStateFinish extends BaseGameState {
  final PlayerRole? winner;

  const GameStateFinish({
    required super.day,
    required this.winner,
  }) : super(stage: GameStage.finish);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameStateFinish &&
          runtimeType == other.runtimeType &&
          stage == other.stage &&
          day == other.day &&
          winner == other.winner;

  @override
  int get hashCode => Object.hash(stage, day, winner);
}

const timeLimits = {
  // GameStage.prepare: null,
  GameStage.night0: Duration(minutes: 1),
  GameStage.night0SheriffCheck: Duration(seconds: 20),
  GameStage.speaking: Duration(minutes: 1),
  // GameStage.preVoting: null,
  // GameStage.voting: null,
  GameStage.excuse: Duration(seconds: 30),
  // GameStage.preFinalVoting: null,
  // GameStage.finalVoting: null,
  // GameStage.dropTableVoting: null,
  GameStage.dayLastWords: Duration(minutes: 1),
  // GameStage.nightKill: null,
  GameStage.nightCheck: Duration(seconds: 10),
  GameStage.nightLastWords: Duration(minutes: 1),
  // GameStage.finish: null,
};

const timeLimitsExtended = {
  GameStage.night0: Duration(minutes: 2),
  GameStage.speaking: Duration(minutes: 1, seconds: 30),
  GameStage.excuse: Duration(minutes: 1),
  GameStage.dayLastWords: Duration(minutes: 1, seconds: 30),
  GameStage.nightCheck: Duration(seconds: 30),
  GameStage.nightLastWords: Duration(minutes: 1, seconds: 30),
};

const validTransitions = {
  GameStage.prepare: [GameStage.night0],
  GameStage.night0: [GameStage.night0SheriffCheck],
  GameStage.night0SheriffCheck: [GameStage.speaking],
  GameStage.speaking: [GameStage.speaking, GameStage.preVoting, GameStage.nightKill],
  GameStage.preVoting: [GameStage.voting, GameStage.dayLastWords],
  GameStage.voting: [GameStage.voting, GameStage.excuse, GameStage.dayLastWords],
  GameStage.excuse: [GameStage.excuse, GameStage.preFinalVoting],
  GameStage.preFinalVoting: [GameStage.finalVoting],
  GameStage.finalVoting: [
    GameStage.finalVoting,
    GameStage.dayLastWords,
    GameStage.dropTableVoting,
    GameStage.nightKill,
  ],
  GameStage.dropTableVoting: [GameStage.dayLastWords, GameStage.nightKill],
  GameStage.dayLastWords: [GameStage.dayLastWords, GameStage.nightKill, GameStage.finish],
  GameStage.nightKill: [GameStage.nightCheck],
  GameStage.nightCheck: [
    GameStage.nightCheck,
    GameStage.nightLastWords,
    GameStage.speaking,
    GameStage.finish,
  ],
  GameStage.nightLastWords: [GameStage.speaking, GameStage.finish],
  GameStage.finish: <GameStage>[],
};
