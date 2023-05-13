import 'dart:collection';

import '../utils.dart';
import 'logger.dart';
import 'player.dart';
import 'states.dart';

class PlayersView {
  final List<Player> _players;

  PlayersView(List<Player> players)
      : assert(
          players.asMap().entries.every((element) => element.value.number == element.key + 1),
          "Players must be sorted by numbers sequentially 1..10",
        ),
        _players = players;

  int get length => _players.length;

  bool isAlive(int number) => _players[number - 1].isAlive;

  PlayerRole getRole(int number) => _players[number - 1].role;

  int get aliveCount => _players.where((player) => player.isAlive).length;

  int get aliveMafiaCount =>
      _players.where((player) => player.role == PlayerRole.mafia && player.isAlive).length;

  int get donNumber => _players.firstWhere((player) => player.role == PlayerRole.don).number;

  int get commissarNumber =>
      _players.firstWhere((player) => player.role == PlayerRole.commissar).number;

  bool get isDonAlive => isAlive(donNumber);

  bool get isCommissarAlive => isAlive(commissarNumber);
}

/// Game controller. Manages game state and players. Doesn't know about UI.
/// To start new game, create new instance of [Game].
class Game {
  var _day = 0;
  var _state = const GameStateWithPlayer(state: GameState.prepare);
  final List<Player> _players;
  final _logger = GameLogger();
  var _firstSpeakingPlayer = 0;
  final List<int> _selectedPlayers = [];
  final LinkedHashMap<int, int> _votes = LinkedHashMap();
  var _consequentDaysWithoutKills = 0; // TODO: use this
  final _accusations = <int, int>{};
  final _history = <GameStateWithPlayer>[];

  Game() : this.withPlayers(generatePlayers());

  Game.withPlayers(List<Player> players) : _players = players.toUnmodifiableList();

  /// Returns current game state.
  GameStateWithPlayer get state => _state;

  /// Returns current game day, starting from 0.
  int get day => _day;

  PlayersView get players => PlayersView(_players); // TODO: make unmodifiable

  Iterable<PlayerEvent> get log => _logger;

  /// Checks if citizen team won, returns null if game is not over.
  bool? get citizenTeamWon {
    var mafiaCount = 0;
    var citizenCount = 0;
    for (final player in _players) {
      if (!player.isAlive) {
        continue;
      }
      if (player.role.isAnyOf([PlayerRole.mafia, PlayerRole.don])) {
        mafiaCount++;
      } else {
        citizenCount++;
      }
    }
    if (mafiaCount == 0) {
      return true;
    }
    if (citizenCount <= mafiaCount) {
      return false;
    }
    return null;
  }

  /// Checks if game is over.
  bool get isGameOver => _state.state == GameState.finish || citizenTeamWon != null;

  int get totalVotes {
    if (!_state.state.isAnyOf([GameState.voting, GameState.finalVoting])) {
      throw StateError("Can't get total votes in state ${_state.state}");
    }
    return _votes.values.sum;
  }

