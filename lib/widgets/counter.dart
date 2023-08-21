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

  VoidCallback? _onButtonPressedFactory({int? delta, int? newValue}) {
    if (delta == null && newValue == null) {
      throw ArgumentError("Either delta or newValue must be provided");
    }
    if (delta != null && newValue != null) {
      throw ArgumentError("Only one of delta or newValue must be provided");
    }
    if (delta != null) {
      newValue = _value + delta;
    }
    if (newValue! > widget.max || newValue < widget.min || _value == newValue) {
      return null;
    }
    return () => setState(() {
          _value = newValue!;
          widget.onValueChanged?.call(newValue);
        });
  }

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _IconButtonWithLongPress(
            onTap: _onButtonPressedFactory(delta: -1),
            onLongPress: _onButtonPressedFactory(newValue: widget.min),
            icon: Icons.remove,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text("$_value", style: const TextStyle(fontSize: 28)),
          ),
          _IconButtonWithLongPress(
            onTap: _onButtonPressedFactory(delta: 1),
            onLongPress: _onButtonPressedFactory(newValue: widget.max),
            icon: Icons.add,
          ),
        ],
      );
}

class _IconButtonWithLongPress extends StatelessWidget {
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final IconData icon;

  const _IconButtonWithLongPress({
    super.key,
    this.onTap,
    this.onLongPress,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final color = onTap == null && onLongPress == null ? Theme.of(context).disabledColor : null;
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Theme(
          data: Theme.of(context),
          child: Icon(
            icon,
            color: color,
          ),
        ),
      ),
    );
  }
}
