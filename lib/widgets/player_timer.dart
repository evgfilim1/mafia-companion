import 'dart:async';

import 'package:flutter/material.dart';

import '../utils.dart';

class PlayerTimer extends StatefulWidget {
  final Duration duration;
  final ValueChanged<Duration>? onTimerTick;
  final Map<Duration, TextStyle> thresholds;

  const PlayerTimer({
    super.key,
    required this.duration,
    this.onTimerTick,
    this.thresholds = const {},
  });

  @override
  State<PlayerTimer> createState() => _PlayerTimerState();
}

class _PlayerTimerState extends State<PlayerTimer> {
  CountdownTimer? _timer;
  Duration? _timeLeft;
  var _textVisible = true;
  Timer? _blinkTimer;

  @override
  void initState() {
    super.initState();
    _initTimer();
  }

  void _initTimer([Duration? value]) {
    if (_timer?.isPaused != true || _timer?.isFinished != true) {
      _timer?.cancel();
    }
    _blinkTimer?.cancel();
    _blinkTimer = null;
    _timer = CountdownTimer(
      value ?? widget.duration,
      (timeLeft) => setState(() {
        _timeLeft = timeLeft;
        widget.onTimerTick?.call(timeLeft);
      }),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeLeft = _timeLeft;
    if (timeLeft == null) {
      return const SizedBox.shrink();
    }
    final Color? textColor;
    if (timeLeft <= const Duration(seconds: 5)) {
      _blinkTimer ??= Timer.periodic(const Duration(milliseconds: 500), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        final bool newVisibility;
        if (_timer?.isPaused != false || _timer?.isFinished != false) {
          timer.cancel();
          newVisibility = true;
        } else {
          newVisibility = !_textVisible;
        }
        setState(() => _textVisible = newVisibility);
      });
      textColor = Colors.red;
    } else if (timeLeft <= const Duration(seconds: 10)) {
      textColor = Colors.yellow;
    } else {
      textColor = null;
    }
    final VoidCallback? buttonCallback;
    if (timeLeft == Duration.zero) {
      buttonCallback = null;
    } else if (_timer?.isPaused == true) {
      buttonCallback = () => setState(() => _timer?.resume());
    } else {
      buttonCallback = () => setState(() => _timer?.pause());
    }
    final text = "${timeLeft.inMinutes.toString().padLeft(2, "0")}:"
        "${(timeLeft.inSeconds % 60).toString().padLeft(2, "0")}";
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedOpacity(
          curve: Curves.easeInOut,
          opacity: _textVisible ? 1 : 0.2,
          duration: const Duration(milliseconds: 500),
          child: Text(text, style: TextStyle(fontSize: 20, color: textColor)),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: buttonCallback,
              icon: Icon(_timer?.isPaused == true ? Icons.play_arrow : Icons.pause),
            ),
            IconButton(
              onPressed: _initTimer,
              icon: const Icon(Icons.restart_alt),
            ),
          ],
        ),
      ],
    );
  }
}
