import 'player.dart';

enum GameState {
  /// Initial state, game is not started yet, giving roles
  prepare,

  /// First night, nobody dies
  night0,

  /// Don and commissar wakes up, but doesn't check anyone
  nightVibeCheck,

  /// A new day starts here
  day,

  /// Players speak during day and make accusations
  speaking, // next may be: speaking, voting, nightKill

  /// Players vote for accused players they want to kill
  voting, // next may be: voting, excuse, dayLastWords

  /// Accused players can speak more (if the voting is tied)
  excuse, // next may be: excuse, finalVoting

  /// Final voting for accused players
  finalVoting, // next may be: finalVoting, dayLastWords, dropTableVoting

  /// Ask players if they want to kill all accused players
  dropTableVoting, // next may be: dayLastWords, nightKill

  /// Last words of players who were killed during day
  dayLastWords, // next may be: dayLastWords, nightKill, finish

  /// Further nights, mafia kills
  nightKill, // next may be: nightCheck, nightLastWords, speaking

  /// Further nights, don and commissar check
  nightCheck, // next may be: nightLastWords, speaking

  /// Last words of player who was killed during night
  nightLastWords, // next may be: speaking, finish

  /// Final state, game is over
  finish,
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
  GameState.night0: Duration(minutes: 2),
  GameState.nightVibeCheck: Duration(seconds: 10),
  GameState.speaking: Duration(minutes: 1, seconds: 10),
  GameState.voting: null,
  GameState.excuse: Duration(seconds: 35),
  GameState.finalVoting: null,
  GameState.dropTableVoting: null,
  GameState.dayLastWords: Duration(seconds: 35),
  GameState.nightKill: null,
  GameState.nightCheck: Duration(seconds: 15),
  GameState.nightLastWords: Duration(seconds: 35),
  GameState.finish: null,
};

const validTransitions = {
  // TODO: game draw
  GameState.prepare: [GameState.night0],
  GameState.night0: [GameState.nightVibeCheck],
  GameState.nightVibeCheck: [GameState.nightVibeCheck, GameState.day],
  GameState.day: [GameState.speaking],
  GameState.speaking: [GameState.speaking, GameState.voting, GameState.nightKill],
  GameState.voting: [GameState.voting, GameState.excuse, GameState.dayLastWords],
  GameState.excuse: [GameState.excuse, GameState.finalVoting],
  GameState.finalVoting: [GameState.finalVoting, GameState.dayLastWords, GameState.dropTableVoting],
  GameState.dropTableVoting: [GameState.dayLastWords, GameState.nightKill],
  GameState.dayLastWords: [GameState.dayLastWords, GameState.nightKill, GameState.finish],
  GameState.nightKill: [GameState.nightCheck, GameState.nightLastWords, GameState.day],
  GameState.nightCheck: [GameState.nightCheck, GameState.nightLastWords, GameState.day],
  GameState.nightLastWords: [GameState.day, GameState.finish],
  GameState.finish: [],
};
