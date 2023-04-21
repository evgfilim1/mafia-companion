import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'game/player.dart';
import 'game/states.dart';

extension RandomItem<T> on List<T> {
  T get randomItem => this[Random().nextInt(length)];
}

extension MinMaxItem<T extends Comparable> on Iterable<T> {
  T get maxItem => reduce((value, element) => value.compareTo(element) > 0 ? value : element);

  T get minItem => reduce((value, element) => value.compareTo(element) < 0 ? value : element);
}

extension ToUnmodifiableList<T> on Iterable<T> {
  List<T> toUnmodifiableList() => List.unmodifiable(this);
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

extension PlayerRolePrettyString on PlayerRole {
  String get prettyName {
    switch (this) {
      case PlayerRole.citizen:
        return "Мирный житель";
      case PlayerRole.mafia:
        return "Мафия";
      case PlayerRole.don:
        return "Дон";
      case PlayerRole.commissar:
        return "Комиссар";
    }
  }
}

extension GameStatePrettyString on GameStateWithPlayer {
  String get prettyName {
    switch (state) {
      case GameState.prepare:
        return "Ожидание игроков...";
      case GameState.night0:
        return "Первая ночь";
      case GameState.nightVibeCheck:
        return "${player!.role.prettyName} обозначает себя";
      case GameState.day:
        return "Начало дня";
      case GameState.speaking:
        return "Речь игрока ${player!.number}";
      case GameState.voting:
        return "Голосование против игрока ${player!.number}";
      case GameState.excuse:
        return "Повторная речь игрока ${player!.number}";
      case GameState.finalVoting:
        return "Повторное голосование против игрока ${player!.number}";
      case GameState.dropTableVoting:
        return "Убить всех?";
      case GameState.dayLastWords:
        return "Последние слова игрока ${player!.number}";
      case GameState.nightKill:
        return "Ночь, ход Мафии";
      case GameState.nightCheck:
        return "Ночь, ход ${player!.role.prettyName}а";
      case GameState.nightLastWords:
        return "Последние слова игрока ${player!.number}";
      case GameState.finish:
        return "Игра окончена";
    }
  }
}

extension IsAnyOf on Object {
  bool isAnyOf(Iterable values) => values.contains(this);
}

void showSimpleDialog({
  required BuildContext context,
  required Widget title,
  required Widget content,
}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: title,
      content: content,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("ОК"),
        ),
      ],
    ),
  );
}
