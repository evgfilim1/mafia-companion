import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:provider/provider.dart";

import "../../utils/bug_report/stub.dart"
    if (dart.library.io) "../../utils/bug_report/native.dart"
    if (dart.library.html) "../../utils/bug_report/web.dart";
import "../../utils/errors.dart";
import "../../utils/game_controller.dart";
import "../../utils/misc.dart";
import "../../utils/ui.dart";
import "../../utils/updates_checker.dart";
import "../../widgets/notification_dot.dart";

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _checkForUpdates(BuildContext context) async {
    final checker = context.read<UpdatesChecker>();
    showSnackBar(context, const SnackBar(content: Text("Проверка обновлений...")));
    final NewVersionInfo? res;
    assert(!kIsWeb, "Updates checking is not supported on web");
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
    final packageInfo = context.read<PackageInfo>();
    final appVersion = packageInfo.version;
    final checker = context.watch<UpdatesChecker>();
    final controller = context.watch<GameController>();
    const updaterUnavailableReason = kEnableUpdater ? null : kIsWeb
        ? "в браузере"
        : kIsDev
            ? "при разработке"
            : null;

    return Scaffold(
      appBar: AppBar(title: const Text("Настройки")),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.color_lens),
            title: const Text("Внешний вид"),
            onTap: () => Navigator.of(context).pushNamed("/settings/appearance"),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text("Поведение"),
            onTap: () => Navigator.of(context).pushNamed("/settings/behavior"),
          ),
          ListTile(
            leading: const Icon(Icons.rule),
            title: const Text("Правила игры"),
            // onTap: () => Navigator.of(context).pushNamed("/settings/rules"),
            onTap: () => showSimpleDialog(
              context: context,
              title: const Text("🚧 В разработке 🚧"),
              content: const Text(
                "Настройки правил игры пока в разработке. Приложение пока работает только с"
                " правилами, описанными ФИИМ.",
              ),
            ),
          ),
          if (kIsDev || kEnableDebugMenu)
            ListTile(
              leading: const Icon(Icons.bug_report),
              title: const Text("Меню отладки"),
              onTap: () => Navigator.pushNamed(context, "/debug"),
            ),
          ListTile(
            enabled: updaterUnavailableReason == null,
            leading: const Icon(Icons.refresh),
            title: const Text("Проверить обновления"),
            subtitle: Text(
              updaterUnavailableReason != null
                  ? "Недоступно $updaterUnavailableReason"
                  : checker.hasUpdate
                      ? "Доступна новая версия v${checker.updateInfo!.version}"
                      : "Обновлений нет",
            ),
            trailing: checker.hasUpdate ? const NotificationDot(size: 8) : null,
            onTap: () => _checkForUpdates(context),
          ),
          ListTile(
            leading: const Icon(Icons.bug_report),
            title: const Text("Сообщить о проблеме"),
            onTap: () {
              if (!controller.isGameInitialized) {
                showSnackBar(
                  context,
                  const SnackBar(content: Text("Это работает только во время игры")),
                );
                return;
              }
              showSimpleDialog(
                context: context,
                title: const Text("Сообщить о проблеме"),
                content: const Text(
                  "Для сообщения о проблеме нужно поделиться файлом мне в ЛС в Telegram.",
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
