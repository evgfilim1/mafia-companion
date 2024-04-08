import "package:flutter/material.dart";

import "../utils/load_save_file.dart";
import "../utils/log.dart";
import "../utils/ui.dart";
import "../widgets/list_tiles/text_field.dart";

class DebugMenuScreen extends StatelessWidget {
  static final _log = Logger("DebugMenuScreen");

  const DebugMenuScreen({super.key});

  Future<void> _getFileInfo(BuildContext context) async {
    final data = await loadJsonFile(fromJson: (json) => json);
    if (data == null) {
      return;
    }
    final String type;
    final String? version;
    if (data is List<dynamic>) {
      final first = data.firstOrNull;
      if (first is Map<String, dynamic> && first.containsKey("oldState")) {
        type = "Game log";
        version = "0";
      } else {
        type = "Unknown";
        version = null;
      }
    } else if (data is Map<String, dynamic>) {
      final keys = data.keys.toSet();
      if (keys.contains("packageInfo") && keys.contains("game")) {
        type = "Bug report";
        version = data["packageInfo"]["version"] as String;
      } else {
        if (keys.remove("version")) {
          version = (data["version"] as int).toString();
        } else {
          version = null;
        }
        if (keys.contains("log")) {
          type = "Game log";
        } else if (keys.contains("players")) {
          type = "Players";
        } else {
          type = "Unknown";
        }
      }
    } else {
      _log.debug("Unknown data type: ${data.runtimeType}");
      type = "Unknown";
      version = null;
    }
    if (!context.mounted) {
      return;
    }
    await showSimpleDialog(
      context: context,
      title: const Text("Информация о файле"),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Тип: $type"),
          if (version != null) Text("Версия: $version"),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text("Меню отладки")),
        body: ListView(
          children: [
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
            ListTile(
              leading: const Icon(Icons.file_open),
              title: const Text("Информация о файле"),
              onTap: () => _getFileInfo(context),
            ),
          ],
        ),
      );
}
