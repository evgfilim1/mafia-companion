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
  //var _consequentDaysWithoutKills = 0; // TODO: use this
  int? _lastVotedPlayer;

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
          return GameStateWithPlayer(
            state: GameState.voting,
            player: _players[_selectedPlayers.first],
          );
        }
        return GameStateWithPlayer(state: GameState.speaking, player: _players[next]);
      case GameState.voting:
        return _handleVoting();
      case GameState.excuse:
        if (_state.player!.number - 1 == _selectedPlayers.last) {
          return GameStateWithPlayer(
            state: GameState.finalVoting,
            player: _players[_selectedPlayers.first],
          );
        }
        final nextIndex = _nextSelectedPlayer(_state.player!.number - 1);
        return GameStateWithPlayer(
          state: GameState.excuse,
          player: _players[_selectedPlayers[nextIndex]],
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
        final nextIndex = _nextSelectedPlayer(_state.player!.number - 1);
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
  void nextState() {
    final nextState = nextStateAssumption;
    if (nextState == null) {
      throw StateError("Game is over");
    }
    assert(
      validTransitions[_state.state]!.contains(nextState.state),
      "Invalid transition from ${_state.state} to ${nextState.state}",
    );
    final oldState = _state.state;
    switch (nextState.state) {
      case GameState.prepare:
        throw AssertionError("Can't go to prepare state");
      case GameState.night0:
        break;
      case GameState.night0CommissarCheck:
        break;
      case GameState.day:
        _selectedPlayers.clear();
        _lastVotedPlayer = null;
        break;
      case GameState.speaking:
        if (oldState != GameState.speaking) {
          _firstSpeakingPlayer = nextState.player!.number - 1;
        }
        break;
      case GameState.voting:
        if (oldState != GameState.voting) {
          _votes.clear();
        }
        break;
      case GameState.excuse:
        if (oldState == GameState.voting) {
          final maxVotesPlayers = _getMaxVotesPlayers()!;
          _selectedPlayers.clear();
          _selectedPlayers.addAll(maxVotesPlayers);
        }
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
          final maxVotesPlayers = _getMaxVotesPlayers()!;
          _selectedPlayers.clear();
          _selectedPlayers.addAll(maxVotesPlayers);
          _votes.clear();
        }
        nextState.player!.kill();
        break;
      case GameState.nightKill:
        _day++;
        _selectedPlayers.clear();
        break;
      case GameState.nightCheck:
        break;
      case GameState.nightLastWords:
        nextState.player!.kill();
        break;
      case GameState.finish:
        _selectedPlayers.clear();
        _votes.clear();
        break;
    }
    _state = nextState;
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
      if (_lastVotedPlayer == state.player!.number) {
        _selectedPlayers.removeAt(_selectedPlayers.length - 1);
      }
      _lastVotedPlayer = state.player!.number;
    } else if (state.state == GameState.nightKill && _selectedPlayers.isNotEmpty) {
      _selectedPlayers.clear();
    }
    _selectedPlayers.add(index);
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
    if (state.state == GameState.speaking && _lastVotedPlayer == state.player!.number) {
      _lastVotedPlayer = null;
    }
    _selectedPlayers.remove(index);
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
    // TODO: https://mafiaworldtour.com/fiim-rules 4.4.12.2
    final maxVotesPlayers = _getMaxVotesPlayers();
    if (maxVotesPlayers == null) {
      return GameStateWithPlayer(
        state: _state.state,
        player: _players[_selectedPlayers[_votes.length]],
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

  int _nextSelectedPlayer(int from) {
    final nextIndex = _selectedPlayers.indexOf(from) + 1;
    assert(0 < nextIndex && nextIndex < _selectedPlayers.length);
    return nextIndex;
  }

  List<int>? _getMaxVotesPlayers() {
    final votes = {..._votes};
    final aliveCount = players.aliveCount;
    if (votes.length + 1 == _selectedPlayers.length) {
      // All players except one was voted against
      // The rest of the votes will be given to the last player
      votes[_selectedPlayers.last] = aliveCount - votes.values.sum;
    }
    if (votes.isEmpty || votes.values.sum <= aliveCount ~/ 2) {
      return null;
    }
    var max = 0;
    final res = <int>[];
    for (final entry in votes.entries) {
      if (entry.value > max) {
        max = entry.value;
        res.clear();
      }
      if (entry.value == max) {
        res.add(entry.key);
      }
    }
    assert(res.isNotEmpty);
    return res;
  }
// endregion
}

class GameController {
  Game _game = Game();

  Game get currentGame => _game;

  void restart() {
    _game = Game();
  }
}
