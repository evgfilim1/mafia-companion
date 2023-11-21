import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:provider/provider.dart";

import "../utils/bug_report/stub.dart"
    if (dart.library.io) "../utils/bug_report/native.dart"
    if (dart.library.html) "../utils/bug_report/web.dart";
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
      appBar: AppBar(title: const Text("Отладочное меню")),
      body: ListView(
        children: [
          if (kDebugMode)
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
            )
          else
            ListTile(
              leading: const Icon(Icons.casino),
              title: const Text("Зерно генератора ролей"),
              subtitle: const Text("Нажмите для копирования"),
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: _seedController.text));
                if (!context.mounted) {
                  throw ContextNotMountedError();
                }
                showSnackBar(
                  context,
                  const SnackBar(content: Text("Текст скопирован в буфер обмена")),
                );
              },
            ),
          ListTile(
            leading: const Icon(Icons.bug_report),
            title: const Text("Сообщить о проблеме"),
            onTap: () {
              showSimpleDialog(
                context: context,
                title: const Text("Сообщить о проблеме"),
                content: const Text(
                  "Для сообщения о проблеме нужно поделиться файлом или скопированным текстом"
                  " мне в ЛС в Telegram.",
                ),
                extraActions: [
                  TextButton(
                    onPressed: () async {
                      await reportBug(context);
                      if (!context.mounted) {
                        throw ContextNotMountedError();
                      }
                      Navigator.pop(context);
                    },
                    child: const Text("Сформировать отчёт"),
                  ),
                ],
              );
            },
          ),
          if (kDebugMode)
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
