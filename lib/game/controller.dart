import 'dart:collection';

import '../utils.dart';
import 'player.dart';
import 'states.dart';

class PlayersView with IterableMixin<Player> {
  final List<Player> _players;
  final Map<int, int> _warns = {};

  PlayersView(List<Player> players)
      : assert(
          players.asMap().entries.every((element) => element.value.number == element.key + 1),
          "Players must be sorted by numbers sequentially 1..10",
        ),
        _players = players;

  Player operator [](int index) => _players[index];

  @override
  Iterator<Player> get iterator => _players.iterator;

  @override
  int get length => _players.length;

  Player getByNumber(int number) => _players[number - 1];

  int get count => length;

  int get aliveCount => _players.where((player) => player.isAlive).length;

  int get aliveMafiaCount =>
      _players.where((player) => player.role.isMafia && player.isAlive).length;

  Player get don => _players.firstWhere((player) => player.role == PlayerRole.don);

  Player get commissar => _players.firstWhere((player) => player.role == PlayerRole.commissar);

  List<Player> get citizen =>
      _players.where((player) => player.role == PlayerRole.citizen).toUnmodifiableList();

  List<Player> get mafia =>
      _players.where((player) => player.role == PlayerRole.mafia).toUnmodifiableList();

  List<Player> get mafiaTeam =>
      _players.where((player) => player.role.isMafia).toUnmodifiableList();

  List<Player> get citizenTeam =>
      _players.where((player) => player.role.isCitizen).toUnmodifiableList();

  void warn(int number) => _warns.update(number, (value) => value + 1, ifAbsent: () => 1);

  int getWarnCount(int number) => _warns[number - 1] ?? 0;

  void unwarn(int number) {
    if (_warns.containsKey(number)) {
      _warns.update(number, (value) => value - 1);
    }
  }

  void kill(int number) => _players[number - 1] = _players[number - 1].copyWith(isAlive: false);

  void revive(int number) => _players[number - 1] = _players[number - 1].copyWith(isAlive: true);
}

/// Game controller. Manages game state and players. Doesn't know about UI.
/// To start new game, create new instance of [Game].
class Game {
  BaseGameState _state = const GameState(stage: GameStage.prepare, day: 0);
  final _history = <BaseGameState>[];

  final PlayersView players;

  /// Creates new game with players generated by [generatePlayers] with default config.
  Game() : this.withPlayers(generatePlayers());

  /// Creates new game with given players.
  Game.withPlayers(List<Player> players)
      : players = PlayersView(players
          ..sort((a, b) => a.number.compareTo(b.number))
          ..toUnmodifiableList());

  /// Returns current game state.
  BaseGameState get state => _state;

  /// Assumes team that will win if game ends right now. Returns [PlayerRole.mafia],
  /// [PlayerRole.citizen] or `null` if the game can't end right now.
  PlayerRole? get winTeamAssumption {
    var aliveMafia = players.aliveMafiaCount;
    var aliveCitizens = players.aliveCount - aliveMafia;
    if (_state
        case GameStateWithPlayer(stage: GameStage.nightLastWords, player: final player) ||
            GameStateWithCurrentPlayer(stage: GameStage.dayLastWords, player: final player)) {
      if (player.role.isMafia) {
        aliveMafia--;
      } else {
        aliveCitizens--;
      }
    }
    if (aliveMafia == 0) {
      return PlayerRole.citizen;
    }
    if (aliveCitizens <= aliveMafia) {
      return PlayerRole.mafia;
    }
    return null;
  }

  /// Checks if game is over.
  bool get isGameOver => _state.stage == GameStage.finish || winTeamAssumption != null;

  int get totalVotes {
    if (_state is! GameStateVoting) {
      throw StateError("Can't get total votes in state ${_state.runtimeType}");
    }
    final state = _state as GameStateVoting;
    return state.votes.values.fold(0, (sum, votes) => votes == null ? sum : sum + votes);
  }

