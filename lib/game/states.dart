import "dart:collection";

import "package:meta/meta.dart";

import "player.dart";

enum GameStage {
  /// Initial stage, game is not started yet
  prepare,

  /// First night, nobody dies
  firstNight,

  /// First night, don and/or sheriff wakes up, no checks
  firstNightWakeUps,

  /// First night rest, nothing happens
  firstNightRest,

  /// Players speak during day and make accusations
  speaking,

  /// Players are announced about vote order before voting
  preVoting,

  /// Players vote for accused players they want to kill
  voting,

  /// Players are announced that voting is tied between several players
  preExcuse,

  /// Accused players can speak more (if the voting is tied)
  excuse,

  /// Players are announced about vote order before final voting
  preFinalVoting,

  /// Final voting for accused players
  finalVoting,

  /// Ask players if they want to kill all accused players
  knockoutVoting,

  /// Last words of players who were killed during day
  dayLastWords,

  /// Further nights, mafia kills
  nightKill,

  /// Further nights, don and sheriff check
  nightCheck,

  /// First night killed player guesses mafia team members
  bestTurn,

  /// Last words of player who was killed during night
  nightLastWords,

  /// Final stage, game is over
  finish,
  ;

  factory GameStage.byName(String name) => GameStage.values.byName(name);
}

/// Base class for all game states.
sealed class BaseGameState {
  final GameStage stage;
  final int day;
  final List<PlayerState> playerStates;

  const BaseGameState({
    required this.stage,
    required this.day,
    required this.playerStates,
  })  : assert(day >= 0, "Invalid day: $day"),
        assert(playerStates.length != 0, "Players list is empty");

  /// Compares two game states. Returns `true` if they differ.
  bool hasStateChanged(BaseGameState oldState) =>
      runtimeType != oldState.runtimeType || stage != oldState.stage || day != oldState.day;
}

/// Represents waiting for players game state.
///
/// [stage] is always [GameStage.prepare] and [day] is always `0`.
@immutable
class GameStatePrepare extends BaseGameState {
  const GameStatePrepare({
    required super.playerStates,
  }) : super(stage: GameStage.prepare, day: 0);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameStatePrepare &&
          runtimeType == other.runtimeType &&
          stage == other.stage &&
          day == other.day &&
          playerStates == other.playerStates;

  @override
  int get hashCode => Object.hash(stage, day, playerStates);

  @useResult
  GameStatePrepare copyWith({
    List<PlayerState>? playerStates,
  }) =>
      GameStatePrepare(
        playerStates: playerStates ?? this.playerStates,
      );
}

///
@immutable
class GameStateNightRest extends BaseGameState {
  const GameStateNightRest({
    required super.playerStates,
  }) : super(stage: GameStage.firstNightRest, day: 1);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameStateNightRest &&
          runtimeType == other.runtimeType &&
          stage == other.stage &&
          day == other.day &&
          playerStates == other.playerStates;

  @override
  int get hashCode => Object.hash(stage, day, playerStates);

  @useResult
  GameStateNightRest copyWith({
    List<PlayerState>? playerStates,
  }) =>
      GameStateNightRest(
        playerStates: playerStates ?? this.playerStates,
      );
}

/// Represents game state with related [currentPlayerNumber].
///
/// [stage] can be [GameStage.firstNightWakeUps] or [GameStage.nightLastWords].
@immutable
class GameStateWithPlayer extends BaseGameState {
  final int currentPlayerNumber;

  const GameStateWithPlayer({
    required super.stage,
    required super.day,
    required super.playerStates,
    required this.currentPlayerNumber,
  }) : assert(
          stage == GameStage.firstNightWakeUps || stage == GameStage.nightLastWords,
          "Invalid stage for GameStateWithPlayer: $stage",
        );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameStateWithPlayer &&
          runtimeType == other.runtimeType &&
          stage == other.stage &&
          day == other.day &&
          playerStates == other.playerStates &&
          currentPlayerNumber == other.currentPlayerNumber;

  @override
  int get hashCode => Object.hash(stage, day, playerStates, currentPlayerNumber);

  @override
  bool hasStateChanged(BaseGameState oldState) =>
      oldState is GameStateWithPlayer && currentPlayerNumber != oldState.currentPlayerNumber ||
      super.hasStateChanged(oldState);

