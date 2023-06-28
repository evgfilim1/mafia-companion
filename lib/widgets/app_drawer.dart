import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:provider/provider.dart";
import "package:url_launcher/url_launcher.dart";

import "../utils/ui.dart";

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  Future<void> _openGameRules(BuildContext context) async {
    const url = "https://mafiaworldtour.com/fiim-rules";
    final isOk = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication, // it crashes for me otherwise for some reason
    );
    if (isOk || !context.mounted) {
      return;
    }
    showSnackBar(
      context,
      SnackBar(
        content: const Text("Не удалось открыть ссылку"),
        action: SnackBarAction(
          label: "Скопировать",
          onPressed: () {
            Clipboard.setData(const ClipboardData(text: url));
            showSnackBar(
              context,
              const SnackBar(
                content: Text("Ссылка скопирована в буфер обмена"),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final packageInfo = context.watch<PackageInfo>();

    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            child: Center(
              child: Text(packageInfo.appName, style: Theme.of(context).textTheme.titleLarge),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.group),
            title: const Text("Случайная рассадка"),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, "/seats");
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("Раздача ролей"),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, "/roles");
            },
          ),
          ListTile(
            leading: const Icon(Icons.format_list_numbered),
            title: const Text("Официальные правила"),
            onTap: () {
              Navigator.pop(context);
              _openGameRules(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text("Настройки"),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, "/settings");
            },
          )
        ],
      ),
    );
  }
}
