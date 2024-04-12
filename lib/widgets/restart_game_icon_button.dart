import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../utils/errors.dart";
import "../utils/game_controller.dart";
import "../utils/ui.dart";
import "restart_dialog.dart";

class RestartGameIconButton extends StatelessWidget {
  const RestartGameIconButton({super.key});

  Future<void> _askRestartGame(BuildContext context) async {
    final restartGame = await showDialog<bool>(
      context: context,
      builder: (context) => const RestartGameDialog(),
    );
    if (!context.mounted) {
      throw ContextNotMountedError();
    }
    if (restartGame ?? false) {
      context.read<GameController>().stopGame();
      showSnackBar(context, const SnackBar(content: Text("Игра перезапущена")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    return IconButton(
      onPressed: controller.isGameInitialized ? () => _askRestartGame(context) : null,
      tooltip: "Перезапустить игру",
      icon: const Icon(Icons.restart_alt),
    );
  }
}
