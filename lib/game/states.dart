import 'dart:collection';

import 'player.dart';

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
class GameState extends BaseGameState {
  const GameState({
    required super.stage,
    required super.day,
  })  : assert(stage == GameStage.prepare),
        assert(day >= 0);

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

/// Represents game state with related player.
///
/// [stage] can be [GameStage.night0SheriffCheck] or [GameStage.nightLastWords].
class GameStateWithPlayer extends BaseGameState {
  final Player player;

  const GameStateWithPlayer({
    required super.stage,
    required super.day,
    required this.player,
  }) : assert(stage == GameStage.night0SheriffCheck || stage == GameStage.nightLastWords);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameStateWithPlayer &&
          runtimeType == other.runtimeType &&
          stage == other.stage &&
          day == other.day &&
          player == other.player;

  @override
  int get hashCode => Object.hash(stage, day, player);
}

/// Represents state with current [player] and [accusations]. Accusations are a map from accuser
/// to accused player.
///
/// [stage] is always [GameStage.speaking].
class GameStateSpeaking extends BaseGameState {
  final Player player;
  final LinkedHashMap<Player, Player> accusations;

  const GameStateSpeaking({
    required super.day,
    required this.player,
    required this.accusations,
  }) : super(stage: GameStage.speaking);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameStateSpeaking &&
          runtimeType == other.runtimeType &&
          stage == other.stage &&
          day == other.day &&
          player == other.player &&
          accusations == other.accusations;

  @override
  int get hashCode => Object.hash(stage, day, player, accusations);
}

/// Represents state with current [player] and [votes]. Votes is a count of votes for each player.
///
/// [stage] can be [GameStage.voting] or [GameStage.finalVoting].
class GameStateVoting extends BaseGameState {
  final Player player;
  final LinkedHashMap<Player, int?> votes;
  final int? currentPlayerVotes;

  const GameStateVoting({
    required super.stage,
    required super.day,
    required this.player,
    required this.votes,
    required this.currentPlayerVotes,
  }) : assert(stage == GameStage.voting || stage == GameStage.finalVoting);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameStateVoting &&
          runtimeType == other.runtimeType &&
          stage == other.stage &&
          day == other.day &&
          player == other.player &&
          votes == other.votes;

  @override
  int get hashCode => Object.hash(stage, day, player, votes);
}

/// Represents game state with related [players].
///
/// [stage] can be [GameStage.night0], [GameStage.preVoting], [GameStage.preFinalVoting] or
/// [GameStage.dropTableVoting].
class GameStateWithPlayers extends BaseGameState {
  final List<Player> players;

  const GameStateWithPlayers({
    required super.stage,
    required super.day,
    required this.players,
  }) : assert(stage == GameStage.night0 ||
            stage == GameStage.preVoting ||
            stage == GameStage.preFinalVoting ||
            stage == GameStage.dropTableVoting);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameStateWithPlayers &&
          runtimeType == other.runtimeType &&
          stage == other.stage &&
          day == other.day &&
          players == other.players;

  @override
  int get hashCode => Object.hash(stage, day, players);
}

/// Represents night kill game state.
///
/// [stage] is always [GameStage.nightKill].
class GameStateNightKill extends BaseGameState {
  final List<Player> mafiaTeam;
  final Player? thisNightKilledPlayer;

  const GameStateNightKill({
    required super.day,
    required this.mafiaTeam,
    required this.thisNightKilledPlayer,
  }) : super(stage: GameStage.nightKill);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameStateNightKill &&
          runtimeType == other.runtimeType &&
          stage == other.stage &&
          day == other.day &&
          mafiaTeam == other.mafiaTeam &&
          thisNightKilledPlayer == other.thisNightKilledPlayer;

  @override
  int get hashCode => Object.hash(stage, day, mafiaTeam, thisNightKilledPlayer);
}

/// Represents night check game state.
///
/// [stage] is always [GameStage.nightCheck].
class GameStateNightCheck extends BaseGameState {
  final Player player;
  final Player? thisNightKilledPlayer;

  const GameStateNightCheck({
    required super.day,
    required this.player,
    required this.thisNightKilledPlayer,
  }) : super(stage: GameStage.nightCheck);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameStateNightCheck &&
          runtimeType == other.runtimeType &&
          stage == other.stage &&
          day == other.day &&
          player == other.player &&
          thisNightKilledPlayer == other.thisNightKilledPlayer;

  @override
  int get hashCode => Object.hash(stage, day, player, thisNightKilledPlayer);
}

/// Represents game state with related [players] and current [playerIndex].
///
/// [stage] can be [GameStage.excuse] or [GameStage.dayLastWords].
class GameStateWithCurrentPlayer extends BaseGameState {
  final List<Player> players;
  final int playerIndex;

  const GameStateWithCurrentPlayer({
    required super.stage,
    required super.day,
    required this.players,
    required this.playerIndex,
  })  : assert(stage == GameStage.excuse || stage == GameStage.dayLastWords),
        assert(0 <= playerIndex && playerIndex < players.length);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameStateWithCurrentPlayer &&
          runtimeType == other.runtimeType &&
          stage == other.stage &&
          day == other.day &&
          players == other.players &&
          playerIndex == other.playerIndex;

  @override
  int get hashCode => Object.hash(stage, day, players, playerIndex);

  Player get player => players[playerIndex];
}

/// Represents finished game state. Contains [winner] team, which is one of [PlayerRole.mafia],
/// [PlayerRole.citizen] or `null` if the game is tied.
///
/// [stage] is always [GameStage.finish].
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
  GameStage.finalVoting: [GameStage.finalVoting, GameStage.dayLastWords, GameStage.dropTableVoting],
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
  GameStage.finish: [],
};
