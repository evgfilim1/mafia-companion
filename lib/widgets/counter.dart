import "package:flutter/material.dart";

class Counter extends StatefulWidget {
  final int initialValue;
  final int min;
  final int max;
  final ValueChanged<int>? onValueChanged;

  const Counter({
    super.key,
    required this.min,
    required this.max,
    this.onValueChanged,
    required this.initialValue,
  }) : assert(min <= initialValue && initialValue <= max, "value must be in range [min, max]");

  @override
  State<Counter> createState() => _CounterState();
}

class _CounterState extends State<Counter> {
  late int _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  VoidCallback? _onButtonPressedFactory({required bool increment}) {
    final delta = increment ? 1 : -1;
    if (increment && _value >= widget.max) {
      return null;
    }
    if (!increment && _value <= widget.min) {
      return null;
    }
    final newValue = _value + delta;
    return () => setState(() {
      _value = newValue;
      widget.onValueChanged?.call(newValue);
    });
  }

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: _onButtonPressedFactory(increment: false),
            icon: const Icon(Icons.remove),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text("$_value", style: const TextStyle(fontSize: 28)),
          ),
          IconButton(
            onPressed: _onButtonPressedFactory(increment: true),
            icon: const Icon(Icons.add),
          ),
        ],
      );
}