  @useResult
  GameStateWithPlayer copyWith({
    GameStage? stage,
    int? day,
    List<PlayerState>? playerStates,
    int? currentPlayerNumber,
  }) =>
      GameStateWithPlayer(
        stage: stage ?? this.stage,
        day: day ?? this.day,
        playerStates: playerStates ?? this.playerStates,
        currentPlayerNumber: currentPlayerNumber ?? this.currentPlayerNumber,
      );
}

/// Represents state with [currentPlayerNumber] and [accusations].
/// Accusations are a map from accuser number to accused number.
///
/// [stage] is always [GameStage.speaking].
@immutable
class GameStateSpeaking extends BaseGameState {
  final int currentPlayerNumber;
  final LinkedHashMap<int, int> accusations;
  final bool canOnlyAccuse;
  final bool hasHalfTime;

  const GameStateSpeaking({
    required super.day,
    required super.playerStates,
    required this.currentPlayerNumber,
    required this.accusations,
    required this.canOnlyAccuse,
    required this.hasHalfTime,
  }) : super(stage: GameStage.speaking);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameStateSpeaking &&
          runtimeType == other.runtimeType &&
          stage == other.stage &&
          day == other.day &&
          playerStates == other.playerStates &&
          currentPlayerNumber == other.currentPlayerNumber &&
          accusations == other.accusations &&
          canOnlyAccuse == other.canOnlyAccuse;

  @override
  int get hashCode => Object.hash(
        stage,
        day,
        playerStates,
        currentPlayerNumber,
        accusations,
        canOnlyAccuse,
      );

  @override
  bool hasStateChanged(BaseGameState oldState) =>
      oldState is GameStateSpeaking && currentPlayerNumber != oldState.currentPlayerNumber ||
      super.hasStateChanged(oldState);

  @useResult
  GameStateSpeaking copyWith({
    int? day,
    List<PlayerState>? playerStates,
    int? currentPlayerNumber,
    LinkedHashMap<int, int>? accusations,
    bool? canOnlyAccuse,
    bool? hasHalfTime,
  }) =>
      GameStateSpeaking(
        day: day ?? this.day,
        playerStates: playerStates ?? this.playerStates,
        currentPlayerNumber: currentPlayerNumber ?? this.currentPlayerNumber,
        accusations: accusations ?? this.accusations,
        canOnlyAccuse: canOnlyAccuse ?? this.canOnlyAccuse,
        hasHalfTime: hasHalfTime ?? this.hasHalfTime,
      );
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
    required super.playerStates,
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
          playerStates == other.playerStates &&
          votes == other.votes &&
          currentPlayerNumber == other.currentPlayerNumber &&
          currentPlayerVotes == other.currentPlayerVotes;

  @override
  int get hashCode =>
      Object.hash(stage, day, playerStates, votes, currentPlayerNumber, currentPlayerVotes);

  @override
  bool hasStateChanged(BaseGameState oldState) =>
      oldState is GameStateVoting && currentPlayerNumber != oldState.currentPlayerNumber ||
      super.hasStateChanged(oldState);

  @useResult
  GameStateVoting copyWith({
    GameStage? stage,
    int? day,
    List<PlayerState>? playerStates,
    LinkedHashMap<int, int?>? votes,
    int? currentPlayerNumber,
    int? currentPlayerVotes,
  }) =>
      GameStateVoting(
        stage: stage ?? this.stage,
        day: day ?? this.day,
        playerStates: playerStates ?? this.playerStates,
        votes: votes ?? this.votes,
        currentPlayerNumber: currentPlayerNumber ?? this.currentPlayerNumber,
        currentPlayerVotes: currentPlayerVotes ?? this.currentPlayerVotes,
      );
}

/// Represents state with [playerNumbers] and [votes].
///
/// [stage] is always [GameStage.knockoutVoting].
@immutable
class GameStateKnockoutVoting extends BaseGameState {
  final List<int> playerNumbers;
  final int votes;

  const GameStateKnockoutVoting({
    required super.day,
    required super.playerStates,
    required this.playerNumbers,
    required this.votes,
  }) : super(stage: GameStage.knockoutVoting);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameStateKnockoutVoting &&
          runtimeType == other.runtimeType &&
          stage == other.stage &&
          day == other.day &&
          playerStates == other.playerStates &&
          playerNumbers == other.playerNumbers &&
          votes == other.votes;