  /// Assumes next game state according to game internal state, and returns it.
  /// Doesn't change internal state. May throw exceptions if game internal state is inconsistent.
  GameStateWithPlayer? get nextStateAssumption {
    switch (_state.state) {
      case GameState.prepare:
        return const GameStateWithPlayer(state: GameState.night0);
      case GameState.night0:
        return GameStateWithPlayer(
          state: GameState.night0CommissarCheck,
          player: _players[players.commissarNumber - 1],
        );
      case GameState.night0CommissarCheck:
        return const GameStateWithPlayer(state: GameState.day);
      case GameState.day:
        final int next;
        if (_day == 0) {
          next = 0;
        } else {
          next = _nextAlivePlayer(_firstSpeakingPlayer);
        }
        return GameStateWithPlayer(state: GameState.speaking, player: _players[next]);
      case GameState.speaking:
        final next = _nextAlivePlayer(_state.player!.number - 1);
        if (next == _firstSpeakingPlayer) {
          if (_selectedPlayers.isEmpty || _day == 0 && _selectedPlayers.length == 1) {
            return const GameStateWithPlayer(state: GameState.nightKill);
          }
          return const GameStateWithPlayer(state: GameState.preVoting);
        }
        return GameStateWithPlayer(state: GameState.speaking, player: _players[next]);
      case GameState.preVoting:
        final player = _players[_selectedPlayers.first];
        if (_selectedPlayers.length == 1) {
          return GameStateWithPlayer(state: GameState.dayLastWords, player: player);
        }
        return GameStateWithPlayer(state: GameState.voting, player: player);
      case GameState.voting:
        return _handleVoting();
      case GameState.excuse:
        if (_state.player!.number - 1 == _selectedPlayers.last) {
          return const GameStateWithPlayer(state: GameState.preFinalVoting);
        }
        final nextIndex = _nextSelectedPlayerIndex(_state.player!.number - 1)!;
        return GameStateWithPlayer(
          state: GameState.excuse,
          player: _players[_selectedPlayers[nextIndex]],
        );
      case GameState.preFinalVoting:
        return GameStateWithPlayer(
          state: GameState.finalVoting,
          player: _players[_selectedPlayers.first],
        );
      case GameState.finalVoting:
        return _handleVoting();
      case GameState.dropTableVoting:
        if (_selectedPlayers.isEmpty) {
          return const GameStateWithPlayer(state: GameState.nightKill);
        }
        return GameStateWithPlayer(
          state: GameState.dayLastWords,
          player: _players[_selectedPlayers.first],
        );
      case GameState.dayLastWords:
        if (_state.player!.number - 1 == _selectedPlayers.last) {
          if (isGameOver) {
            return const GameStateWithPlayer(state: GameState.finish);
          }
          return const GameStateWithPlayer(state: GameState.nightKill);
        }
        final nextIndex = _nextSelectedPlayerIndex(_state.player!.number - 1)!;
        return GameStateWithPlayer(
          state: GameState.dayLastWords,
          player: _players[_selectedPlayers[nextIndex]],
        );
      case GameState.nightKill:
        return GameStateWithPlayer(
          state: GameState.nightCheck,
          player: _players[players.donNumber - 1],
        );
      case GameState.nightCheck:
        if (_state.player!.role == PlayerRole.don) {
          return GameStateWithPlayer(
            state: GameState.nightCheck,
            player: _players[players.commissarNumber - 1],
          );
        }
        return _handleEndOfNight();
      case GameState.nightLastWords:
        if (isGameOver) {
          return const GameStateWithPlayer(state: GameState.finish);
        }
        return const GameStateWithPlayer(state: GameState.day);
      case GameState.finish:
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
      validTransitions[_state.state]?.contains(nextState.state) == true,
      "Invalid or unspecified transition from ${_state.state} to ${nextState.state}",
    );
    final oldState = _state.state;
    _history.add(_state);
    if (oldState.isAnyOf([GameState.dayLastWords, GameState.nightLastWords])) {
      _state.player!.kill();
    }
    switch (nextState.state) {
      case GameState.prepare:
        throw AssertionError("Can't go to prepare state");
      case GameState.night0:
        break;
      case GameState.night0CommissarCheck:
        break;
      case GameState.day:
        _selectedPlayers.clear();
        _accusations.clear();
        break;
      case GameState.speaking:
        if (oldState != GameState.speaking) {
          _firstSpeakingPlayer = nextState.player!.number - 1;
        }
        break;
      case GameState.preVoting:
        break;
      case GameState.voting:
        if (oldState != GameState.voting) {
          _votes.clear();
        }
        break;
      case GameState.excuse:
        if (oldState == GameState.voting) {
          final maxVotesPlayers = _maxVotesPlayers!;
          _selectedPlayers.clear();
          _selectedPlayers.addAll(maxVotesPlayers);
        }
        break;
      case GameState.preFinalVoting:
        break;
      case GameState.finalVoting:
        if (oldState != GameState.finalVoting) {
          _votes.clear();
        }
        break;
      case GameState.dropTableVoting:
        break;
      case GameState.dayLastWords:
        if (oldState != GameState.dayLastWords) {
          final maxVotesPlayers = _maxVotesPlayers!;
          _selectedPlayers.clear();
          _selectedPlayers.addAll(maxVotesPlayers);
          _votes.clear();
        }
        break;
      case GameState.nightKill:
        _day++;
        _selectedPlayers.clear();
        break;
      case GameState.nightCheck:
        break;
      case GameState.nightLastWords:
        break;
      case GameState.finish:
        _selectedPlayers.clear();
        _votes.clear();
        break;
    }
    if (oldState == GameState.voting && _votes[_state.player!.number - 1] == null) {
      _votes[_state.player!.number - 1] = 0;
    }
    _state = nextState;
  }

  /// Gets previous game state according to game internal state, and returns it.
  /// Doesn't change internal state. May throw exceptions if game internal state is inconsistent.
  /// Returns `null` if there is no previous state.
  GameStateWithPlayer? get previousState {
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
    if (previousState.state.isAnyOf([GameState.dayLastWords, GameState.nightLastWords])) {
      previousState.player!.revive(); // Finally, infinite lives!
    }
    if (previousState.state.isAnyOf(
        [GameState.preVoting, GameState.voting, GameState.preFinalVoting, GameState.finalVoting])) {
      _votes.remove(_state.player!.number - 1);
    }
    _history.removeLast();
    _state = previousState;
  }

