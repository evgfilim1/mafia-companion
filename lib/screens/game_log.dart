import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../game/log.dart";
import "../game/states.dart";
import "../utils/game_controller.dart";
import "../utils/ui.dart";

extension DescribeLogItem on BaseGameLogItem {
  List<String> get description {
    final result = <String>[];
    switch (this) {
      case StateChangeGameLogItem(oldState: final oldState):
        switch (oldState) {
          case GameState() ||
                GameStateWithPlayer() ||
                GameStateVoting() ||
                GameStateDropTableVoting() ||
                GameStateWithPlayers() ||
                GameStateNightKill() ||
                GameStateNightCheck() ||
                GameStateWithCurrentPlayer():
            // skip
            break;
          case GameStateSpeaking(currentPlayerNumber: final pn, accusations: final accusations):
            if (accusations[pn] != null) {
              result.add("Игрок #$pn выставил на голосование игрока #${accusations[pn]}");
            }
          case GameStateFinish():
            throw AssertionError();
        }
        result.add('Этап игры изменён с "${oldState.prettyName}"');
      case PlayerCheckedGameLogItem(
          playerNumber: final playerNumber,
          checkedByRole: final checkedByRole,
        ):
        result.add("${checkedByRole.prettyName} проверил игрока #$playerNumber");
      case PlayerWarnedGameLogItem(playerNumber: final playerNumber):
        result.add("Выдано предупреждение игроку #$playerNumber");
    }
    return result;
  }
}

class GameLogScreen extends StatelessWidget {
  const GameLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<GameController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Журнал игры"),
      ),
      body: controller.gameLog.isNotEmpty
          ? ListView(
              children: <ListTile>[
                for (final item in controller.gameLog)
                  for (final desc in item.description)
                    ListTile(
                      title: Text(desc),
                      dense: true,
                    ),
              ],
            )
          : Center(
              child: Text(
                "Ещё ничего не произошло",
                style: TextStyle(color: Theme.of(context).disabledColor),
              ),
            ),
    );
  }
}
