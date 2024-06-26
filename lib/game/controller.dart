import "dart:collection";

import "../utils/extensions.dart";
import "../utils/log.dart";
import "../utils/state_change_utils.dart";
import "config.dart";
import "log.dart";
import "player.dart";
import "players_view.dart";
import "states.dart";

/// Game controller. Manages game state and players. Shouldn't know about UI.
/// To start a new game, create a new instance of [Game].
class Game {
  static final _logger = Logger("Game");

  final GameLog _log;
  final List<Player> _players;
  final GameConfig _config;

  /// Creates a new game with given players and game [config].
  factory Game.withPlayers(
    List<Player> players, {
    GameConfig? config,
  }) {
    final needsSorting = players.indexed.any((r) => r.$2.number != r.$1 + 1);
    final List<Player> sortedPlayers;
    if (needsSorting) {
      sortedPlayers = List.of(players)..sort((a, b) => a.number.compareTo(b.number));
    } else {
      sortedPlayers = players;
    }
    if (sortedPlayers.length != 10) {
      _logger.warning("Players count is not 10, unexpected things may happen");
    }
    final log = GameLog()
      ..add(
        StateChangeGameLogItem(
          newState: GameStatePrepare(
            playerStates: List<PlayerState>.generate(
              players.length,
              (_) => const PlayerState(),
              growable: false,
            ).toUnmodifiableList(),
          ),
        ),
      );
    return Game._(log, players, config ?? const GameConfig());
  }

  Game._(this._log, this._players, this._config);

  /// Returns current game state.
  BaseGameState get state => _log.lastWhereType<StateChangeGameLogItem>().newState;

  /// Returns game log.
  Iterable<BaseGameLogItem> get log => _log;

  /// Returns convenient players view.
  PlayersView get players => PlayersView(
        players: _players
            .zip(state.playerStates)
            .map((e) => e.$1.withState(state: e.$2))
            .toUnmodifiableList(),
      );

