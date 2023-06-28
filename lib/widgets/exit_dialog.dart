import "package:flutter/material.dart";

class ExitDialog extends StatelessWidget {
  const ExitDialog({super.key});

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text("Выход из игры"),
        content: const Text("Вы уверены, что хотите выйти из игры? Все данные будут потеряны."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Нет"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Да"),
          ),
        ],
      );
}
