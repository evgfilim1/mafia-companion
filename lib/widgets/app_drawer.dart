import "package:flutter/material.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:provider/provider.dart";

import "../utils/navigation.dart";
import "../utils/ui.dart";
import "../utils/updates_checker.dart";
import "notification_dot.dart";

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final packageInfo = context.watch<PackageInfo>();
    final checker = context.watch<UpdatesChecker>();

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
            title: const Text("Игроки"),
            onTap: () {
              Navigator.pop(context);
              openPlayersPage(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.format_list_numbered),
            title: const Text("Официальные правила ФИИМ"),
            onTap: () {
              Navigator.pop(context);
              launchUrlOrCopy(context, "https://mafiaworldtour.com/fiim-rules");
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text("Настройки"),
            trailing: checker.hasUpdate ? const NotificationDot(size: 8) : null,
            onTap: () {
              Navigator.pop(context);
              openSettingsPage(context);
            },
          ),
        ],
      ),
    );
  }
}
