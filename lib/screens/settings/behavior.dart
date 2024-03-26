import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:vibration/vibration.dart";

import "../../utils/settings.dart";
import "../../utils/ui.dart";
import "../../widgets/list_tiles/choice.dart";
import "../../widgets/list_tiles/confirm.dart";

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
            leading: const Icon(Icons.vibration),
            title: const Text("Длительность вибрации"),
            items: VibrationDuration.values,
            itemToString: (item) => switch (item) {
              VibrationDuration.disabled => "Отключена",
              VibrationDuration.xShort => "Очень короткая",
              VibrationDuration.short => "Короткая",
              VibrationDuration.medium => "Средняя",
              VibrationDuration.long => "Длинная",
              VibrationDuration.xLong => "Очень длинная",
            },
            index: settings.vibrationDuration.index,
            onChanged: (length) {
              settings.setVibrationDuration(length);
              if (length != VibrationDuration.disabled) {
                Vibration.vibrate(duration: length.milliseconds);
              }
            },
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
          ConfirmationListTile(
            leading: const Icon(Icons.visibility),
            title: const Text("Показать скрытые диалоги"),
            confirmationContent: const Text(
              "Это действие сбросит все сохранённые выборы и покажет все диалоги, которые были"
              " скрыты. Продолжить?",
            ),
            onConfirm: () {
              settings.forgetRememberedChoices();
              showSnackBar(context, const SnackBar(content: Text("Скрытые диалоги восстановлены")));
            },
          ),
        ],
      ),
    );
  }
}
