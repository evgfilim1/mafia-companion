import "dart:async";

import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../utils/updates_checker.dart";
import "confirmation_dialog.dart";

class UpdateDialog extends StatelessWidget {
  const UpdateDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final updater = context.watch<UpdatesChecker>();
    final action = switch (updater.currentAction) {
      OtaAction.downloading => "Загрузка обновления...",
      OtaAction.installing => "Установка обновления...",
      OtaAction.error => "Ошибка",
      null => "Ожидание...",
    };
    return AlertDialog(
      title: Text(action),
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            flex: 5,
            child: LinearProgressIndicator(
              value: updater.progress,
            ),
          ),
          if (updater.progress != null)
            Flexible(
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: 16),
                child: Text("${(updater.progress! * 100).round()}%"),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: updater.isCancellable
              ? () async {
                  final res = await showDialog<bool>(
                    context: context,
                    builder: (context) => const ConfirmationDialog(
                      title: Text("Отменить обновление?"),
                      content: Text("Вы уверены, что хотите отменить обновление?"),
                    ),
                  );
                  if (res ?? false) {
                    unawaited(updater.cancelOtaUpdate());
                    if (!context.mounted) {
                      return;
                    }
                    Navigator.pop(context);
                  }
                }
              : null,
          child: const Text("Отмена"),
        ),
      ],
    );
  }
}
