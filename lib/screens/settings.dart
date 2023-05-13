import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../settings.dart';

class _ChoiceListTile<T> extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final List<T> items;
  final String Function(T)? itemToString;
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

  void _onTileClick(BuildContext context) async {
    final res = await showDialog<T>(
      context: context,
      builder: (context) => SimpleDialog(
        title: title,
        children: [
          for (var i = 0; i < items.length; i++)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, items[i]!),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_itemToString(items[i])),
                  if (i == index) const Icon(Icons.check),
                ],
              ),
            ),
        ],
      ),
    );
    if (res != null) {
      onChanged(res);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading,
      title: title,
      subtitle: Text(_itemToString(items[index])),
      onTap: () => _onTileClick(context),
    );
  }
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
            leading: const Icon(Icons.timer),
            title: const Text("Таймер"),
            items: TimerType.values,
            itemToString: (item) {
              switch (item) {
                case TimerType.strict:
                  return "Строгий";
                case TimerType.plus5:
                  return "+5 секунд";
                case TimerType.extended:
                  return "Увеличенный";
                case TimerType.disabled:
                  return "Отключен";
              }
            },
            index: settings.timerType.index,
            onChanged: (value) => settings.setTimerType(value),
          ),
          ListTile(
            enabled: false,  // TODO: implement
            leading: const SizedBox(),
            title: const Text("Отмена действий"),
            subtitle: const Text("Экспериментальная функция, может работать некорректно"),
            trailing: Switch(
              value: settings.cancellable,
              onChanged: (value) => settings.setCancellable(value),
            ),
            onTap: () => settings.setCancellable(!settings.cancellable),
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
            ),
          ),
        ],
      ),
    );
  }
}
