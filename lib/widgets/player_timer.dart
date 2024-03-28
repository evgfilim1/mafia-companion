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
    _maybeVibrate(timer);
  }

  void _maybeVibrate(TimerService timer) {
    final settings = context.read<SettingsModel>();
    final remaining = timer.remainingTime;
    if (settings.vibrationDuration == VibrationDuration.disabled || remaining == null) {
      return;
    }
    if (remaining == Duration.zero) {
      _vibrateOnZeroTimeLeft();
    } else if (remaining <= const Duration(seconds: 5)) {
      Vibration.vibrate(duration: settings.vibrationDuration.milliseconds);
    }
  }

  void _onBlinkTick(Timer blinkTimer, TimerService timer) {
    if (!mounted) {
      blinkTimer.cancel();
      return;
    }
    setState(() {
      if (timer.isPaused || timer.isFinished) {
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
    const animationDuration = Duration(milliseconds: 500);
    final Color? textColor;
    if (remaining == Duration.zero) {
      textColor = Colors.red;
      _textVisible = true;
      _blinkTimer = null;
    } else if (remaining <= const Duration(seconds: 5)) {
      _blinkTimer ??= Timer.periodic(animationDuration, (t) => _onBlinkTick(t, timer));
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
          duration: animationDuration,
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
            ),
            IconButton(
              onPressed: timer.restart,
              icon: const Icon(Icons.restart_alt),
            ),
          ],
        ),
      ],
    );
  }
}
