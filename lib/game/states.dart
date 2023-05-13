import 'player.dart';

enum GameState {
  /// Initial state, game is not started yet, giving roles
  prepare,

  /// First night, nobody dies
  night0,

  /// Commissar wakes up and looks on the players, but doesn't check anyone
  night0CommissarCheck,

  /// A new day starts here
  day,

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

  /// Further nights, don and commissar check
  nightCheck,

  /// Last words of player who was killed during night
  nightLastWords,

  /// Final state, game is over
  finish,

  ;
}

class GameStateWithPlayer {
  const GameStateWithPlayer({required this.state, this.player});

  final GameState state;
  final Player? player;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameStateWithPlayer &&
          runtimeType == other.runtimeType &&
          state == other.state &&
          player == other.player;

  @override
  int get hashCode => Object.hash(state, player);
}

const timeLimits = {
  GameState.prepare: null,
  GameState.night0: Duration(minutes: 1),
  GameState.night0CommissarCheck: Duration(seconds: 20),
  GameState.speaking: Duration(minutes: 1),
  GameState.preVoting: null,
  GameState.voting: null,
  GameState.excuse: Duration(seconds: 30),
  GameState.preFinalVoting: null,
  GameState.finalVoting: null,
  GameState.dropTableVoting: null,
  GameState.dayLastWords: Duration(minutes: 1),
  GameState.nightKill: null,
  GameState.nightCheck: Duration(seconds: 10),
  GameState.nightLastWords: Duration(minutes: 1),
  GameState.finish: null,
};

const timeLimitsExtended = {
  GameState.night0: Duration(minutes: 2),
  GameState.speaking: Duration(minutes: 1, seconds: 30),
  GameState.excuse: Duration(minutes: 1),
  GameState.dayLastWords: Duration(minutes: 1, seconds: 30),
  GameState.nightCheck: Duration(seconds: 30),
  GameState.nightLastWords: Duration(minutes: 1, seconds: 30),
};

const validTransitions = {
  // TODO: game draw
  GameState.prepare: [GameState.night0],
  GameState.night0: [GameState.night0CommissarCheck],
  GameState.night0CommissarCheck: [GameState.day],
  GameState.day: [GameState.speaking],
  GameState.speaking: [
    GameState.speaking,
    GameState.preVoting,
    GameState.nightKill,
  ],
  GameState.preVoting: [GameState.voting, GameState.dayLastWords],
  GameState.voting: [GameState.voting, GameState.excuse, GameState.dayLastWords],
  GameState.excuse: [GameState.excuse, GameState.preFinalVoting],
  GameState.preFinalVoting: [GameState.finalVoting],
  GameState.finalVoting: [GameState.finalVoting, GameState.dayLastWords, GameState.dropTableVoting],
  GameState.dropTableVoting: [GameState.dayLastWords, GameState.nightKill],
  GameState.dayLastWords: [GameState.dayLastWords, GameState.nightKill, GameState.finish],
  GameState.nightKill: [GameState.nightCheck],
  GameState.nightCheck: [GameState.nightCheck, GameState.nightLastWords, GameState.day],
  GameState.nightLastWords: [GameState.day, GameState.finish],
  GameState.finish: [],
};
