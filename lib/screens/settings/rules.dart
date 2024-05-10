import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../../utils/rules.dart";

class GameRulesSettingsScreen extends StatelessWidget {
  const GameRulesSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rules = context.watch<GameRulesModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Правила"),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text("Проводить голосование полностью"),
            subtitle: Text(
              rules.alwaysContinueVoting
                  ? "Голосование продолжится, даже когда результат станет однозначным"
                  : "Голосование закончится, как только результат станет однозначным",
            ),
            value: rules.alwaysContinueVoting,
            onChanged: rules.setAlwaysContinueVoting,
          ),
        ],
      ),
    );
  }
}
