import "dart:collection";

import "package:flutter/foundation.dart";

import "player.dart";
import "states.dart";

@immutable
abstract class BaseGameLogItem {
  const BaseGameLogItem();
}

@immutable
class StateChangeGameLogItem extends BaseGameLogItem {
  final BaseGameState? oldState;
  final BaseGameState newState;

  const StateChangeGameLogItem({
    required this.oldState,
    required this.newState,
  });
}

@immutable
class PlayerCheckedGameLogItem extends BaseGameLogItem {
  final int playerNumber;
  final PlayerRole checkedByRole;

  const PlayerCheckedGameLogItem({
    required this.playerNumber,
    required this.checkedByRole,
  });
}

class GameLog with IterableMixin<BaseGameLogItem> {
  final _log = <BaseGameLogItem>[];

  GameLog();

  @override
  Iterator<BaseGameLogItem> get iterator => _log.iterator;

  @override
  int get length => _log.length;

  @override
  BaseGameLogItem get last => _log.last;

  void add(BaseGameLogItem item) => _log.add(item);

  BaseGameLogItem pop() => _log.removeLast();

  /// Removes all items from the end of the log until [test] returns true.
  /// If [test] never returns true, nothing will be removed.
  ///
  /// Example:
  /// ```dart
  /// final log = GameLog();
  /// log.add(1);
  /// log.add(2);
  /// log.add(3);
  /// log.removeLastUntil((item) => item == 2);
  /// print(log); // [1, 2]
  /// ```
  void removeLastUntil(bool Function(BaseGameLogItem item) test) {
    final i = _log.lastIndexWhere(test);
    if (i != -1) {
      _log.removeRange(i + 1, _log.length);
    }
  }

  T lastWhereType<T extends BaseGameLogItem>() => lastWhere((item) => item is T) as T;
}