  /// Assumes next game state according to game internal state, and returns it.
  /// Doesn't change internal state. May throw exceptions if game internal state is inconsistent.
  BaseGameState? get nextStateAssumption {
    switch (_state.stage) {
      // TODO: Dart 3 pattern matching
      case GameStage.prepare:
        return GameStateWithPlayers(stage: GameStage.night0, day: 0, players: players.mafiaTeam);
      case GameStage.night0:
        return GameStateWithPlayer(
          stage: GameStage.night0CommissarCheck,
          day: 0,
          player: players.commissar,
        );
      case GameStage.night0CommissarCheck:
        return GameStateSpeaking(
          player: players[0],
          day: state.day + 1,
          accusations: LinkedHashMap(),
        );
      case GameStage.speaking:
        final state = _state as GameStateSpeaking;
        final next = _nextAlivePlayer(fromNumber: state.player.number);
        if (next.number == _firstSpeakingPlayerNumber) {
          if (state.accusations.isEmpty || state.day == 1 && state.accusations.length == 1) {
            return GameStateNightKill(
              day: state.day,
              mafiaTeam: players.mafiaTeam,
              thisNightKilledPlayer: null,
            );
          }
          return GameStateWithPlayers(
            stage: GameStage.preVoting,
            day: state.day,
            players: state.accusations.values.toUnmodifiableList(),
          );
        }
        return GameStateSpeaking(
          player: next,
          day: state.day,
          accusations: LinkedHashMap.of(state.accusations),
        );
      case GameStage.preVoting:
        final state = _state as GameStateWithPlayers;
        final firstPlayer = state.players.first;
        if (state.players.length == 1) {
          return GameStateWithCurrentPlayer(
            stage: GameStage.dayLastWords,
            day: state.day,
            players: [firstPlayer],
            playerIndex: 0,
          );
        }
        return GameStateVoting(
          stage: GameStage.voting,
          day: state.day,
          player: firstPlayer,
          votes: LinkedHashMap.fromEntries(state.players.map((player) => MapEntry(player, null))),
          currentPlayerVotes: null,
        );
      case GameStage.voting:
        return _handleVoting();
      case GameStage.excuse:
        final state = _state as GameStateWithCurrentPlayer;
        if (state.playerIndex == state.players.length - 1) {
          return GameStateWithPlayers(
            stage: GameStage.preFinalVoting,
            day: state.day,
            players: state.players,
          );
        }
        return GameStateWithCurrentPlayer(
          stage: GameStage.excuse,
          day: state.day,
          players: state.players,
          playerIndex: state.playerIndex + 1,
        );
      case GameStage.preFinalVoting:
        final state = _state as GameStateWithPlayers;
        return GameStateVoting(
          stage: GameStage.finalVoting,
          day: state.day,
          player: state.players.first,
          votes: LinkedHashMap.fromEntries(state.players.map((player) => MapEntry(player, null))),
          currentPlayerVotes: null,
        );
      case GameStage.finalVoting:
        return _handleVoting();
      case GameStage.dropTableVoting:
        final state = _state as GameStateWithPlayers;
        if (state.players.isEmpty) {
          return GameStateNightKill(
            day: state.day,
            mafiaTeam: players.mafiaTeam,
            thisNightKilledPlayer: null,
          );
        }
        return GameStateWithCurrentPlayer(
          stage: GameStage.dayLastWords,
          day: state.day,
          players: state.players,
          playerIndex: 0,
        );
      case GameStage.dayLastWords:
        final state = _state as GameStateWithCurrentPlayer;
        if (state.playerIndex == state.players.length - 1) {
          if (isGameOver) {
            return GameStateFinish(day: state.day, winner: winTeamAssumption);
          }
          return GameStateNightKill(
            day: state.day,
            mafiaTeam: players.mafiaTeam,
            thisNightKilledPlayer: null,
          );
        }
        return GameStateWithCurrentPlayer(
          stage: GameStage.dayLastWords,
          day: state.day,
          players: state.players,
          playerIndex: state.playerIndex + 1,
        );
      case GameStage.nightKill:
        final state = _state as GameStateNightKill;
        return GameStateNightCheck(
          day: state.day,
          player: players.don,
          thisNightKilledPlayer: state.thisNightKilledPlayer,
        );
      case GameStage.nightCheck:
        final state = _state as GameStateNightCheck;
        if (state.player.role == PlayerRole.don) {
          return GameStateNightCheck(
            day: state.day,
            player: players.commissar,
            thisNightKilledPlayer: state.thisNightKilledPlayer,
          );
        }
        return _handleEndOfNight();
      case GameStage.nightLastWords:
        if (isGameOver) {
          return GameStateFinish(day: state.day, winner: winTeamAssumption);
        }
        return GameStateSpeaking(
          player: players.getByNumber(_firstSpeakingPlayerNumber),
          day: state.day + 1,
          accusations: LinkedHashMap(),
        );
      case GameStage.finish:
        return null;
    }
  }

