import "dart:collection";

import "../utils/extensions.dart";
import "log.dart";
import "player.dart";
import "players_view.dart";
import "states.dart";

/// Game controller. Manages game state and players. Shouldn't know about UI.
/// To start new game, create new instance of [Game].
class Game {
  final GameLog _log;
  final bool skipBestTurnStage;

  /// Creates new game with players generated by [generatePlayers] with default config.
  /// If [skipBestTurnStage] is `true`, then game will skip [GameStage.bestTurn] stage.
  factory Game({
    bool skipBestTurnStage = false,
  }) =>
      Game.withPlayers(
        generatePlayers(),
        skipBestTurnStage: skipBestTurnStage,
      );

  /// Creates new game with given players. If [skipBestTurnStage] is `true`, then game will skip
  /// [GameStage.bestTurn] stage.
  factory Game.withPlayers(
    List<Player> players, {
    bool skipBestTurnStage = false,
  }) {
    final sortedPlayers = players
      ..sort((a, b) => a.number.compareTo(b.number))
      ..toUnmodifiableList();
    final log = GameLog()
      ..add(
        StateChangeGameLogItem(
          oldState: null,
          newState: GameStatePrepare(players: sortedPlayers),
        ),
      );
    return Game._(log, skipBestTurnStage);
  }

  Game._(this._log, this.skipBestTurnStage);

  /// Returns current game state.
  BaseGameState get state => _log.lastWhereType<StateChangeGameLogItem>().newState;

  /// Returns game log.
  Iterable<BaseGameLogItem> get log => _log;

  /// Returns convenient players view.
  PlayersView get players => PlayersView(state.players);

