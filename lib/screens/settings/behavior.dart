import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../../utils/settings.dart";
import "../../widgets/list_tiles/choice.dart";

class BehaviorSettingsScreen extends StatefulWidget {
  const BehaviorSettingsScreen({super.key});

  @override
  State<BehaviorSettingsScreen> createState() => _BehaviorSettingsScreenState();
}

class _BehaviorSettingsScreenState extends State<BehaviorSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsModel>();

    return Scaffold(
      appBar: AppBar(title: const Text("Поведение")),
      body: ListView(
        children: [
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
        ],
      ),
    );
  }
}
