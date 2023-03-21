import 'package:flutter/material.dart';

class Counter extends StatelessWidget {
  final int value;
  final int? min;
  final int? max;
  final ValueChanged<int> onValueChanged;

  const Counter({
    super.key,
    this.min,
    this.max,
    required this.onValueChanged,
    int? value,
  })  : assert((min ?? double.negativeInfinity) < (max ?? double.infinity)),
        value = (value ?? min ?? 0);

  VoidCallback? _onButtonPressedFactory({required bool increment}) {
    final delta = increment ? 1 : -1;
    if (increment && max != null && value >= max!) {
      return null;
    }
    if (!increment && min != null && value <= min!) {
      return null;
    }
    return () => onValueChanged(value + delta);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: _onButtonPressedFactory(increment: false),
          icon: const Icon(Icons.remove),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text("$value", style: const TextStyle(fontSize: 28)),
        ),
        IconButton(
          onPressed: _onButtonPressedFactory(increment: true),
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}
