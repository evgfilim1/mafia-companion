import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'game/player.dart';
import 'game/states.dart';

extension RandomItem<T> on List<T> {
  T get randomItem => this[Random().nextInt(length)];
}

extension MinMaxItemComparable<T extends Comparable> on Iterable<T> {
  static int _compare<T extends Comparable>(T a, T b) => a.compareTo(b);

  T max([Comparator<T>? comparator]) =>
      reduce((value, element) => (comparator ?? _compare)(value, element) > 0 ? value : element);

  T min([Comparator<T>? comparator]) =>
      reduce((value, element) => (comparator ?? _compare)(value, element) < 0 ? value : element);
}

extension MinMaxItem<T> on Iterable<T> {
  T max(Comparator<T> comparator) =>
      reduce((value, element) => comparator(value, element) > 0 ? value : element);

  T min(Comparator<T> comparator) =>
      reduce((value, element) => comparator(value, element) < 0 ? value : element);
}

extension ToUnmodifiableList<T> on Iterable<T> {
  List<T> toUnmodifiableList() => List<T>.unmodifiable(this);
}

extension FirstWhereOrNull<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    try {
      return firstWhere(test);
    } on StateError {
      return null;
    }
  }
}

extension Sum on Iterable<int> {
  int get sum => fold(0, (value, element) => value + element);
}

typedef CountdownTimerCallback = void Function(Duration timeLeft);

typedef ConverterFunction<T, R> = R Function(T value);

/// A simple countdown timer that calls [callback] every second until [duration]
/// is reached.
class CountdownTimer {
  Timer? _impl;
  Duration _timeLeft;
  final CountdownTimerCallback _callback;

  /// Creates a new [CountdownTimer] that will call [callback] every second until
  /// [duration] is reached.
  CountdownTimer(Duration duration, CountdownTimerCallback callback)
      : _timeLeft = duration,
        _callback = callback {
    _runTimer();
  }

  /// The time left until the timer is finished.
  Duration get timeLeft => _timeLeft;

  /// Whether the timer is finished.
  bool get isFinished => _timeLeft == Duration.zero;

  /// Whether the timer is paused.
  bool get isPaused => _impl?.isActive != true;

  /// Pauses the timer.
  void pause() => _impl?.cancel();

  /// Resumes the timer.
  void resume() => _runTimer();

  /// Cancels and resets the countdown timer to zero.
  void cancel() {
    _impl?.cancel();
    _timeLeft = Duration.zero;
  }

  void _runTimer() {
    if (_timeLeft == Duration.zero) {
      return;
    }
    if (_impl?.isActive != true) {
      _impl?.cancel();
    }
    _callback(_timeLeft);
    _impl = Timer.periodic(const Duration(seconds: 1), (timer) {
      _timeLeft -= const Duration(seconds: 1);
      _callback(_timeLeft);
      if (_timeLeft == Duration.zero) {
        _impl?.cancel();
      }
    });
  }
}

void showSnackBar(BuildContext context, SnackBar snackBar, {bool dismissPrevious = true}) {
  final messenger = ScaffoldMessenger.of(context);
  if (dismissPrevious) {
    messenger.hideCurrentSnackBar();
  }
  messenger.showSnackBar(snackBar);
}

/// Shows a simple dialog with a list of [items] and returns the selected item.
///
/// [itemToString] is used to convert the item to a string.
///
/// [selectedIndex] is the index of the item that should be selected by default.
/// If [selectedIndex] is null, no item will be selected, thus no checkmark will
/// be shown.
///
/// Returns the selected item or null if the dialog was dismissed.
Future<T?> showChoiceDialog<T>({
  required BuildContext context,
  required List<T> items,
  ConverterFunction<T, String>? itemToString,
  required Widget title,
  required int? selectedIndex,
}) async {
  return showDialog<T>(
    context: context,
    builder: (context) => SimpleDialog(
      title: title,
      children: [
        for (var i = 0; i < items.length; i++)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, items[i]),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(itemToString?.call(items[i]) ?? items[i].toString()),
                if (i == selectedIndex) const Icon(Icons.check),
              ],
            ),
          ),
      ],
    ),
  );
}

extension PlayerRolePrettyString on PlayerRole {
  String get prettyName {
    switch (this) {
      case PlayerRole.citizen:
        return "Мирный житель";
      case PlayerRole.mafia:
        return "Мафия";
      case PlayerRole.don:
        return "Дон";
      case PlayerRole.sheriff:
        return "Шериф";
    }
  }
}

extension GameStatePrettyString on BaseGameState {
  String get prettyName {
    switch (this) {
      case GameState(stage: GameStage.prepare):
        return "Ожидание игроков...";
      case GameStateWithPlayers(stage: GameStage.night0):
        return "Первая ночь";
      case GameStateWithPlayer(stage: GameStage.night0SheriffCheck):
        return "Шериф осматривает стол";
      case GameStateSpeaking(stage: GameStage.speaking, player: final player):
        return "Речь игрока ${player.number}";
      case GameStateWithPlayers(stage: GameStage.preVoting):
        return "Голосование";
      case GameStateVoting(stage: GameStage.voting, player: final player):
        return "Голосование против игрока ${player.number}";
      case GameStateWithCurrentPlayer(stage: GameStage.excuse, player: final player):
        return "Повторная речь игрока ${player.number}";
      case GameStateWithPlayers(stage: GameStage.preFinalVoting):
        return "Повторное голосование";
      case GameStateVoting(stage: GameStage.finalVoting, player: final player):
        return "Повторное голосование против игрока ${player.number}";
      case GameStateDropTableVoting():
        return "Голосование за подъём стола";
      case GameStateWithCurrentPlayer(stage: GameStage.dayLastWords, player: final player):
        return "Последние слова игрока ${player.number}";
      case GameStateNightKill():
        return "Ночь, ход Мафии";
      case GameStateNightCheck(stage: GameStage.nightCheck, player: final player):
        if (player.role == PlayerRole.don) {
          return "Ночь, ход Дона";
        }
        return "Ночь, ход Шерифа";
      case GameStateWithPlayer(stage: GameStage.nightLastWords, player: final player):
        return "Последние слова игрока ${player.number}";
      case GameStateFinish():
        return "Игра окончена";
      default:
        throw AssertionError("Unknown game state: $this");
    }
  }
}

extension IsAnyOf<T> on T {
  bool isAnyOf(Iterable<T> values) => values.contains(this);
}

void showSimpleDialog({
  required BuildContext context,
  required Widget title,
  required Widget content,
  List<Widget> actions = const [],
}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: title,
      content: content,
      actions: [
        ...actions,
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("ОК"),
        ),
      ],
    ),
  );
}