  /// Changes game state to next state assumed by [nextStateAssumption].
  /// Modifies internal game state.
  void setNextState() {
    final nextState = nextStateAssumption;
    if (nextState == null) {
      throw StateError("Game is over");
    }
    assert(
      validTransitions[_state.stage]?.contains(nextState.stage) == true,
      "Invalid or unspecified transition from ${_state.stage} to ${nextState.stage}",
    );
    final oldState = _state;
    _history.add(_state);
    // if (oldState.stage.isAnyOf([GameStage.dayLastWords, GameStage.nightLastWords])) {
    if (oldState
        case GameStateWithCurrentPlayer(stage: GameStage.dayLastWords, player: final player) ||
            GameStateWithPlayer(stage: GameStage.nightLastWords, player: final player)) {
      players.kill(player.number);
    }
    if (oldState is GameStateVoting) {
      final state = _state as GameStateVoting;
      state.votes[state.player] = state.currentPlayerVotes ?? 0;
    }
    _state = nextState;
  }

  /// Gets previous game state according to game internal state, and returns it.
  /// Doesn't change internal state. May throw exceptions if game internal state is inconsistent.
  /// Returns `null` if there is no previous state.
  BaseGameState? get previousState {
    if (_history.isEmpty) {
      return null;
    }
    return _history.last;
  }

  void setPreviousState() {
    final previousState = this.previousState;
    if (previousState == null) {
      throw StateError("Can't go to previous state");
    }
    if (previousState
        case GameStateWithPlayer(stage: GameStage.nightLastWords, player: final player) ||
            GameStateWithCurrentPlayer(stage: GameStage.dayLastWords, player: final player)) {
      players.revive(player.number);
    }
    _history.removeLast();
    _state = previousState;
  }

  void togglePlayerSelected(int playerNumber) {
    // TODO: "best move" when logging will be added
    final state = _state;
    final player = players.getByNumber(playerNumber);
    if (!player.isAlive) {
      return;
    }
    if (state is GameStateSpeaking) {
      if (state.accusations.containsValue(player)) {
        return;
      }
      if (state.accusations[state.player] == player) {
        state.accusations.remove(state.player);
      } else {
        state.accusations[state.player] = player;
      }
      return;
    }
    if (state is GameStateNightKill) {
      _state = GameStateNightKill(
        day: state.day,
        mafiaTeam: state.mafiaTeam,
        thisNightKilledPlayer: state.thisNightKilledPlayer == player ? null : player,
      );
      return;
    }
  }

  void deselectAllPlayers() {
    if (_state.stage != GameStage.dropTableVoting || _state is! GameStateWithPlayers) {
      return;
    }
    final state = _state as GameStateWithPlayers;
    _state = GameStateWithPlayers(
      stage: GameStage.dropTableVoting,
      day: state.day,
      players: Iterable<Player>.generate(0).toUnmodifiableList(),
    );
  }

  List<int> get voteCandidates {
    if (!state.stage.isAnyOf([
      GameStage.preVoting,
      GameStage.voting,
      GameStage.preFinalVoting,
      GameStage.finalVoting,
    ])) {
      throw StateError("Can't get vote candidates in state ${state.stage}");
    }
    if (_state is GameStateWithPlayers) {
      final state = _state as GameStateWithPlayers;
      return state.players.map((e) => e.number).toUnmodifiableList();
    }
    if (_state is GameStateVoting) {
      final state = _state as GameStateVoting;
      return state.votes.keys.map((e) => e.number).toUnmodifiableList();
    }
    throw AssertionError("Unexpected state type: ${_state.runtimeType}");
  }

  void vote(int playerNumber, int count) {
    if (_state is! GameStateVoting) {
      return;
    }
    final state = _state as GameStateVoting;
    _state = GameStateVoting(
      stage: state.stage,
      day: state.day,
      player: state.player,
      votes: state.votes,
      currentPlayerVotes: count,
    );
  }

  int? getPlayerVotes(int playerNumber) {
    if (_state is! GameStateVoting) {
      return null;
    }
    final state = _state as GameStateVoting;
    return state.votes[players.getByNumber(playerNumber)];
  }