  void selectPlayer(int playerNumber) {
    if (!state.state.isAnyOf([
      GameState.speaking,
      GameState.nightKill,
      //GameState.nightLastWords, // TODO: "best move"
    ])) {
      return;
    }
    final index = playerNumber - 1;
    if (_selectedPlayers.contains(index)) {
      return;
    }
    if (!_players[index].isAlive) {
      return;
    }
    if (state.state == GameState.speaking) {
      final thisPlayerAccusation = _accusations[state.player!.number - 1];
      if (thisPlayerAccusation != null) {
        _selectedPlayers.remove(thisPlayerAccusation);
      }
      if (thisPlayerAccusation == index) {
        _accusations.remove(state.player!.number - 1);
      } else {
        _selectedPlayers.add(index);
        _accusations[state.player!.number - 1] = index;
      }
    } else if (state.state == GameState.nightKill && _selectedPlayers.isNotEmpty) {
      _selectedPlayers.clear();
    } else {
      _selectedPlayers.add(index);
    }
  }

  bool isPlayerSelected(int playerNumber) {
    final index = playerNumber - 1;
    return _selectedPlayers.contains(index);
  }

  void deselectPlayer(int playerNumber) {
    if (!state.state.isAnyOf([
      GameState.speaking,
      GameState.nightKill,
    ])) {
      return;
    }
    final index = playerNumber - 1;
    if (state.state == GameState.speaking) {
      final thisPlayerAccusation = _accusations[state.player!.number - 1];
      if (thisPlayerAccusation == index) {
        _accusations.remove(state.player!.number - 1);
        _selectedPlayers.remove(index);
      }
    } else {
      _selectedPlayers.remove(index);
    }
  }

  void deselectAllPlayers() {
    if (!state.state.isAnyOf([
      GameState.speaking,
      GameState.dropTableVoting,
      GameState.nightKill,
    ])) {
      return;
    }
    _selectedPlayers.clear();
  }

  List<int> get voteCandidates {
    if (!state.state.isAnyOf([
      GameState.preVoting,
      GameState.voting,
      GameState.preFinalVoting,
      GameState.finalVoting,
    ])) {
      throw StateError("Can't get vote candidates in state ${state.state}");
    }
    return _selectedPlayers.map((e) => e + 1).toUnmodifiableList();
  }

  void vote(int playerNumber, int count) {
    if (!state.state.isAnyOf([
      GameState.voting,
      GameState.finalVoting,
    ])) {
      return;
    }
    final index = playerNumber - 1;
    _votes[index] = count;
  }

  int getPlayerVotes(int playerNumber) {
    final index = playerNumber - 1;
    return _votes[index] ?? 0;
  }

  int _nextMod(int i, int mod) => (i + 1) % mod;

  // region Private helpers
  int _nextAlivePlayer(int from) {
    for (var i = _nextMod(from, _players.length); i != from; i = _nextMod(i, _players.length)) {
      if (_players[i].isAlive) {
        return i;
      }
    }
    throw StateError("No alive players");
  }

  GameStateWithPlayer _handleVoting() {
    final maxVotesPlayers = _maxVotesPlayers;
    if (maxVotesPlayers == null) {
      final nextSelectedPlayer = _nextSelectedPlayerIndex(_state.player!.number - 1)!;
      return GameStateWithPlayer(
        state: _state.state,
        player: _players[nextSelectedPlayer],
      );
    }
    if (maxVotesPlayers.length == 1) {
      return GameStateWithPlayer(
        state: GameState.dayLastWords,
        player: _players[maxVotesPlayers.first],
      );
    }
    if (_state.state == GameState.voting) {
      return GameStateWithPlayer(state: GameState.excuse, player: _players[maxVotesPlayers.first]);
    }
    // TODO: https://mafiaworldtour.com/fiim-rules 4.4.12.2
    return const GameStateWithPlayer(state: GameState.dropTableVoting);
  }

  GameStateWithPlayer _handleEndOfNight() {
    if (_selectedPlayers.isEmpty) {
      return const GameStateWithPlayer(state: GameState.day);
    }
    return GameStateWithPlayer(
      state: GameState.nightLastWords,
      player: _players[_selectedPlayers.first],
    );
  }

  int? _nextSelectedPlayerIndex(int from) {
    final nextIndex = _selectedPlayers.indexOf(from) + 1;
    assert(0 < nextIndex && nextIndex <= _selectedPlayers.length);
    return nextIndex != _selectedPlayers.length ? _selectedPlayers[nextIndex] : null;
  }

  List<int>? get _maxVotesPlayers {
    final votes = {..._votes};
    final aliveCount = players.aliveCount;
    if (votes[_state.player!.number - 1] == null) {
      votes[_state.player!.number - 1] = 0;
    }
    if (votes.length + 1 == _selectedPlayers.length) {
      // All players except one was voted against
      // The rest of the votes will be given to the last player
      votes[_selectedPlayers.last] = aliveCount - totalVotes;
    }
    final votesTotal = votes.values.sum;
    if (votes.isEmpty || votesTotal <= aliveCount ~/ 2) {
      return null;
    }
    final max = votes.values.maxItem;
    if (aliveCount - votesTotal >= max) {
      return null;
    }
    final res = votes.entries.where((e) => e.value == max).map((e) => e.key).toUnmodifiableList();
    assert(res.isNotEmpty);
    return res;
  }
// endregion
}
