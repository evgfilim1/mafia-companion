import "package:flutter/material.dart";

import "../utils/ui.dart";
import "../widgets/list_tiles/text_field.dart";

class DebugMenuScreen extends StatelessWidget {
  const DebugMenuScreen({super.key});

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
          ],
        ),
      );
}
