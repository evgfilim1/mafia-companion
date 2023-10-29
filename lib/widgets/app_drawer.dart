import "package:flutter/material.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:provider/provider.dart";

import "../utils/ui.dart";

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

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
              launchUrlOrCopy(context, "https://mafiaworldtour.com/fiim-rules");
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text("Настройки"),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, "/settings");
            },
          ),
        ],
      ),
    );
  }
}
