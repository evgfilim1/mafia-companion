import "package:flutter/foundation.dart";

import "../game/states.dart";
import "countdown.dart";
import "game_controller.dart";
import "settings.dart";

class TimerService with ChangeNotifier {
  Duration? _remainingTime;

  CountdownTimer? _timer;

  final GameController _controller;
  final SettingsModel _settings;

  BaseGameState _prevState;

  TimerService({
    required GameController controller,
    required SettingsModel settings,
  })  : _controller = controller,
        _settings = settings,
        _prevState = controller.state {
    _controller.addListener(_onGameControllerChange);
    restart();
  }

  Duration? get remainingTime => _remainingTime;

  bool get isPaused => _timer?.isPaused ?? false;

  bool get isFinished => _timer?.isFinished ?? true;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.removeListener(_onGameControllerChange);
    super.dispose();
  }

  void pause() {
    if (_timer == null) {
      return;
    }
    _timer?.pause();
    notifyListeners();
  }

  void resume() {
    if (_timer == null) {
      return;
    }
    _timer?.resume();
    notifyListeners();
  }

  void restart({bool paused = false}) {
    _timer?.cancel();
    _timer = null;
    final timeLimit = _getTimeLimit();
    _remainingTime = timeLimit;
    if (timeLimit != null) {
      _initTimer(timeLimit, paused: paused);
    }
    notifyListeners();
  }

  void _onGameControllerChange() {
    if (!_controller.state.hasStateChanged(_prevState)) {
      // No need to update the timer if the state hasn't changed
      return;
    }
    _prevState = _controller.state;
    restart();
  }

  void _initTimer(Duration value, {bool paused = false}) {
    _timer = CountdownTimer(value, _onTimerTick);
    if (paused) {
      _timer!.pause();
    }
  }

  void _onTimerTick(Duration timeLeft) {
    _remainingTime = timeLeft;
    notifyListeners();
  }

  Duration? _getTimeLimit() {
    final gameState = _controller.state;
    var timeLimit = switch (_settings.timerType) {
      TimerType.disabled => null,
      TimerType.strict || TimerType.plus5 => timeLimits[gameState.stage],
      TimerType.extended => timeLimitsExtended[gameState.stage] ?? timeLimits[gameState.stage],
      TimerType.shortened => timeLimitsShortened[gameState.stage] ?? timeLimits[gameState.stage],
    };
    if (_settings.timerType == TimerType.plus5 && timeLimit != null) {
      timeLimit += const Duration(seconds: 5);
    }
    if (gameState is GameStateSpeaking && gameState.hasHalfTime && timeLimit != null) {
      timeLimit ~/= 2;
    }
    return timeLimit;
  }
}
