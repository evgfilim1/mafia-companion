import 'package:flutter/material.dart';

import '../game/player.dart';
import '../utils.dart';

class PlayerButton extends StatelessWidget {
  final int number;
  final PlayerRole role;
  final bool isAlive;
  final bool isSelected;
  final bool isActive;
  final VoidCallback? onTap;
  final List<Widget> longPressActions;
  final Widget? child;

  const PlayerButton({
    super.key,
    required this.number,
    required this.role,
    required this.isAlive,
    required this.isSelected,
    this.isActive = false,
    this.onTap,
    this.longPressActions = const [],
    this.child,
  });

  void _onLongPress(BuildContext context) {
    final isAliveText = isAlive ? "Жив" : "Мёртв";
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Игрок $number"),
        content: Text("Состояние: $isAliveText\nРоль: ${role.prettyName}"),
        actions: [
          ...longPressActions,
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Закрыть"),
          ),
        ],
      ),
    );
  }

  Color? _getBorderColor(BuildContext context) {
    if (isActive) {
      return Colors.yellow;
    }
    if (isSelected) {
      return Theme.of(context).colorScheme.primary;
    }
    if (!isAlive) {
      return Colors.red;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = _getBorderColor(context);
    return Padding(
      padding: const EdgeInsets.all(4),
      child: ElevatedButton(
        style: ButtonStyle(
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          side: MaterialStateProperty.all(
            BorderSide(
              color: borderColor ?? Colors.transparent,
              width: 1,
            ),
          ),
        ),
        onPressed: onTap,
        onLongPress: () => _onLongPress(context),
        child: child ?? Center(child: Text("$number")),
      ),
    );
  }
}
