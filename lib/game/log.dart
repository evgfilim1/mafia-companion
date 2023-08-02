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
  final BaseGameState oldState;

  const StateChangeGameLogItem({
    required this.oldState,
  });
}

@immutable
class PlayerWarnedGameLogItem extends BaseGameLogItem {
  final int playerNumber;

  const PlayerWarnedGameLogItem({
    required this.playerNumber,
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

  void removeLastWhere(bool Function(BaseGameLogItem item) test) {
    final i = _log.lastIndexWhere(test);
    if (i != -1) {
      _log.removeAt(i);
    }
  }
}
