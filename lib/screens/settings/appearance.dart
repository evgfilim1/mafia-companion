import "package:flutter/material.dart";
import "package:flutter_colorpicker/flutter_colorpicker.dart";
import "package:provider/provider.dart";

import "../../utils/settings.dart";
import "../../widgets/list_tiles/choice.dart";

class AppearanceSettingsScreen extends StatelessWidget {
  const AppearanceSettingsScreen({super.key});

  Future<void> _setSeedColor(BuildContext context, SettingsModel settings) async {
    final newColor = await showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Выберите цвет"),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: settings.seedColor,
            onColorChanged: (color) => Navigator.of(context).pop(color),
            availableColors: Colors.primaries,
          ),
        ),
      ),
    );
    if (newColor != null) {
      settings.setSeedColor(newColor);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsModel>();

    return Scaffold(
      appBar: AppBar(title: const Text("Внешний вид")),
      body: ListView(
        children: [
          ChoiceListTile(
            leading: const Icon(Icons.color_lens),
            title: const Text("Тема"),
            items: ThemeMode.values,
            itemToString: (item) => switch (item) {
              ThemeMode.system => "Системная",
              ThemeMode.light => "Светлая",
              ThemeMode.dark => "Тёмная",
            },
            index: settings.themeMode.index,
            onChanged: settings.setThemeMode,
          ),
          ChoiceListTile(
            leading: const Icon(Icons.color_lens),
            title: const Text("Цветовая схема"),
            items: ColorSchemeType.values,
            itemToString: (item) => switch (item) {
              ColorSchemeType.system => "Системная",
              ColorSchemeType.app => "Пользовательская",
            },
            index: settings.colorSchemeType.index,
            onChanged: settings.setColorSchemeType,
          ),
          ListTile(
            enabled: settings.colorSchemeType == ColorSchemeType.app,
            leading: const Icon(Icons.color_lens),
            title: const Text("Основной цвет"),
            subtitle: Text(
                settings.colorSchemeType == ColorSchemeType.app
                    ? "#${(settings.seedColor.value & 0xFFFFFF).toRadixString(16).padLeft(6, "0")}"
                    : "Системный",
            ),
            onTap: () => _setSeedColor(context, settings),
          ),
        ],
      ),
    );
  }
}
