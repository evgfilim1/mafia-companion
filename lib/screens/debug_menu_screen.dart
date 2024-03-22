import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../utils/errors.dart";
import "../utils/game_controller.dart";
import "../utils/ui.dart";
import "../widgets/confirmation_dialog.dart";
import "../widgets/list_tiles/text_field.dart";

class DebugMenuScreen extends StatelessWidget {
  const DebugMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    return Scaffold(
      appBar: AppBar(title: const Text("Меню отладки")),
      body: ListView(
        children: [
          TextFieldListTile(
            leading: const Icon(Icons.casino),
            title: const Text("Зерно генератора ролей"),
            subtitle: const Text("При изменении игра будет перезапущена"),
            keyboardType: TextInputType.number,
            initialText: controller.rolesSeed?.toString() ?? "",
            labelText: "Зерно генератора ролей",
            onSubmit: (value) async {
              final seed = int.tryParse(value);
              if (seed != null) {
                final res = await showDialog<bool>(
                  context: context,
                  builder: (context) => const ConfirmationDialog(
                    title: Text("Применить настройки?"),
                    content: Text("Текущая игра будет перезапущена. Продолжить?"),
                  ),
                );
                if (res ?? false) {
                  controller
                    ..rolesSeed = seed
                    ..stopGame();
                  if (!context.mounted) {
                    throw ContextNotMountedError();
                  }
                  showSnackBar(
                    context,
                    const SnackBar(content: Text("Игра перезапущена")),
                  );
                }
              }
            },
          ),
          TextFieldListTile(
            leading: const Icon(Icons.arrow_forward),
            title: const Text("Перейти к экрану"),
            initialText: "/",
            labelText: "Путь",
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Введите путь";
              }
              if (!value.startsWith("/")) {
                return "Путь должен начинаться с /";
              }
              return null;
            },
            onSubmit: (value) async {
              try {
                await Navigator.pushNamed(context, value);
              } catch (e) {
                if (!context.mounted) {
                  return;
                }
                await showSimpleDialog(
                  context: context,
                  title: const Text("Ошибка"),
                  content: Text(e.toString()),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
