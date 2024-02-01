import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_colorpicker/flutter_colorpicker.dart";
import "package:provider/provider.dart";

import "../../utils/color_scheme.dart";
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
    final colorScheme = context.read<BrightnessAwareColorScheme>();
    final dynamicColorUnavailableReason = kIsWeb
        ? "в браузере"
        : !colorScheme.isDynamicColorSupported
            ? "на этом устройстве"
            : null;
    final canSelectSeedColor =
        settings.colorSchemeType == ColorSchemeType.custom || dynamicColorUnavailableReason != null;

    return Scaffold(
      appBar: AppBar(title: const Text("Внешний вид")),
      body: ListView(
        children: [
          ChoiceListTile(
            leading: switch (settings.themeMode) {
              ThemeMode.system => const Icon(Icons.brightness_auto),
              ThemeMode.dark => const Icon(Icons.dark_mode),
              ThemeMode.light => const Icon(Icons.light_mode),
            },
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
            enabled: dynamicColorUnavailableReason == null,
            leading: const Icon(Icons.color_lens),
            title: const Text("Цветовая схема"),
            subtitle: dynamicColorUnavailableReason != null
                ? Text("Недоступно $dynamicColorUnavailableReason")
                : null,
            items: ColorSchemeType.values,
            itemToString: (item) => switch (item) {
              ColorSchemeType.system => "Системная",
              ColorSchemeType.custom => "Пользовательская",
            },
            index: dynamicColorUnavailableReason == null
                ? settings.colorSchemeType.index
                : ColorSchemeType.custom.index,
            onChanged: settings.setColorSchemeType,
          ),
          ListTile(
            enabled: canSelectSeedColor,
            leading: Icon(
              Icons.colorize,
              color: canSelectSeedColor ? settings.seedColor : null,
            ),
            title: const Text("Основной цвет"),
            subtitle: Text(
              canSelectSeedColor
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