  @override
  int get hashCode => Object.hash(stage, day, playerStates, playerNumbers, votes);

  @useResult
  GameStateKnockoutVoting copyWith({
    int? day,
    List<PlayerState>? playerStates,
    List<int>? playerNumbers,
    int? votes,
  }) =>
      GameStateKnockoutVoting(
        day: day ?? this.day,
        playerStates: playerStates ?? this.playerStates,
        playerNumbers: playerNumbers ?? this.playerNumbers,
        votes: votes ?? this.votes,
      );
}

/// Represents game state with related [playerNumbers].
///
/// [stage] can be [GameStage.firstNight], [GameStage.preVoting], [GameStage.preExcuse]
/// or [GameStage.preFinalVoting].
@immutable
class GameStateWithPlayers extends BaseGameState {
  final List<int> playerNumbers;

  const GameStateWithPlayers({
    required super.stage,
    required super.day,
    required super.playerStates,
    required this.playerNumbers,
  }) : assert(
          stage == GameStage.firstNight ||
              stage == GameStage.preVoting ||
              stage == GameStage.preExcuse ||
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
          playerStates == other.playerStates &&
          playerNumbers == other.playerNumbers;

  @override
  int get hashCode => Object.hash(stage, day, playerStates, playerNumbers);

  @override
  bool hasStateChanged(BaseGameState oldState) =>
      oldState is GameStateWithPlayers && playerNumbers != oldState.playerNumbers ||
      super.hasStateChanged(oldState);

  @useResult
  GameStateWithPlayers copyWith({
    GameStage? stage,
    int? day,
    List<PlayerState>? playerStates,
    List<int>? playerNumbers,
  }) =>
      GameStateWithPlayers(
        stage: stage ?? this.stage,
        day: day ?? this.day,
        playerStates: playerStates ?? this.playerStates,
        playerNumbers: playerNumbers ?? this.playerNumbers,
      );
}

/// Represents night kill game state.
///
/// [stage] is always [GameStage.nightKill].
@immutable
class GameStateNightKill extends BaseGameState {
  final int? thisNightKilledPlayerNumber;

  const GameStateNightKill({
    required super.day,
    required super.playerStates,
    required this.thisNightKilledPlayerNumber,
  }) : super(stage: GameStage.nightKill);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameStateNightKill &&
          runtimeType == other.runtimeType &&
          stage == other.stage &&
          day == other.day &&
          playerStates == other.playerStates &&
          thisNightKilledPlayerNumber == other.thisNightKilledPlayerNumber;

  @override
  int get hashCode => Object.hash(stage, day, playerStates, thisNightKilledPlayerNumber);

  @useResult
  GameStateNightKill copyWith({
    int? day,
    List<PlayerState>? playerStates,
    int? thisNightKilledPlayerNumber,
  }) =>
      GameStateNightKill(
        day: day ?? this.day,
        playerStates: playerStates ?? this.playerStates,
        thisNightKilledPlayerNumber:
            thisNightKilledPlayerNumber ?? this.thisNightKilledPlayerNumber,
      );
}

/// Represents night check game state.
///
/// [stage] is always [GameStage.nightCheck].
@immutable
class GameStateNightCheck extends BaseGameState {
  final int activePlayerNumber;
  final RoleTeam activePlayerTeam;

  const GameStateNightCheck({
    required super.day,
    required super.playerStates,
    required this.activePlayerNumber,
    required this.activePlayerTeam,
  }) : super(stage: GameStage.nightCheck);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameStateNightCheck &&
          runtimeType == other.runtimeType &&
          stage == other.stage &&
          day == other.day &&
          playerStates == other.playerStates &&
          activePlayerNumber == other.activePlayerNumber &&
          activePlayerTeam == other.activePlayerTeam;

  @override
  int get hashCode => Object.hash(
        stage,
        day,
        playerStates,
        activePlayerNumber,
        activePlayerTeam,
      );

  @override
  bool hasStateChanged(BaseGameState oldState) =>
      oldState is GameStateNightCheck &&
          (activePlayerNumber != oldState.activePlayerNumber ||
              activePlayerTeam != oldState.activePlayerTeam) ||
      super.hasStateChanged(oldState);

