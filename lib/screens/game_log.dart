import "dart:convert";

import "package:file_saver/file_saver.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:provider/provider.dart";

import "../game/log.dart";
import "../game/states.dart";
import "../utils/game_controller.dart";
import "../utils/json.dart";
import "../utils/ui.dart";

final _fileNameDateFormat = DateFormat("yyyy-MM-dd_HH-mm-ss");

extension DescribeLogItem on BaseGameLogItem {
  List<String> get description {
    final result = <String>[];
    switch (this) {
      case StateChangeGameLogItem(oldState: final oldState, newState: final newState):
        if (oldState != null && !newState.hasStateChanged(oldState)) {
          for (var i = 0; i < newState.players.length; i++) {
            final oldWarns = oldState.players[i].warns;
            final newWarns = newState.players[i].warns;
            if (oldWarns != newWarns) {
              result.add("Выдан фол игроку #${newState.players[i].number}");
            }
          }
          break;
        }
        switch (oldState) {
          case GameStatePrepare() ||
                GameStateWithPlayer() ||
                GameStateWithPlayers() ||
                GameStateNightKill() ||
                GameStateNightCheck() ||
                GameStateWithIterablePlayers() ||
                null:
            // skip
            break;
          case GameStateSpeaking(currentPlayerNumber: final pn, accusations: final accusations):
            if (accusations[pn] != null) {
              result.add("Игрок #$pn выставил на голосование игрока #${accusations[pn]}");
            }
          case GameStateVoting(currentPlayerNumber: final pn, currentPlayerVotes: final votes):
            result.add("За игрока #$pn отдано голосов: ${votes ?? 0}"); // FIXME: i18n
          case GameStateDropTableVoting(votesForDropTable: final votes):
            result.add("За подъём стола отдано голосов: $votes"); // FIXME: i18n
          case GameStateBestTurn(currentPlayerNumber: final pn, playerNumbers: final pns):
            if (pns.isNotEmpty) {
              result.add(
                'Игрок #$pn сделал "Лучший ход": игрок(и) ${pns.map((n) => "#$n").join(", ")}',
              );
            }
          case GameStateFinish():
            throw AssertionError();
        }
        result.add('Этап игры изменён на "${newState.prettyName}"');
      case PlayerCheckedGameLogItem(
          playerNumber: final playerNumber,
          checkedByRole: final checkedByRole,
        ):
        result.add("${checkedByRole.prettyName} проверил игрока #$playerNumber");
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
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: "Сохранить журнал",
            onPressed: () async {
              final jsonData = jsonEncode(controller.gameLog.map((e) => e.jsonData).toList());
              final data = Uint8List.fromList(jsonData.codeUnits);
              final fileName = "mafia_game_log_${_fileNameDateFormat.format(DateTime.now())}";
              final String? path;
              if (kIsWeb) {
                // web doesn't support `saveAs`
                path = await FileSaver.instance.saveFile(
                  name: fileName,
                  ext: "json",
                  bytes: data,
                  mimeType: MimeType.json,
                );
              } else {
                path = await FileSaver.instance.saveAs(
                  name: fileName,
                  ext: "json",
                  bytes: data,
                  mimeType: MimeType.json,
                );
              }
              if (!context.mounted || path == null) {
                return;
              }
              showSnackBar(context, const SnackBar(content: Text("Журнал сохранён")));
            },
          ),
        ],
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
