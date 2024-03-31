import "dart:async";

import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:vibration/vibration.dart";

import "../utils/extensions.dart";
import "../utils/settings.dart";
import "../utils/timer.dart";

class PlayerTimer extends StatefulWidget {
  const PlayerTimer({
    super.key,
  });

  @override
  State<PlayerTimer> createState() => _PlayerTimerState();
}

class _PlayerTimerState extends State<PlayerTimer> {
  static const _blinkAfter = Duration(seconds: 5);
  static const _blinkDuration = Duration(milliseconds: 500);

  var _textVisible = true;
  Timer? _blinkTimer;
  late TimerService _timerService;

  @override
  void initState() {
    super.initState();
    _timerService = context.read<TimerService>()..addListener(_onTimerChange);
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _timerService.removeListener(_onTimerChange);
    super.dispose();
  }

  void _onTimerChange() {
    if (!mounted) {
      return;
    }
    final timer = context.read<TimerService>();
    _maybeStartBlinking(timer);
    _maybeVibrate(timer);
  }

  void _maybeStartBlinking(TimerService timer) {
    final remaining = timer.remainingTime;
    if (remaining == null || remaining > _blinkAfter || remaining == Duration.zero) {
      _blinkTimer?.cancel();
      if (!_textVisible) {
        setState(() => _textVisible = true);
      }
      return;
    }
    if (_blinkTimer == null || !(_blinkTimer?.isActive ?? false)) {
      _blinkTimer = Timer.periodic(_blinkDuration, (t) => _onBlinkTick(t, timer));
    }
  }

  void _maybeVibrate(TimerService timer) {
    final settings = context.read<SettingsModel>();
    final remaining = timer.remainingTime;
    if (settings.vibrationDuration == VibrationDuration.disabled || remaining == null) {
      return;
    }
    if (remaining == Duration.zero) {
      _vibrateOnZeroTimeLeft();
    } else if (remaining <= _blinkAfter) {
      Vibration.vibrate(duration: settings.vibrationDuration.milliseconds);
    }
  }

  void _onBlinkTick(Timer blinkTimer, TimerService timer) {
    if (!mounted) {
      blinkTimer.cancel();
      return;
    }
    setState(() {
      if (timer.isFinished ||
          timer.remainingTime == null ||
          timer.remainingTime! > _blinkAfter + const Duration(seconds: 1) ||
          timer.remainingTime! == Duration.zero) {
        blinkTimer.cancel();
        _textVisible = true;
      } else {
        _textVisible = !_textVisible;
      }
    });
  }

  Future<void> _vibrateOnZeroTimeLeft() async {
    const vibrateMs = 100;
    const pauseMs = 200;
    await Vibration.vibrate(duration: vibrateMs);
    await Future<void>.delayed(const Duration(milliseconds: vibrateMs + pauseMs));
    await Vibration.vibrate(duration: vibrateMs);
  }

  @override
  Widget build(BuildContext context) {
    final timer = context.watch<TimerService>();
    final remaining = timer.remainingTime;
    if (remaining == null) {
      return const SizedBox.shrink();
    }
    final Color? textColor;
    if (remaining <= _blinkAfter) {
      textColor = Colors.red;
    } else if (remaining <= const Duration(seconds: 10)) {
      textColor = Colors.yellow;
    } else {
      textColor = null;
    }
    final VoidCallback? buttonCallback;
    if (remaining == Duration.zero) {
      buttonCallback = null;
    } else if (timer.isPaused) {
      buttonCallback = timer.resume;
    } else {
      buttonCallback = timer.pause;
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedOpacity(
          curve: Curves.easeInOut,
          opacity: _textVisible ? 1 : 0.2,
          duration: _blinkDuration,
          child: Text(
            remaining.toMinSecString(),
            style: TextStyle(fontSize: 20, color: textColor),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: buttonCallback,
              icon: Icon(timer.isPaused ? Icons.play_arrow : Icons.pause),
              tooltip: timer.isPaused ? "Продолжить" : "Пауза",
            ),
            IconButton(
              onPressed: timer.restart,
              icon: const Icon(Icons.restart_alt),
              tooltip: "Перезапустить",
            ),
          ],
        ),
      ],
    );
  }
}
