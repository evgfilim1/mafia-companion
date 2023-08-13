import "package:flutter/material.dart";

import "confirmation_dialog.dart";

class RestartGameDialog extends StatelessWidget {
  const RestartGameDialog({super.key});

  @override
  Widget build(BuildContext context) => const ConfirmationDialog(
        title: Text("Перезапустить игру"),
        content: Text("Вы уверены? Весь прогресс будет потерян."),
      );
}