  /// Assumes team that will win if game ends right now. Returns `null` if the game can't end now.
  RoleTeam? get winTeamAssumption {
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
      if (player.state.isAlive) {
        if (player.role.team == RoleTeam.mafia) {
          aliveMafia--;
        } else {
          aliveCitizens--;
        }
      }
    }
    if (state.stage.isAnyOf([GameStage.nightLastWords, GameStage.dayLastWords])) {
      var stop = false;
      for (final event in _log.reversed) {
        if (stop) {
          break;
        }
        switch (event) {
          case StateChangeGameLogItem(:final newState):
            if (!newState.stage.isAnyOf([GameStage.nightLastWords, GameStage.dayLastWords])) {
              stop = true;
            }
          case PlayerKickedGameLogItem(:final playerNumber):
            final player = players.getByNumber(playerNumber);
            if (player.role.team == RoleTeam.mafia) {
              aliveMafia++;
            } else {
              aliveCitizens++;
            }
          default:
            continue;
        }
      }
    }
    if (aliveMafia == 0) {
      return RoleTeam.citizen;
    }
    if (aliveCitizens <= aliveMafia) {
      return RoleTeam.mafia;
    }
    return null;
  }

  /// Checks if the game is over.
  bool get isGameOver => state.stage == GameStage.finish;

  /// Checks if the game is running.
  bool get isActive => !state.stage.isAnyOf([GameStage.prepare, GameStage.finish]);

  int get totalVotes {
    if (state case GameStateVoting(votes: final votes)) {
      return votes.values.nonNulls.sum;
    }
    throw StateError("Can't get total votes in state ${state.stage}");
  }

  /// Assumes next game state according to game internal state, and returns it.
  /// Doesn't change internal state. May throw exceptions if game internal state is inconsistent.
  BaseGameState? get nextStateAssumption {
    final otherTeamWin = _log.whereType<PlayerKickedGameLogItem>().where((e) => e.isOtherTeamWin);
    if (otherTeamWin.isNotEmpty) {
      return GameStateFinish(
        day: state.day,
        winner: players.getByNumber(otherTeamWin.last.playerNumber).role.team.other,
        playerStates: state.playerStates,
      );
    }
    if (!state.stage.isAnyOf([GameStage.nightLastWords, GameStage.dayLastWords]) &&
        winTeamAssumption != null) {
      if (state.stage == GameStage.finish) {
        return null;
      }
      return GameStateFinish(
        day: state.day,
        playerStates: state.playerStates,
        winner: winTeamAssumption,
      );
    }
    switch (state) {
      case GameStatePrepare():
        return GameStateWithPlayers(
          stage: GameStage.firstNight,
          day: 1,
          playerStates: state.playerStates,
          playerNumbers: players.mafiaTeam.map((player) => player.number).toUnmodifiableList(),
        );
      case GameStateWithPlayers(stage: GameStage.firstNight):
        return GameStateWithPlayer(
          stage: GameStage.firstNightWakeUps,
          day: 1,
          playerStates: state.playerStates,
          currentPlayerNumber: players.sheriff.number,
        );
      case GameStateWithPlayer(stage: GameStage.firstNightWakeUps):
        return GameStateNightRest(playerStates: state.playerStates);
      case GameStateNightRest():
        final next = _nextAlivePlayer(fromNumber: 0);
        assert(next.state.isAlive, "Next player must be alive");
        return GameStateSpeaking(
          currentPlayerNumber: next.number,
          day: state.day,
          playerStates: state.playerStates,
          accusations: LinkedHashMap(),
          canOnlyAccuse: _canOnlyAccuse(next),
          hasHalfTime: _hasHalfTime(next),
        );
      case GameStateSpeaking(accusations: final accusations, currentPlayerNumber: final pn):
        final alreadySpoke =
            _log.whereType<StateChangeGameLogItem>().getAlreadySpokePlayers(currentDay: state.day);
        final shouldSpeakCount = players.aliveCount +
            _log
                .whereType<PlayerKickedGameLogItem>()
                .where((e) => e.day == state.day && alreadySpoke.contains(e.playerNumber))
                .length;
        if (alreadySpoke.length == shouldSpeakCount) {
          final kickedPlayers = _getKickedPlayers();
          final lastDayKickedPlayers = _getKickedPlayers(daysBack: 1);
          final lastDayVotedOutPlayers = (_log
                  .whereType<StateChangeGameLogItem>()
                  .where(
                    (e) =>
                        e.newState.day == state.day - 1 &&
                        e.newState.stage == GameStage.dayLastWords,
                  )
                  .firstOrNull
                  ?.newState as GameStateWithIterablePlayers?)
              ?.playerNumbers
              .toSet();
          final skipVoting = state.day == 1 && accusations.length < 2 ||
              accusations.isEmpty ||
              kickedPlayers.length == 1 && kickedPlayers.single != _thisNightKilledPlayer ||
              lastDayVotedOutPlayers != null &&
                  lastDayKickedPlayers.difference(lastDayVotedOutPlayers).isNotEmpty;
          if (skipVoting) {
            return GameStateNightKill(
              day: state.day + 1,
              playerStates: state.playerStates,
              thisNightKilledPlayerNumber: null,
            );
          }
          return GameStateWithPlayers(
            stage: GameStage.preVoting,
            day: state.day,
            playerStates: state.playerStates,
            playerNumbers: accusations.values.toUnmodifiableList(),
          );
        }
        final next = _nextAlivePlayer(fromNumber: pn);
        assert(next.state.isAlive, "Next player must be alive");
        return GameStateSpeaking(
          currentPlayerNumber: next.number,
          day: state.day,
          playerStates: state.playerStates,
          accusations: LinkedHashMap.of(accusations),
          canOnlyAccuse: _canOnlyAccuse(next),
          hasHalfTime: _hasHalfTime(next),
        );
      case GameStateWithPlayers(
          stage: GameStage.preVoting || GameStage.preExcuse || GameStage.preFinalVoting,
          playerNumbers: final pns,
        ):
        final kickedPlayers = _getKickedPlayers();
        final skipVoting =
            kickedPlayers.length == 1 && kickedPlayers.single != _thisNightKilledPlayer ||
                kickedPlayers.length > 1;
        if (skipVoting) {
          return GameStateNightKill(
            day: state.day + 1,
            playerStates: state.playerStates,
            thisNightKilledPlayerNumber: null,
          );
        }
        if (pns.length == 1) {
          return GameStateWithIterablePlayers(
            stage: GameStage.dayLastWords,
            day: state.day,
            playerStates: state.playerStates,
            playerNumbers: pns,
            currentPlayerIndex: 0,
          );
        }
        if (state.stage == GameStage.preExcuse) {
          return GameStateWithIterablePlayers(
            stage: GameStage.excuse,
            day: state.day,
            playerStates: state.playerStates,
            playerNumbers: pns,
            currentPlayerIndex: 0,
          );
        }
        return GameStateVoting(
          stage: state.stage == GameStage.preVoting ? GameStage.voting : GameStage.finalVoting,
          day: state.day,
          playerStates: state.playerStates,
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
        // TODO: refactor (maybe?)
        final kickedPlayers = _getKickedPlayers();
        final skipVoting =
            kickedPlayers.length == 1 && kickedPlayers.single != _thisNightKilledPlayer ||
                kickedPlayers.length > 1;
        if (skipVoting) {
          return GameStateNightKill(
            day: state.day + 1,
            playerStates: state.playerStates,
            thisNightKilledPlayerNumber: null,
          );
        }
        int? nextPlayerNumber;
        for (final p in votes.keys) {
          if (votes[p] == null && p != pn) {
            nextPlayerNumber = p;
            break;
          }
        }
        if (nextPlayerNumber != null) {
          final newVotes = LinkedHashMap.of(votes)..addAll({pn: pv ?? 0});
          final int? currentPlayerVotes;
          if (nextPlayerNumber == votes.keys.last) {
            currentPlayerVotes = players.aliveCount - newVotes.values.nonNulls.sum;
          } else {
            currentPlayerVotes = null;
          }
          if (!_config.alwaysContinueVoting && maxVotesPlayers == null ||
              _config.alwaysContinueVoting) {
            return GameStateVoting(
              stage: state.stage,
              day: state.day,
              playerStates: state.playerStates,
              currentPlayerNumber: nextPlayerNumber,
              votes: newVotes,
              currentPlayerVotes: currentPlayerVotes,
            );
          }
        }
        if (maxVotesPlayers == null) {
          throw AssertionError();
        }
        if (maxVotesPlayers.length == 1) {
          return GameStateWithIterablePlayers(
            stage: GameStage.dayLastWords,
            day: state.day,
            playerStates: state.playerStates,
            playerNumbers: maxVotesPlayers,
            currentPlayerIndex: 0,
          );
        }
        if (state.stage == GameStage.finalVoting && maxVotesPlayers.length == votes.length) {
          if (maxVotesPlayers.length == players.aliveCount) {
            // Rule 7.8
            return GameStateNightKill(
              day: state.day + 1,
              playerStates: state.playerStates,
              thisNightKilledPlayerNumber: null,
            );
          }
          return GameStateKnockoutVoting(
            day: state.day,
            playerStates: state.playerStates,
            playerNumbers: maxVotesPlayers,
            votes: 0,
          );
        }
        return GameStateWithPlayers(
          stage: GameStage.preExcuse,
          day: state.day,
          playerStates: state.playerStates,
          playerNumbers: maxVotesPlayers,
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
            playerStates: state.playerStates,
            playerNumbers: pns,
          );
        }
        return GameStateWithIterablePlayers(
          stage: GameStage.excuse,
          day: state.day,
          playerStates: state.playerStates,
          playerNumbers: pns,
          currentPlayerIndex: i + 1,
        );
      case GameStateKnockoutVoting(votes: final votes, playerNumbers: final pns):
        if (votes <= players.aliveCount ~/ 2) {
          return GameStateNightKill(
            day: state.day + 1,
            playerStates: state.playerStates,
            thisNightKilledPlayerNumber: null,
          );
        }
        return GameStateWithIterablePlayers(
          stage: GameStage.dayLastWords,
          day: state.day,
          playerStates: state.playerStates,
          playerNumbers: pns,
          currentPlayerIndex: 0,
        );
      case GameStateWithIterablePlayers(
          stage: GameStage.dayLastWords,
          playerNumbers: final pns,
          currentPlayerIndex: final i,
        ):
        final newPlayers = List.of(state.playerStates);
        newPlayers[pns[i] - 1] = newPlayers[pns[i] - 1].copyWith(isAlive: false);
        if (i == pns.length - 1) {
          final wta = winTeamAssumption;
          if (wta != null) {
            return GameStateFinish(
              day: state.day,
              winner: wta,
              playerStates: newPlayers,
            );
          }
          return GameStateNightKill(
            day: state.day + 1,
            playerStates: newPlayers,
            thisNightKilledPlayerNumber: null,
          );
        }
        return GameStateWithIterablePlayers(
          stage: GameStage.dayLastWords,
          day: state.day,
          playerStates: newPlayers,
          playerNumbers: pns,
          currentPlayerIndex: i + 1,
        );
      case GameStateNightKill():
        final don = players.don;
        return GameStateNightCheck(
          day: state.day,
          playerStates: state.playerStates,
          activePlayerNumber: don.number,
          activePlayerTeam: don.role.team,
        );
      case GameStateNightCheck(:final activePlayerTeam):
        if (activePlayerTeam == RoleTeam.mafia) {
          final sheriff = players.sheriff;
          return GameStateNightCheck(
            day: state.day,
            playerStates: state.playerStates,
            activePlayerNumber: sheriff.number,
            activePlayerTeam: sheriff.role.team,
          );
        }
        final killedPlayerNumber =
            _log.whereType<StateChangeGameLogItem>().getLastDayKilledPlayerNumber();
        if (killedPlayerNumber != null) {
          if (state.day == 2 && players.aliveCount >= players.count - 1) {
            return GameStateBestTurn(
              day: state.day,
              playerStates: state.playerStates,
              currentPlayerNumber: killedPlayerNumber,
              playerNumbers: const [],
            );
          }
          return GameStateWithPlayer(
            stage: GameStage.nightLastWords,
            day: state.day,
            playerStates: state.playerStates,
            currentPlayerNumber: killedPlayerNumber,
          );
        }
        if (_consequentDaysWithoutDeaths >= 3) {
          return GameStateFinish(
            day: state.day,
            playerStates: state.playerStates,
            winner: null,
          );
        }
        final firstSpeakingPlayer = players.getByNumber(_firstSpeakingPlayerNumber);
        return GameStateSpeaking(
          day: state.day,
          playerStates: state.playerStates,
          currentPlayerNumber: firstSpeakingPlayer.number,
          accusations: LinkedHashMap(),
          canOnlyAccuse: _canOnlyAccuse(firstSpeakingPlayer),
          hasHalfTime: _hasHalfTime(firstSpeakingPlayer),
        );
      case GameStateBestTurn(currentPlayerNumber: final pn):
        return GameStateWithPlayer(
          stage: GameStage.nightLastWords,
          day: state.day,
          playerStates: state.playerStates,
          currentPlayerNumber: pn,
        );
      case GameStateWithPlayer(stage: GameStage.nightLastWords, currentPlayerNumber: final pn):
        final newPlayers = List.of(state.playerStates);
        newPlayers[pn - 1] = newPlayers[pn - 1].copyWith(isAlive: false);
        final wta = winTeamAssumption;
        if (wta != null) {
          return GameStateFinish(
            day: state.day,
            winner: wta,
            playerStates: newPlayers.toUnmodifiableList(),
          );
        }
        final firstSpeakingPlayer = players.getByNumber(_firstSpeakingPlayerNumber);
        return GameStateSpeaking(
          currentPlayerNumber: firstSpeakingPlayer.number,
          day: state.day,
          playerStates: newPlayers.toUnmodifiableList(),
          accusations: LinkedHashMap(),
          canOnlyAccuse: _canOnlyAccuse(firstSpeakingPlayer),
          hasHalfTime: _hasHalfTime(firstSpeakingPlayer),
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
      players.indexed.every((r) => r.$2.number == r.$1 + 1),
      "Players must be sorted by number",
    );
    assert(
      state.playerStates.runtimeType == List<PlayerState>.unmodifiable([]).runtimeType,
      "Players must be unmodifiable",
    );
    _log.add(StateChangeGameLogItem(newState: nextState));
  }

  /// Gets previous game state according to game internal state, and returns it.
  /// Doesn't change internal state. May throw exceptions if game internal state is inconsistent.
  /// Returns `null` if there is no previous state.
  BaseGameState? get previousState => _log.whereType<StateChangeGameLogItem>().getPreviousState();

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
    if (!player.state.isAlive) {
      throw StateError("Can't select dead player");
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
          newState: currentState.copyWith(accusations: newAccusations),
        ),
      );
      return;
    }
    if (currentState case GameStateNightKill(thisNightKilledPlayerNumber: final kn)) {
      _log.add(
        StateChangeGameLogItem(
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
          newState: currentState.copyWith(playerNumbers: playerNumbers.toUnmodifiableList()),
        ),
      );
      return;
    }
    throw StateError("Can't toggle player in state ${state.stage}");
  }

  /// Vote for current player with [count] votes.
  void vote(int count) {
    final currentState = state;
    if (currentState is GameStateKnockoutVoting) {
      _log.add(
        StateChangeGameLogItem(
          newState: currentState.copyWith(votes: count),
        ),
      );
      return;
    }
    if (currentState is GameStateVoting) {
      _log.add(
        StateChangeGameLogItem(
          newState: currentState.copyWith(currentPlayerVotes: count),
        ),
      );
      return;
    }
    throw StateError("Can't vote in state ${state.stage}");
  }

  void warnPlayer(int number) {
    if (!isActive) {
      throw StateError("Can't warn player in state ${state.stage}");
    }
    final newPlayers = List.of(state.playerStates);
    final i = number - 1;
    final warnCount = newPlayers[i].warns;
    final newWarnCount = (newPlayers[i].warns + 1).clamp(1, 4);
    newPlayers[i] = newPlayers[i].copyWith(
      warns: newWarnCount,
      isAlive: newPlayers[i].isAlive && newWarnCount < 4,
      isKicked: newWarnCount == 4,
    );
    _log.add(
      PlayerWarnsChangedGameLogItem(
        day: state.day,
        playerNumber: number,
        oldWarns: warnCount,
        currentWarns: newWarnCount,
      ),
    );
    if (newWarnCount == 4) {
      _log.add(PlayerKickedGameLogItem(day: state.day, playerNumber: number));
    }
    _editPlayers(newPlayers);
  }

  void warnMinusPlayer(int number) {
    if (!isActive) {
      throw StateError("Can't -warn player in state ${state.stage}");
    }
    final newPlayers = List.of(state.playerStates);
    final i = number - 1;
    newPlayers[i] = newPlayers[i].copyWith(warns: (newPlayers[i].warns - 1).clamp(0, 3));
    _log.add(
      PlayerWarnsChangedGameLogItem(
        day: state.day,
        playerNumber: number,
        oldWarns: state.playerStates[i].warns,
        currentWarns: newPlayers[i].warns,
      ),
    );
    _editPlayers(newPlayers);
  }

  void kickPlayer(int number) {
    if (!isActive) {
      throw StateError("Can't kick player in state ${state.stage}");
    }
    final newPlayers = List.of(state.playerStates);
    final i = number - 1;
    newPlayers[i] = newPlayers[i].copyWith(isAlive: false, isKicked: true);
    _log.add(PlayerKickedGameLogItem(day: state.day, playerNumber: number));
    _editPlayers(newPlayers);
  }

  void kickPlayerTeam(int number) {
    if (!isActive) {
      throw StateError("Can't kick player's team in state ${state.stage}");
    }
    final newPlayers = List.of(state.playerStates);
    final i = number - 1;
    newPlayers[i] = newPlayers[i].copyWith(isAlive: false, isKicked: true);
    _log.add(PlayerKickedGameLogItem(day: state.day, playerNumber: number, isOtherTeamWin: true));
    _editPlayers(newPlayers);
  }

  int getPlayerWarnCount(int number) => players.getByNumber(number).state.warns;

  bool checkPlayer(int number) {
    final checkedPlayer = players.getByNumber(number);
    if (state case GameStateNightCheck(activePlayerNumber: final playerNumber)) {
      final activePlayer = players.getByNumber(playerNumber);
      if (!activePlayer.state.isAlive) {
        throw StateError("Active player is not in the game and therefore cannot check players");
      }
      _log.add(
        PlayerCheckedGameLogItem(
          day: state.day,
          playerNumber: number,
          checkedByRole: activePlayer.role,
        ),
      );
      if (activePlayer.role == PlayerRole.don) {
        return checkedPlayer.role == PlayerRole.sheriff;
      }
      if (activePlayer.role == PlayerRole.sheriff) {
        return checkedPlayer.role.team == RoleTeam.mafia;
      }
      throw AssertionError();
    }
    throw StateError("Cannot check player in state ${state.stage}");
  }

  // region Private helpers
  void _editPlayers(List<PlayerState> newPlayers) {
    final currentState = state;
    // This weird thing is needed to make Dart analyzer happy and to be type safe.
    // I could make it prettier like below, but it may lead to runtime errors in future.
    // final newState = (currentState as dynamic).copyWith(playerStates: newPlayers);
    final newState = switch (currentState) {
      GameStatePrepare() => currentState.copyWith(playerStates: newPlayers),
      GameStateNightRest() => currentState.copyWith(playerStates: newPlayers),
      GameStateWithPlayer() => currentState.copyWith(playerStates: newPlayers),
      GameStateSpeaking() => currentState.copyWith(playerStates: newPlayers),
      GameStateVoting() => currentState.copyWith(playerStates: newPlayers),
      GameStateKnockoutVoting() => currentState.copyWith(playerStates: newPlayers),
      GameStateWithPlayers() => currentState.copyWith(playerStates: newPlayers),
      GameStateNightKill() => currentState.copyWith(playerStates: newPlayers),
      GameStateNightCheck() => currentState.copyWith(playerStates: newPlayers),
      GameStateBestTurn() => currentState.copyWith(playerStates: newPlayers),
      GameStateWithIterablePlayers() => currentState.copyWith(playerStates: newPlayers),
      GameStateFinish() => currentState.copyWith(playerStates: newPlayers),
    };
    _log.add(StateChangeGameLogItem(newState: newState));
  }

  PlayerWithState _nextAlivePlayer({required int fromNumber}) {
    for (var i = fromNumber % 10 + 1; i != fromNumber; i = i % 10 + 1) {
      final player = players.getByNumber(i);
      if (player.state.isAlive) {
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
      if (_config.alwaysContinueVoting && newVotes.values.nonNulls.length != newVotes.length) {
        return null;
      }
      final res =
          newVotes.entries.where((e) => e.value == max).map((e) => e.key).toUnmodifiableList();
      assert(res.isNotEmpty, "BUG in votes calculation");
      return res;
    }
    throw StateError("Can't get max votes in state ${state.stage}");
  }

  int get _firstSpeakingPlayerNumber {
    final previousFirstSpeakingPlayer = _log
        .whereType<StateChangeGameLogItem>()
        .getPreviousFirstSpeakingPlayerNumber(currentDay: state.day);
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

  int get _consequentDaysWithoutDeaths {
    final lastDeathDay = _log.whereType<StateChangeGameLogItem>().getLastDayPlayerLeft();
    return state.day - (lastDeathDay ?? 1);
  }

  Set<int> _getKickedPlayers({int daysBack = 0}) => _log
      .whereType<PlayerKickedGameLogItem>()
      .where((e) => e.day == state.day - daysBack)
      .map((e) => e.playerNumber)
      .toSet();

  int? get _thisNightKilledPlayer => (_log
          .whereType<StateChangeGameLogItem>()
          .where(
            (e) => e.newState.day == state.day && e.newState.stage == GameStage.nightLastWords,
          )
          .firstOrNull
          ?.newState as GameStateWithPlayer?)
      ?.currentPlayerNumber;

  bool _hasPlayerBeenMutedForToday(PlayerWithState player) {
    if (player.state.warns != 3) {
      return false;
    }
    var hasSpoke = false;
    var hasThirdWarn = false;
    for (final item in _log.reversed) {
      if (item
          case StateChangeGameLogItem(
                newState: GameStateSpeaking(currentPlayerNumber: final pn, :final day)
              ) ||
              PlayerWarnsChangedGameLogItem(playerNumber: final pn, currentWarns: 3, :final day)) {
        if (day < state.day - 1) {
          break;
        }
        if (pn != player.number) {
          continue;
        }
      }
      switch (item) {
        case StateChangeGameLogItem(newState: GameStateSpeaking(:final canOnlyAccuse)):
          if (canOnlyAccuse) {
            return false;
          }
          if (hasThirdWarn) {
            return true;
          }
          hasSpoke = true;
        case PlayerWarnsChangedGameLogItem(currentWarns: 3):
          hasThirdWarn = true;
        default:
          continue;
      }
    }
    if (!hasThirdWarn) {
      return false;
    }
    if (!hasSpoke) {
      return true;
    }
    throw AssertionError("BUG in _hasPlayerBeenMutedForToday");
  }

  bool _canOnlyAccuse(PlayerWithState player) =>
      !state.stage.isAnyOf([GameStage.excuse, GameStage.voting]) &&
      players.aliveCount > 4 &&
      _hasPlayerBeenMutedForToday(player);

  bool _hasHalfTime(PlayerWithState player) =>
      (players.aliveCount <= 4 ||
          players.aliveCount == 5 && state.stage == GameStage.nightLastWords) &&
      _hasPlayerBeenMutedForToday(player);
// endregion
}
