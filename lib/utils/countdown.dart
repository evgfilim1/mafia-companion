import "dart:async";

typedef CountdownTimerCallback = void Function(Duration timeLeft);

/// A simple countdown timer that calls callback every second until the duration is reached.
class CountdownTimer {
  Timer? _impl;
  Duration _timeLeft;
  final CountdownTimerCallback _callback;

  /// Creates a new [CountdownTimer] that will call [callback] every second until [duration]
  /// is reached.
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
