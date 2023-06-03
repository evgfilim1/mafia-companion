import "package:flutter/material.dart";

class BottomControlBar extends StatelessWidget {
  final VoidCallback? onTapBack;
  final String backLabel;
  final VoidCallback? onTapNext;
  final String nextLabel;

  const BottomControlBar({
    super.key,
    this.onTapBack,
    this.backLabel = "Назад",
    this.onTapNext,
    this.nextLabel = "Далее",
  });

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: GameControl(
                onTap: onTapBack,
                icon: Icons.arrow_back,
                label: backLabel,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: GameControl(
                onTap: onTapNext,
                icon: Icons.arrow_forward,
                label: nextLabel,
              ),
            ),
          ),
        ],
      );
}

class GameControl extends StatelessWidget {
  final VoidCallback? onTap;
  final IconData icon;
  final String label;

  const GameControl({
    super.key,
    this.onTap,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final color = onTap == null ? Theme.of(context).disabledColor : null;
    return ElevatedButton(
      onPressed: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Icon(icon, color: color),
            Text(
              label,
              style: TextStyle(color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
