import "package:flutter/material.dart";

class RestartGameDialog extends StatelessWidget {
  const RestartGameDialog({super.key});

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text("Перезапустить игру"),
        content: const Text("Вы уверены? Весь прогресс будет потерян."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Нет"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: const Text("Да"),
          ),
        ],
      );
}