  @useResult
  GameStateNightCheck copyWith({
    int? day,
    List<PlayerState>? playerStates,
    int? activePlayerNumber,
    RoleTeam? activePlayerTeam,
  }) =>
      GameStateNightCheck(
        day: day ?? this.day,
        playerStates: playerStates ?? this.playerStates,
        activePlayerNumber: activePlayerNumber ?? this.activePlayerNumber,
        activePlayerTeam: activePlayerTeam ?? this.activePlayerTeam,
      );
}

/// Represents game state with assumed mafia team [playerNumbers] and current [currentPlayerNumber].
/// [currentPlayerNumber] is the player who guesses mafia team.
///
/// [stage] is always [GameStage.bestTurn].
@immutable
class GameStateBestTurn extends BaseGameState {
  final int currentPlayerNumber;
  final List<int> playerNumbers;

  const GameStateBestTurn({
    required super.day,
    required super.playerStates,
    required this.currentPlayerNumber,
    required this.playerNumbers,
  }) : super(stage: GameStage.bestTurn);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameStateBestTurn &&
          runtimeType == other.runtimeType &&
          stage == other.stage &&
          day == other.day &&
          playerStates == other.playerStates &&
          currentPlayerNumber == other.currentPlayerNumber &&
          playerNumbers == other.playerNumbers;

  @override
  int get hashCode => Object.hash(stage, day, playerStates, currentPlayerNumber, playerNumbers);

  @override
  bool hasStateChanged(BaseGameState oldState) =>
      oldState is GameStateBestTurn && currentPlayerNumber != oldState.currentPlayerNumber ||
      super.hasStateChanged(oldState);

  @useResult
  GameStateBestTurn copyWith({
    int? day,
    List<PlayerState>? playerStates,
    int? currentPlayerNumber,
    List<int>? playerNumbers,
  }) =>
      GameStateBestTurn(
        day: day ?? this.day,
        playerStates: playerStates ?? this.playerStates,
        currentPlayerNumber: currentPlayerNumber ?? this.currentPlayerNumber,
        playerNumbers: playerNumbers ?? this.playerNumbers,
      );
}

/// Represents game state with related [playerNumbers] and current [currentPlayerIndex].
///
/// [stage] can be [GameStage.excuse] or [GameStage.dayLastWords].
@immutable
class GameStateWithIterablePlayers extends BaseGameState {
  final List<int> playerNumbers;
  final int currentPlayerIndex;

