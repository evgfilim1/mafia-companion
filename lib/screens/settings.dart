import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:provider/provider.dart";

import "../utils/errors.dart";
import "../utils/settings.dart";
import "../utils/ui.dart";
import "../utils/updates_checker.dart";
import "../widgets/list_tiles/choice.dart";
import "../widgets/notification_dot.dart";

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _checkForUpdates(BuildContext context) async {
    final checker = context.read<UpdatesChecker>();
    showSnackBar(context, const SnackBar(content: Text("Проверка обновлений...")));
    final NewVersionInfo? res;
    try {
      res = await checker.checkForUpdates(rethrow_: true);
    } on Exception {
      if (!context.mounted) {
        throw ContextNotMountedError();
      }
      showSnackBar(
        context,
        const SnackBar(content: Text("Ошибка проверки обновлений")),
      );
      return;
    }
    if (!context.mounted) {
      throw ContextNotMountedError();
    }
    if (res != null) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar(reason: SnackBarClosedReason.remove);
      unawaited(showUpdateDialog(context));
    } else {
      showSnackBar(context, const SnackBar(content: Text("Обновлений нет")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsModel>();
    final packageInfo = context.read<PackageInfo>();
    final appVersion = packageInfo.version + (kDebugMode ? " (debug)" : "");
    final checker = context.watch<UpdatesChecker>();

    return Scaffold(
      appBar: AppBar(title: const Text("Настройки")),
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
              ColorSchemeType.app => "Приложения",
            },
            index: settings.colorSchemeType.index,
            onChanged: settings.setColorSchemeType,
          ),
          ChoiceListTile(
            leading: const Icon(Icons.timer),
            title: const Text("Режим таймера"),
            items: TimerType.values,
            itemToString: (item) => switch (item) {
              TimerType.shortened => "Сокращённый",
              TimerType.strict => "Строгий",
              TimerType.plus5 => "+5 секунд",
              TimerType.extended => "Увеличенный",
              TimerType.disabled => "Отключен",
            },
            index: settings.timerType.index,
            onChanged: settings.setTimerType,
          ),
          ChoiceListTile(
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
            subtitle: Text(
              checker.hasUpdate
                  ? "Доступна новая версия v${checker.updateInfo!.version}"
                  : "Обновлений нет",
            ),
            trailing: checker.hasUpdate ? const NotificationDot(size: 8) : null,
            onTap: () => _checkForUpdates(context),
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
