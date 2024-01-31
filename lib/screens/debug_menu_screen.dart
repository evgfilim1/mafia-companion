import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../utils/errors.dart";
import "../utils/game_controller.dart";
import "../utils/ui.dart";
import "../widgets/confirmation_dialog.dart";
import "../widgets/list_tiles/text_field.dart";

class DebugMenuScreen extends StatefulWidget {
  const DebugMenuScreen({super.key});

  @override
  State<DebugMenuScreen> createState() => _DebugMenuScreenState();
}

class _DebugMenuScreenState extends State<DebugMenuScreen> {
  final _seedController = TextEditingController();
  final _pathController = TextEditingController(text: "/");

  @override
  void dispose() {
    _seedController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    _seedController.text = controller.playerRandomSeed.toString();
    return Scaffold(
      appBar: AppBar(title: const Text("Меню отладки")),
      body: ListView(
        children: [
          TextFieldListTile(
            leading: const Icon(Icons.casino),
            title: const Text("Зерно генератора ролей"),
            subtitle: const Text("При изменении игра будет перезапущена"),
            textField: TextField(
              controller: _seedController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Зерно генератора ролей",
              ),
            ),
            onSaved: () async {
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
            textField: TextField(
              controller: _pathController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Путь",
              ),
            ),
            onSaved: () => Navigator.pushNamed(context, _pathController.text),
          ),
        ],
      ),
    );
  }
}