  /// Assumes team that will win if game ends right now. Returns [PlayerRole.mafia],
  /// [PlayerRole.citizen] or `null` if the game can't end right now.
  PlayerRole? get winTeamAssumption {
    var aliveMafia = players.aliveMafiaCount;
    var aliveCitizens = players.aliveCount - aliveMafia;
    if (state
        case GameStateWithPlayer(
              stage: GameStage.nightLastWords,
              currentPlayerNumber: final playerNumber,
            ) ||
            GameStateWithIterablePlayers(
              stage: GameStage.dayLastWords,
              currentPlayerNumber: final playerNumber,
            )) {
      final player = players.getByNumber(playerNumber);
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

  /// Checks if the game is over.
  bool get isGameOver => state.stage == GameStage.finish || winTeamAssumption != null;

  /// Checks if the game is running.
  bool get isActive => !state.stage.isAnyOf([GameStage.prepare, GameStage.finish]);

  int get totalVotes {
    if (state case GameStateVoting(votes: final votes)) {
      return votes.values.nonNulls.sum;
    }
    throw StateError("Can't get total votes in state ${state.runtimeType}");
  }

  /// Assumes next game state according to game internal state, and returns it.
  /// Doesn't change internal state. May throw exceptions if game internal state is inconsistent.
  BaseGameState? get nextStateAssumption {
    switch (state) {
      case GameStatePrepare():
        return GameStateWithPlayers(
          stage: GameStage.night0,
          day: 0,
          players: state.players,
          playerNumbers: players.mafiaTeam.map((player) => player.number).toUnmodifiableList(),
        );
      case GameStateWithPlayers(stage: GameStage.night0):
        return GameStateWithPlayer(
          stage: GameStage.night0SheriffCheck,
          day: 0,
          players: state.players,
          currentPlayerNumber: players.sheriff.number,
        );
      case GameStateWithPlayer(stage: GameStage.night0SheriffCheck):
        return GameStateSpeaking(
          currentPlayerNumber: 1,
          day: state.day + 1,
          players: state.players,
          accusations: LinkedHashMap(),
        );
      case GameStateSpeaking(accusations: final accusations, currentPlayerNumber: final pn):
        final alreadySpokeCount = _log
            .whereType<StateChangeGameLogItem>()
            .where((e) => e.oldState != null && e.newState.hasStateChanged(e.oldState!))
            .map((e) => e.newState)
            .where((e) => e is GameStateSpeaking && e.day == state.day)
            .cast<GameStateSpeaking>()
            .length;
        if (alreadySpokeCount == players.aliveCount) {
          if (accusations.isEmpty || state.day == 1 && accusations.length == 1) {
            return GameStateNightKill(
              day: state.day,
              players: state.players,
              mafiaTeam: players.mafiaTeam.map((player) => player.number).toUnmodifiableList(),
              thisNightKilledPlayerNumber: null,
            );
          }
          return GameStateWithPlayers(
            stage: GameStage.preVoting,
            day: state.day,
            players: state.players,
            playerNumbers: accusations.values.toUnmodifiableList(),
          );
        }
        final next = _nextAlivePlayer(fromNumber: pn);
        assert(next.isAlive, "Next player must be alive");
        return GameStateSpeaking(
          currentPlayerNumber: next.number,
          day: state.day,
          players: state.players,
          accusations: LinkedHashMap.of(accusations),
        );
      case GameStateWithPlayers(
          stage: GameStage.preVoting || GameStage.preFinalVoting,
          playerNumbers: final pns,
        ):
        if (pns.length == 1) {
          return GameStateWithIterablePlayers(
            stage: GameStage.dayLastWords,
            day: state.day,
            players: state.players,
            playerNumbers: pns,
            currentPlayerIndex: 0,
          );
        }
        return GameStateVoting(
          stage: state.stage == GameStage.preVoting ? GameStage.voting : GameStage.finalVoting,
          day: state.day,
          players: state.players,
          currentPlayerNumber: pns.first,
          votes: LinkedHashMap.fromEntries(pns.map((player) => MapEntry(player, null))),
          currentPlayerVotes: null,
        );
      case GameStateVoting(
          stage: GameStage.voting || GameStage.finalVoting,
          votes: final votes,
          currentPlayerNumber: final pn,
          currentPlayerVotes: final pv,
        ):
        final maxVotesPlayers = _maxVotesPlayers;
        if (maxVotesPlayers == null) {
          int? nextPlayerNumber;
          for (final p in votes.keys) {
            if (votes[p] == null && p != pn) {
              nextPlayerNumber = p;
              break;
            }
          }
          if (nextPlayerNumber == null) {
            throw AssertionError("No player to vote");
          }
          return GameStateVoting(
            stage: state.stage,
            day: state.day,
            players: state.players,
            currentPlayerNumber: nextPlayerNumber,
            votes: LinkedHashMap.of(votes)..addAll({pn: pv ?? 0}),
            currentPlayerVotes: null,
          );
        }
        if (maxVotesPlayers.length == 1) {
          return GameStateWithIterablePlayers(
            stage: GameStage.dayLastWords,
            day: state.day,
            players: state.players,
            playerNumbers: maxVotesPlayers,
            currentPlayerIndex: 0,
          );
        }
        if (state.stage == GameStage.finalVoting && maxVotesPlayers.length == votes.length) {
          if (maxVotesPlayers.length == players.aliveCount) {
            // Rule 7.8
            return GameStateNightKill(
              day: state.day,
              players: state.players,
              mafiaTeam: players.mafiaTeam.map((player) => player.number).toUnmodifiableList(),
              thisNightKilledPlayerNumber: null,
            );
          }
          return GameStateDropTableVoting(
            day: state.day,
            players: state.players,
            playerNumbers: maxVotesPlayers,
            votesForDropTable: 0,
          );
        }
        return GameStateWithIterablePlayers(
          stage: GameStage.excuse,
          day: state.day,
          players: state.players,
          playerNumbers: maxVotesPlayers,
          currentPlayerIndex: 0,
        );
      case GameStateWithIterablePlayers(
          stage: GameStage.excuse,
          playerNumbers: final pns,
          currentPlayerIndex: final i,
        ):
        if (i == pns.length - 1) {
          return GameStateWithPlayers(
            stage: GameStage.preFinalVoting,
            day: state.day,
            players: state.players,
            playerNumbers: pns,
          );
        }
        return GameStateWithIterablePlayers(
          stage: GameStage.excuse,
          day: state.day,
          players: state.players,
          playerNumbers: pns,
          currentPlayerIndex: i + 1,
        );
      case GameStateDropTableVoting(votesForDropTable: final votes, playerNumbers: final pns):
        if (votes <= players.aliveCount ~/ 2) {
          return GameStateNightKill(
            day: state.day,
            players: state.players,
            mafiaTeam: players.mafiaTeam.map((player) => player.number).toUnmodifiableList(),
            thisNightKilledPlayerNumber: null,
          );
        }
        return GameStateWithIterablePlayers(
          stage: GameStage.dayLastWords,
          day: state.day,
          players: state.players,
          playerNumbers: pns,
          currentPlayerIndex: 0,
        );
      case GameStateWithIterablePlayers(
          stage: GameStage.dayLastWords,
          playerNumbers: final pns,
          currentPlayerIndex: final i,
        ):
        final newPlayers = List.of(state.players);
        newPlayers[pns[i] - 1] = newPlayers[pns[i] - 1].copyWith(isAlive: false);
        if (i == pns.length - 1) {
          if (isGameOver) {
            return GameStateFinish(
              day: state.day,
              winner: winTeamAssumption,
              players: newPlayers,
            );
          }
          return GameStateNightKill(
            day: state.day,
            players: newPlayers,
            mafiaTeam: players.mafiaTeam.map((player) => player.number).toUnmodifiableList(),
            thisNightKilledPlayerNumber: null,
          );
        }
        return GameStateWithIterablePlayers(
          stage: GameStage.dayLastWords,
          day: state.day,
          players: newPlayers,
          playerNumbers: pns,
          currentPlayerIndex: i + 1,
        );
      case GameStateNightKill():
        return GameStateNightCheck(
          day: state.day,
          players: state.players,
          activePlayerNumber: players.don.number,
        );
      case GameStateNightCheck(activePlayerNumber: final pn):
        if (players.getByNumber(pn).role == PlayerRole.don) {
          return GameStateNightCheck(
            day: state.day,
            players: state.players,
            activePlayerNumber: players.sheriff.number,
          );
        }
        final killedPlayerNumber = (_log
                .whereType<StateChangeGameLogItem>()
                .lastWhere((e) => e.oldState is GameStateNightKill)
                .oldState! as GameStateNightKill)
            .thisNightKilledPlayerNumber;
        if (killedPlayerNumber != null) {
          if (state.day == 1 && players.aliveCount >= players.count - 1 && !skipBestTurnStage) {
            return GameStateBestTurn(
              day: state.day,
              players: state.players,
              currentPlayerNumber: killedPlayerNumber,
              playerNumbers: const [],
            );
          }
          return GameStateWithPlayer(
            stage: GameStage.nightLastWords,
            day: state.day,
            players: state.players,
            currentPlayerNumber: killedPlayerNumber,
          );
        }
        if (_consequentDaysWithoutKills >= 3) {
          return GameStateFinish(
            day: state.day,
            players: state.players,
            winner: null,
          );
        }
        return GameStateSpeaking(
          day: state.day + 1,
          players: state.players,
          currentPlayerNumber: _firstSpeakingPlayerNumber,
          accusations: LinkedHashMap(),
        );
      case GameStateBestTurn(currentPlayerNumber: final pn):
        return GameStateWithPlayer(
          stage: GameStage.nightLastWords,
          day: state.day,
          players: state.players,
          currentPlayerNumber: pn,
        );
      case GameStateWithPlayer(stage: GameStage.nightLastWords, currentPlayerNumber: final pn):
        final newPlayers = List.of(state.players);
        newPlayers[pn - 1] = newPlayers[pn - 1].copyWith(isAlive: false);
        if (isGameOver) {
          return GameStateFinish(
            day: state.day,
            winner: winTeamAssumption,
            players: newPlayers.toUnmodifiableList(),
          );
        }
        return GameStateSpeaking(
          currentPlayerNumber: _firstSpeakingPlayerNumber,
          day: state.day + 1,
          players: newPlayers.toUnmodifiableList(),
          accusations: LinkedHashMap(),
        );
      case GameStateFinish():
        return null;
      default:
        throw AssertionError("Unexpected state: $state");
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
      validTransitions[state.stage]?.contains(nextState.stage) ?? false,
      "Invalid or unspecified transition from ${state.stage} to ${nextState.stage}",
    );
    // I don't know where to put these assertion, so I leave them here.
    assert(
      state.players.indexed.every((r) => r.$2.number == r.$1 + 1),
      "Players must be sorted by number",
    );
    assert(
      state.players.runtimeType == List<Player>.unmodifiable([]).runtimeType,
      "Players must be unmodifiable",
    );
    final oldState = state;
    _log.add(StateChangeGameLogItem(oldState: oldState, newState: nextState));
  }

  /// Gets previous game state according to game internal state, and returns it.
  /// Doesn't change internal state. May throw exceptions if game internal state is inconsistent.
  /// Returns `null` if there is no previous state.
  BaseGameState? get previousState => _log
      .whereType<StateChangeGameLogItem>()
      .map((e) => e.oldState)
      .lastWhere((e) => e != null && state.hasStateChanged(e), orElse: () => null);

  void setPreviousState() {
    final prevState = previousState;
    if (prevState == null) {
      throw StateError("Can't go to previous state");
    }
    _log.removeLastUntil(
      (item) => item is StateChangeGameLogItem && identical(item.newState, prevState),
    );
  }

  void togglePlayerSelected(int playerNumber) {
    final player = players.getByNumber(playerNumber);
    if (!player.isAlive) {
      return;
    }
    final currentState = state;
    if (currentState
        case GameStateSpeaking(accusations: final accusations, currentPlayerNumber: final pn)) {
      final newAccusations = LinkedHashMap.of(accusations);
      if (newAccusations[pn] == playerNumber) {
        // toggle (deselect) player
        newAccusations.remove(pn);
      } else if (!newAccusations.containsValue(playerNumber)) {
        // player is not yet selected
        newAccusations[pn] = playerNumber;
      }
      _log.add(
        StateChangeGameLogItem(
          oldState: currentState,
          newState: currentState.copyWith(accusations: newAccusations),
        ),
      );
      return;
    }
    if (currentState case GameStateNightKill(thisNightKilledPlayerNumber: final kn)) {
      _log.add(
        StateChangeGameLogItem(
          oldState: currentState,
          newState: currentState.copyWith(
            thisNightKilledPlayerNumber: kn == playerNumber ? null : playerNumber,
          ),
        ),
      );
      return;
    }
    if (currentState case GameStateBestTurn(playerNumbers: final pns)) {
      final playerNumbers = List.of(pns);
      if (playerNumbers.contains(playerNumber)) {
        playerNumbers.remove(playerNumber);
      } else if (playerNumbers.length < 3) {
        playerNumbers.add(playerNumber);
      }
      _log.add(
        StateChangeGameLogItem(
          oldState: currentState,
          newState: currentState.copyWith(playerNumbers: playerNumbers.toUnmodifiableList()),
        ),
      );
      return;
    }
  }

  /// Vote for [playerNumber] with [count] votes. [playerNumber] is ignored (can be `null`) if
  /// game [state] is [GameStateDropTableVoting].
  void vote(int? playerNumber, int count) {
    final currentState = state;
    if (currentState is GameStateDropTableVoting) {
      _log.add(
        StateChangeGameLogItem(
          oldState: currentState,
          newState: currentState.copyWith(votesForDropTable: count),
        ),
      );
      return;
    }
    if (currentState is GameStateVoting) {
      if (playerNumber == null) {
        throw ArgumentError.value(
          playerNumber,
          "playerNumber",
          "You must specify player number to vote for",
        );
      }
      _log.add(
        StateChangeGameLogItem(
          oldState: currentState,
          newState: currentState.copyWith(currentPlayerVotes: count),
        ),
      );
      return;
    }
    throw StateError("Can't vote in state ${state.runtimeType}");
  }

  void warnPlayer(int number) {
    final currentState = state;
    if (!isActive) {
      throw StateError("Can't warn player in state ${state.runtimeType}");
    }
    final newPlayers = List.of(currentState.players);
    newPlayers[number - 1] =
        newPlayers[number - 1].copyWith(warns: newPlayers[number - 1].warns + 1);
    // This weird thing is needed to make Dart analyzer happy and to be type safe.
    // I could make it prettier like below, but it may lead to runtime errors in future.
    // final newState = (currentState as dynamic).copyWith(players: newPlayers);
    final newState = switch (currentState) {
      GameStatePrepare() => currentState.copyWith(players: newPlayers),
      GameStateWithPlayer() => currentState.copyWith(players: newPlayers),
      GameStateSpeaking() => currentState.copyWith(players: newPlayers),
      GameStateVoting() => currentState.copyWith(players: newPlayers),
      GameStateDropTableVoting() => currentState.copyWith(players: newPlayers),
      GameStateWithPlayers() => currentState.copyWith(players: newPlayers),
      GameStateNightKill() => currentState.copyWith(players: newPlayers),
      GameStateNightCheck() => currentState.copyWith(players: newPlayers),
      GameStateBestTurn() => currentState.copyWith(players: newPlayers),
      GameStateWithIterablePlayers() => currentState.copyWith(players: newPlayers),
      GameStateFinish() => currentState.copyWith(players: newPlayers),
    };
    _log.add(StateChangeGameLogItem(oldState: currentState, newState: newState));
  }

  int getPlayerWarnCount(int number) => players.getByNumber(number).warns;

  bool checkPlayer(int number) {
    final checkedPlayer = players.getByNumber(number);
    if (state case GameStateNightCheck(activePlayerNumber: final playerNumber)) {
      final activePlayer = players.getByNumber(playerNumber);
      _log.add(PlayerCheckedGameLogItem(playerNumber: number, checkedByRole: activePlayer.role));
      if (activePlayer.role == PlayerRole.don) {
        return checkedPlayer.role == PlayerRole.sheriff;
      }
      if (activePlayer.role == PlayerRole.sheriff) {
        return checkedPlayer.role.isMafia;
      }
      throw AssertionError();
    }
    throw StateError("Cannot check player in state ${state.runtimeType}");
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

  List<int>? get _maxVotesPlayers {
    if (state
        case GameStateWithPlayers(
          stage: GameStage.preVoting || GameStage.preFinalVoting,
          playerNumbers: final pns
        )) {
      if (pns.length == 1) {
        return pns;
      }
    }
    if (state
        case GameStateVoting(
          votes: final votes,
          currentPlayerNumber: final pn,
          currentPlayerVotes: final pv
        )) {
      final newVotes = {...votes, pn: pv ?? 0};
      final aliveCount = players.aliveCount;
      if (newVotes[pn] == null) {
        newVotes[pn] = 0;
      }
      if (newVotes.values.nonNulls.length + 1 == newVotes.length) {
        // All players except one was voted against
        // The rest of the votes will be given to the last player
        newVotes[votes.keys.last] = aliveCount - newVotes.values.nonNulls.sum;
        assert(newVotes.values.nonNulls.sum == aliveCount, "BUG in votes calculation");
      }
      final nonNullVotes = newVotes.values.nonNulls;
      final votesTotal = nonNullVotes.sum;
      if (nonNullVotes.isEmpty || votesTotal <= aliveCount ~/ 2) {
        return null;
      }
      final max = nonNullVotes.max();
      if (aliveCount - votesTotal >= max) {
        return null;
      }
      final res =
          newVotes.entries.where((e) => e.value == max).map((e) => e.key).toUnmodifiableList();
      assert(res.isNotEmpty, "BUG in votes calculation");
      return res;
    }
    throw StateError("Can't get max votes in state ${state.runtimeType}");
  }

  int get _firstSpeakingPlayerNumber {
    final previousFirstSpeakingPlayer = _log
        .whereType<StateChangeGameLogItem>()
        .map((e) => e.oldState)
        .where((e) => e is GameStateSpeaking && e.day == state.day)
        .cast<GameStateSpeaking>()
        .firstOrNull
        ?.currentPlayerNumber;
    if (state is GameStateSpeaking) {
      throw AssertionError("_firstSpeakingPlayerNumber called in GameStateSpeaking");
    }
    var result = _nextAlivePlayer(fromNumber: previousFirstSpeakingPlayer ?? 1).number;
    if (state
        case GameStateWithPlayer(
          stage: GameStage.nightLastWords,
          currentPlayerNumber: final playerNumber,
        )) {
      if (playerNumber == result) {
        result = _nextAlivePlayer(fromNumber: result).number;
      }
    }
    return result;
  }

  int get _consequentDaysWithoutKills {
    final lastKillDay = _log
        .whereType<StateChangeGameLogItem>()
        .map((e) => e.oldState)
        .where(
          (e) =>
              (e is GameStateWithPlayer && e.stage == GameStage.nightLastWords) ||
              (e is GameStateWithIterablePlayers && e.stage == GameStage.dayLastWords),
        )
        .lastOrNull
        ?.day;
    return state.day - (lastKillDay ?? 0);
  }
// endregion
}