  const GameStateWithIterablePlayers({
    required super.stage,
    required super.day,
    required super.playerStates,
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
      other is GameStateWithIterablePlayers &&
          runtimeType == other.runtimeType &&
          stage == other.stage &&
          day == other.day &&
          playerStates == other.playerStates &&
          playerNumbers == other.playerNumbers &&
          currentPlayerIndex == other.currentPlayerIndex;

  @override
  int get hashCode => Object.hash(stage, day, playerStates, playerNumbers, currentPlayerIndex);

  @override
  bool hasStateChanged(BaseGameState oldState) =>
      oldState is GameStateWithIterablePlayers &&
          (playerNumbers != oldState.playerNumbers ||
              currentPlayerIndex != oldState.currentPlayerIndex) ||
      super.hasStateChanged(oldState);

  int get currentPlayerNumber => playerNumbers[currentPlayerIndex];

  @useResult
  GameStateWithIterablePlayers copyWith({
    GameStage? stage,
    int? day,
    List<PlayerState>? playerStates,
    List<int>? playerNumbers,
    int? currentPlayerIndex,
  }) =>
      GameStateWithIterablePlayers(
        stage: stage ?? this.stage,
        day: day ?? this.day,
        playerStates: playerStates ?? this.playerStates,
        playerNumbers: playerNumbers ?? this.playerNumbers,
        currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      );
}

/// Represents finished game state. Contains [winner] team, which is one of [PlayerRole.mafia],
/// [PlayerRole.citizen] or `null` if the game is tied.
///
/// [stage] is always [GameStage.finish].
@immutable
class GameStateFinish extends BaseGameState {
  final RoleTeam? winner;

  const GameStateFinish({
    required super.day,
    required super.playerStates,
    required this.winner,
  }) : super(stage: GameStage.finish);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameStateFinish &&
          runtimeType == other.runtimeType &&
          stage == other.stage &&
          day == other.day &&
          playerStates == other.playerStates &&
          winner == other.winner;

  @override
  int get hashCode => Object.hash(stage, day, playerStates, winner);

  @override
  bool hasStateChanged(BaseGameState oldState) =>
      oldState is GameStateFinish && winner != oldState.winner || super.hasStateChanged(oldState);

  @useResult
  GameStateFinish copyWith({
    int? day,
    List<PlayerState>? playerStates,
    RoleTeam? winner,
  }) =>
      GameStateFinish(
        day: day ?? this.day,
        playerStates: playerStates ?? this.playerStates,
        winner: winner ?? this.winner,
      );
}

const timeLimits = <GameStage, Duration>{
  // GameStage.prepare: null,
  GameStage.firstNight: Duration(minutes: 1),
  GameStage.firstNightWakeUps: Duration(seconds: 20),
  GameStage.firstNightRest: Duration(seconds: 30),
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
  GameStage.bestTurn: Duration(seconds: 20),
  GameStage.nightLastWords: Duration(minutes: 1),
  // GameStage.finish: null,
};

const timeLimitsExtended = <GameStage, Duration>{
  GameStage.firstNight: Duration(minutes: 2),
  GameStage.speaking: Duration(minutes: 1, seconds: 30),
  GameStage.excuse: Duration(minutes: 1),
  GameStage.dayLastWords: Duration(minutes: 1, seconds: 30),
  GameStage.nightCheck: Duration(seconds: 30),
  GameStage.bestTurn: Duration(seconds: 40),
  GameStage.nightLastWords: Duration(minutes: 1, seconds: 30),
};

const timeLimitsShortened = <GameStage, Duration>{
  GameStage.firstNight: Duration(seconds: 30),
  GameStage.firstNightWakeUps: Duration(seconds: 10),
  GameStage.firstNightRest: Duration(seconds: 15),
  GameStage.speaking: Duration(seconds: 30),
  GameStage.excuse: Duration(seconds: 15),
  GameStage.dayLastWords: Duration(seconds: 30),
  GameStage.nightCheck: Duration(seconds: 6),
  GameStage.bestTurn: Duration(seconds: 10),
  GameStage.nightLastWords: Duration(seconds: 30),
};

const validTransitions = <GameStage, Set<GameStage>>{
  GameStage.prepare: {GameStage.firstNight},
  GameStage.firstNight: {GameStage.firstNightWakeUps, GameStage.finish},
  GameStage.firstNightWakeUps: {GameStage.speaking, GameStage.firstNightRest, GameStage.finish},
  GameStage.firstNightRest: {GameStage.speaking, GameStage.finish},
  GameStage.speaking: {
    GameStage.speaking,
    GameStage.preVoting,
    GameStage.nightKill,
    GameStage.finish,
  },
  GameStage.preVoting: {
    GameStage.voting,
    GameStage.dayLastWords,
    GameStage.nightKill,
    GameStage.finish,
  },
  GameStage.voting: {
    GameStage.voting,
    GameStage.preExcuse,
    GameStage.dayLastWords,
    GameStage.nightKill,
    GameStage.finish,
  },
  GameStage.preExcuse: {GameStage.nightKill, GameStage.excuse, GameStage.finish},
  GameStage.excuse: {GameStage.excuse, GameStage.preFinalVoting, GameStage.finish},
  GameStage.preFinalVoting: {GameStage.finalVoting, GameStage.finish},
  GameStage.finalVoting: {
    GameStage.finalVoting,
    GameStage.preExcuse,
    GameStage.dayLastWords,
    GameStage.knockoutVoting,
    GameStage.nightKill,
    GameStage.finish,
  },
  GameStage.knockoutVoting: {GameStage.dayLastWords, GameStage.nightKill, GameStage.finish},
  GameStage.dayLastWords: {GameStage.dayLastWords, GameStage.nightKill, GameStage.finish},
  GameStage.nightKill: {GameStage.nightCheck, GameStage.finish},
  GameStage.nightCheck: {
    GameStage.nightCheck,
    GameStage.bestTurn,
    GameStage.nightLastWords,
    GameStage.speaking,
    GameStage.finish,
  },
  GameStage.bestTurn: {GameStage.nightLastWords, GameStage.finish},
  GameStage.nightLastWords: {GameStage.speaking, GameStage.finish},
  GameStage.finish: {},
};
