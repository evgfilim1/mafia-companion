import "dart:convert";

import "package:file_picker/file_picker.dart";
import "package:file_saver/file_saver.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:provider/provider.dart";

import "../game/log.dart";
import "../game/states.dart";
import "../utils/bug_report/stub.dart";
import "../utils/game_controller.dart";
import "../utils/json.dart";
import "../utils/log.dart";
import "../utils/ui.dart";

final _fileNameDateFormat = DateFormat("yyyy-MM-dd_HH-mm-ss");

extension _DescribeLogItem on BaseGameLogItem {
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
            result.add("За игрока #$pn отдано голосов: ${votes ?? 0}");
          case GameStateKnockoutVoting(votes: final votes):
            result.add("За подъём стола отдано голосов: $votes");
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
  static final _log = Logger("GameLogScreen");
  final List<BaseGameLogItem>? log;
  final bool isExternal;

  const GameLogScreen({
    super.key,
    this.log,
    this.isExternal = false,
  });

  Future<void> _onLoadPressed(BuildContext context) async {
    final pickerResult = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ["json"],
      withData: true,
    );
    if (!context.mounted || pickerResult == null) {
      return;
    }
    assert(pickerResult.isSinglePick, "Only single file pick is supported");
    final rawJsonString = String.fromCharCodes(pickerResult.files.single.bytes!);
    final data = jsonDecode(rawJsonString);
    final List<BaseGameLogItem> logFromFile;
    try {
      if (data is Map<String, dynamic> && data.containsKey("packageInfo")) {
        logFromFile = BugReportInfo.fromJson(data).game.log;
      } else if (data is List<dynamic> || data is Map<String, dynamic>) {
        logFromFile = VersionedGameLog.fromJson(data).log;
      } else {
        throw ArgumentError("Unknown data: ${data.runtimeType}, [0]=${rawJsonString[0]}");
      }
    } catch (e, s) {
      showSnackBar(context, const SnackBar(content: Text("Ошибка загрузки журнала")));
      _log.error(
        "Error loading game log: e=$e\n$s",
      );
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => GameLogScreen(log: logFromFile, isExternal: true)),
    );
  }

  Future<void> _onSavePressed(BuildContext context) async {
    final controller = context.read<GameController>();
    final jsonData = jsonEncode(controller.gameLog.map((e) => e.toJson()).toList());
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
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<GameController>();
    final title = isExternal ? "Загруженный журнал игры" : "Журнал игры";
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_open),
            tooltip: "Открыть журнал",
            onPressed: () => _onLoadPressed(context),
          ),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: "Сохранить журнал",
            onPressed: () => _onSavePressed(context),
          ),
        ],
      ),
      body: controller.gameLog.isNotEmpty
          ? ListView(
              children: <ListTile>[
                for (final item in log ?? controller.gameLog)
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