  // region Private helpers
  Player _nextAlivePlayer({required int fromNumber}) {
    for (var i = fromNumber % 10 + 1; i != fromNumber; i = i % 10 + 1) {
      final player = players.getByNumber(i);
      if (player.isAlive) {
        return player;
      }
    }
    throw StateError("No alive players");
  }

  BaseGameState _handleVoting() {
    final maxVotesPlayers = _maxVotesPlayers;
    final state = _state as GameStateVoting;
    if (maxVotesPlayers == null) {
      Player? nextPlayer;
      for (final p in state.votes.keys) {
        if (state.votes[p] == null && p != state.player) {
          nextPlayer = p;
          break;
        }
      }
      if (nextPlayer == null) {
        throw AssertionError("No player to vote");
      }
      return GameStateVoting(
        stage: state.stage,
        day: state.day,
        player: nextPlayer,
        votes: LinkedHashMap.of({...state.votes, state.player: state.currentPlayerVotes ?? 0}),
        currentPlayerVotes: null,
      );
    }
    if (maxVotesPlayers.length == 1) {
      return GameStateWithCurrentPlayer(
        stage: GameStage.dayLastWords,
        day: _state.day,
        players: maxVotesPlayers,
        playerIndex: 0,
      );
    }
    if (state.stage == GameStage.voting) {
      return GameStateWithCurrentPlayer(
        stage: GameStage.excuse,
        day: state.day,
        players: maxVotesPlayers,
        playerIndex: 0,
      );
    }
    // TODO: https://mafiaworldtour.com/fiim-rules 4.4.12.2
    return GameStateWithPlayers(
      stage: GameStage.dropTableVoting,
      day: state.day,
      players: maxVotesPlayers,
    );
  }

  BaseGameState _handleEndOfNight() {
    final state = _state as GameStateNightCheck;
    final thisNightKilledPlayer = state.thisNightKilledPlayer;
    if (thisNightKilledPlayer != null) {
      return GameStateWithPlayer(
        stage: GameStage.nightLastWords,
        day: state.day,
        player: thisNightKilledPlayer,
      );
    }
    return GameStateSpeaking(
      day: state.day + 1,
      player: players.getByNumber(_firstSpeakingPlayerNumber),
      accusations: LinkedHashMap(),
    );
  }

  List<Player>? get _maxVotesPlayers {
    if (_state is! GameStateVoting) {
      if (_state is GameStateWithPlayers &&
          _state.stage.isAnyOf([GameStage.preVoting, GameStage.preFinalVoting])) {
        final state = _state as GameStateWithPlayers;
        if (state.players.length == 1) {
          return state.players;
        }
      }
      return null;
    }
    final state = _state as GameStateVoting;
    final votes = {...state.votes, state.player: state.currentPlayerVotes};
    final aliveCount = players.aliveCount;
    if (votes[state.player] == null) {
      votes[state.player] = 0;
    }
    if (votes.values.nonNulls.length + 1 == votes.length) {
      // All players except one was voted against
      // The rest of the votes will be given to the last player
      votes[votes.keys.last] = aliveCount - votes.values.nonNulls.sum;
      assert(votes.values.nonNulls.sum == aliveCount);
    }
    final nonNullVotes = votes.values.nonNulls;
    final votesTotal = nonNullVotes.sum;
    if (nonNullVotes.isEmpty || votesTotal <= aliveCount ~/ 2) {
      return null;
    }
    final max = nonNullVotes.max();
    if (aliveCount - votesTotal >= max) {
      return null;
    }
    final res = votes.entries.where((e) => e.value == max).map((e) => e.key).toUnmodifiableList();
    assert(res.isNotEmpty);
    return res;
  }

  int get _firstSpeakingPlayerNumber {
    final previousFirstSpeakingPlayer = _history
        .where((e) => e is GameStateSpeaking && e.day == _state.day)
        .cast<GameStateSpeaking>()
        .firstOrNull
        ?.player;
    Player result = previousFirstSpeakingPlayer ?? players.getByNumber(1);
    if (_state is GameStateSpeaking) {
      return result.number;
    }
    result = _nextAlivePlayer(fromNumber: result.number);
    if (_state case GameStateWithPlayer(stage: GameStage.nightLastWords, player: final player)) {
      if (player == result) {
        result = _nextAlivePlayer(fromNumber: result.number);
      }
    }
    return result.number;
  }
// endregion
}
