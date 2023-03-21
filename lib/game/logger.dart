import 'dart:collection';

import 'controller.dart';
import 'player.dart';

enum Event {
  accused,
  warned,
  kicked,
  killedDay,
  killedNight,
  donChecked,
  commissarChecked,
}

class PlayerEvent {
  final Event event;
  final Player? source; // null if event is not caused by player
  final Player target;

  const PlayerEvent(
    this.event, {
    this.source,
    required this.target,
  });
}

class GameLogger with IterableMixin<PlayerEvent> {
  final _events = <PlayerEvent>[];

  void logEvent(Event event, {Player? source, required Player target}) {
    _events.add(PlayerEvent(event, source: source, target: target));
  }

  @override
  Iterator<PlayerEvent> get iterator => _events.iterator;
}
