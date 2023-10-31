import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../utils/game_controller.dart";
import "../utils/ui.dart";
import "confirmation_dialog.dart";

class DebugMenuDialog extends StatefulWidget {
  const DebugMenuDialog({super.key});

  @override
  State<DebugMenuDialog> createState() => _DebugMenuDialogState();
}

class _DebugMenuDialogState extends State<DebugMenuDialog> {
  final _seedController = TextEditingController();

  @override
  void dispose() {
    _seedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<GameController>();
    _seedController.text = controller.playerRandomSeed.toString();
    return AlertDialog(
      title: const Text("Отладочное меню"),
      content: TextField(
        controller: _seedController,
        readOnly: !kDebugMode,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: "Зерно генерации списка игроков",
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Отмена"),
        ),
        TextButton(
          onPressed: () async {
            final seed = int.tryParse(_seedController.text);
            if (seed != null) {
              final res = await showDialog<bool>(
                context: context,
                builder: (context) => const ConfirmationDialog(
                  title: Text("Применить настройки?"),
                  content: Text("Текущая игра будет перезапущена. Продолжить?"),
                ),
              );
              if (res ?? false) {
                controller.restart(seed: seed);
                if (context.mounted) {
                  unawaited(
                    showSnackBar(
                      context,
                      const SnackBar(content: Text("Игра перезапущена")),
                    ),
                  );
                }
              }
            }
            if (context.mounted) {
              Navigator.pop(context);
            }
          },
          child: const Text("Сохранить"),
        ),
      ],
    );
  }
}
