import "../game/log.dart";
import "../game/states.dart";
import "extensions.dart";

extension StateChangeUtils on Iterable<StateChangeGameLogItem> {
  Iterable<(BaseGameState?, BaseGameState)> _iterWithPrevious() sync* {
    for (final (previous, item) in withPreviousElement) {
      yield (previous?.newState, item.newState);
    }
  }

  Iterable<BaseGameState> _iter() sync* {
    for (final item in this) {
      yield item.newState;
    }
  }

  int? getLastDayPlayerLeft() {
    int? result;
    for (final (previous, item) in _iterWithPrevious()) {
      if (previous != null &&
          item.players.countWhere((e) => e.isAlive) !=
              previous.players.countWhere((e) => e.isAlive)) {
        result = previous.day;
      }
    }
    return result;
  }

  int? getPreviousFirstSpeakingPlayerNumber({required int currentDay}) {
    for (final item in _iter()) {
      if (item is GameStateSpeaking && item.day == currentDay - 1) {
        return item.currentPlayerNumber;
      }
    }
    return null;
  }

  Set<int> getAlreadySpokePlayers({required int currentDay}) {
    final result = <int>{};
    for (final (previous, item) in _iterWithPrevious()) {
      if (previous != null && item.hasStateChanged(previous) && item is GameStateSpeaking &&
          item.day == currentDay) {
        result.add(item.currentPlayerNumber);
      }
    }
    return result;
  }

  int? getLastDayKilledPlayerNumber() {
    int? result;
    for (final item in _iter()) {
      if (item is GameStateNightKill) {
        result = item.thisNightKilledPlayerNumber;
      }
    }
    return result;
  }

  BaseGameState? getPreviousState() {
    BaseGameState? result;
    for (final (previous, _) in _iterWithPrevious()) {
      result = previous;
    }
    return result;
  }

  GameStateBestTurn? getBestTurn() {
    GameStateBestTurn? result;
    for (final item in _iter()) {
      if (item is GameStateBestTurn) {
        result = item;
      }
    }
    return result;
  }
}
