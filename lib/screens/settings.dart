import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:provider/provider.dart";

import "../utils/settings.dart";
import "../utils/ui.dart";
import "../utils/updates_checker.dart";

class _ChoiceListTile<T> extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final List<T> items;
  final ConverterFunction<T, String>? itemToString;
  final int index;
  final ValueChanged<T> onChanged;

  const _ChoiceListTile({
    super.key,
    this.leading,
    required this.title,
    required this.items,
    this.itemToString,
    required this.index,
    required this.onChanged,
  });

  String _itemToString(T item) => itemToString == null ? item.toString() : itemToString!(item);

  Future<void> _onTileClick(BuildContext context) async {
    final res = await showChoiceDialog(
      context: context,
      items: items,
      itemToString: _itemToString,
      title: title,
      selectedIndex: index,
    );
    if (res != null) {
      onChanged(res);
    }
  }

  @override
  Widget build(BuildContext context) => ListTile(
        leading: leading,
        title: title,
        subtitle: Text(_itemToString(items[index])),
        onTap: () => _onTileClick(context),
      );
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsModel>();
    final packageInfo = context.read<PackageInfo>();
    final appVersion = packageInfo.version + (kDebugMode ? " (debug)" : "");
    return Scaffold(
      appBar: AppBar(title: const Text("Настройки")),
      body: ListView(
        children: [
          _ChoiceListTile(
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
          _ChoiceListTile(
            leading: const Icon(Icons.color_lens),
            title: const Text("Цветовая схема"),
            items: ColorSchemeType.values,
            itemToString: (item) => switch (item) {
              ColorSchemeType.system => "Системная",
              ColorSchemeType.app => "Приложения",
            },
            index: settings.colorSchemeType.index,
            onChanged: settings.setColorSchemeType,
          ),
          _ChoiceListTile(
            leading: const Icon(Icons.timer),
            title: const Text("Режим таймера"),
            items: TimerType.values,
            itemToString: (item) => switch (item) {
              TimerType.strict => "Строгий",
              TimerType.plus5 => "+5 секунд",
              TimerType.extended => "Увеличенный",
              TimerType.disabled => "Отключен",
            },
            index: settings.timerType.index,
            onChanged: settings.setTimerType,
          ),
          _ChoiceListTile(
            leading: const Icon(Icons.update),
            title: const Text("Проверка обновлений"),
            items: CheckUpdatesType.values,
            itemToString: (item) => switch (item) {
              CheckUpdatesType.onLaunch => "При запуске",
              CheckUpdatesType.manually => "Вручную",
            },
            index: settings.checkUpdatesType.index,
            onChanged: settings.setCheckUpdatesType,
          ),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text("Проверить обновления"),
            onTap: () async {
              unawaited(
                showSnackBar(context, const SnackBar(content: Text("Проверка обновлений..."))),
              );
              final NewVersionInfo? res;
              try {
                res = await checkForUpdates(rethrow_: true);
              } on Exception {
                if (context.mounted) {
                  unawaited(
                    showSnackBar(
                      context,
                      const SnackBar(content: Text("Ошибка проверки обновлений")),
                    ),
                  );
                }
                return;
              }
              if (context.mounted) {
                if (res != null) {
                  ScaffoldMessenger.of(context)
                      .removeCurrentSnackBar(reason: SnackBarClosedReason.remove);
                  unawaited(showUpdateDialog(context, res));
                } else {
                  unawaited(showSnackBar(context, const SnackBar(content: Text("Обновлений нет"))));
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text("О приложении"),
            subtitle: Text("${packageInfo.appName} $appVersion"),
            onTap: () => showAboutDialog(
              context: context,
              applicationName: packageInfo.appName,
              applicationVersion: "$appVersion build ${packageInfo.buildNumber}",
              applicationLegalese: "© 2023 Евгений Филимонов",
              // TODO: sources, license
            ),
          ),
        ],
      ),
    );
  }
}
