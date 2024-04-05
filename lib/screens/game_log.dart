import "dart:async";

import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:provider/provider.dart";

import "../game/log.dart";
import "../game/states.dart";
import "../utils/bug_report/stub.dart";
import "../utils/errors.dart";
import "../utils/extensions.dart";
import "../utils/game_controller.dart";
import "../utils/load_save_file.dart";
import "../utils/log.dart";
import "../utils/ui.dart";
import "../utils/versioned/game_log.dart";
import "../widgets/information_dialog.dart";

final _fileNameDateFormat = DateFormat("yyyy-MM-dd_HH-mm-ss");

extension _DescribeLogItem on BaseGameLogItem {
  List<String> get description {
    final result = <String>[];
    switch (this) {
      case StateChangeGameLogItem(:final newState):
        switch (newState) {
          case GameStatePrepare() ||
                GameStateNightRest() ||
                GameStateWithPlayer() ||
                GameStateWithPlayers() ||
                GameStateNightKill() ||
                GameStateNightCheck() ||
                GameStateWithIterablePlayers() ||
                GameStateFinish():
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
        }
        result.add('Этап игры изменён на "${newState.prettyName}"');
      case PlayerCheckedGameLogItem(
          playerNumber: final playerNumber,
          checkedByRole: final checkedByRole,
        ):
        result.add("${checkedByRole.prettyName} проверил игрока #$playerNumber");
      case PlayerWarnsChangedGameLogItem(:final playerNumber, :final oldWarns, :final currentWarns):
        if (currentWarns > oldWarns) {
          result.add("Игроку #$playerNumber выдан фол: $oldWarns -> $currentWarns");
        } else {
          result.add("У игрока #$playerNumber снят фол: $oldWarns -> $currentWarns");
        }
      case PlayerKickedGameLogItem(
          playerNumber: final playerNumber,
          isOtherTeamWin: final isOtherTeamWin,
        ):
        final kickMessage = "Игрок #$playerNumber исключён из игры";
        if (isOtherTeamWin) {
          result.add("$kickMessage и объявлена ППК");
        } else {
          result.add(kickMessage);
        }
    }
    return result;
  }
}

class GameLogScreen extends StatelessWidget {
  static final _log = Logger("GameLogScreen");
  final List<BaseGameLogItem>? log;

  const GameLogScreen({
    super.key,
    this.log,
  });

  VersionedGameLog _loadLogFromJson(dynamic data) {
    final VersionedGameLog vgl;
    if (data is Map<String, dynamic> && data.containsKey("packageInfo")) {
      vgl = VersionedGameLog(BugReportInfo.fromJson(data).game.log);
    } else if (data is List<dynamic> || data is Map<String, dynamic>) {
      vgl = VersionedGameLog.fromJson(data);
    } else {
      throw ArgumentError("Unknown data: ${data.runtimeType}");
    }
    return vgl;
  }

  void _onLoadLogFromJsonError(BuildContext context, Object error, StackTrace stackTrace) {
    if (error is UnsupportedVersion) {
      var content = "Версия этого журнала игры не поддерживается.";
      if (error is RemovedVersion) {
        content += " Попробуйте использовать приложение версии <=v${error.lastSupportedAppVersion}";
      }
      showSimpleDialog(
        context: context,
        title: const Text("Ошибка"),
        content: Text(content),
      );
      return;
    } else {
      showSnackBar(context, const SnackBar(content: Text("Ошибка загрузки журнала")));
      _log.error(
        "Error loading game log: e=$error\n$stackTrace",
      );
    }
  }

  Future<void> _onLoadPressed(BuildContext context) async {
    final logFromFile = await loadJsonFile(
      fromJson: _loadLogFromJson,
      onError: (e, st) => _onLoadLogFromJsonError(context, e, st),
    );
    if (logFromFile == null) {
      return; // error already handled
    }
    if (!context.mounted) {
      throw ContextNotMountedError();
    }
    if (logFromFile.version.isDeprecated) {
      await showDialog<void>(
        context: context,
        builder: (context) => InformationDialog(
          title: const Text("Предупреждение"),
          content: const Text(
            "Загрузка журналов игр старого формата устарела и скоро будет невозможна",
          ),
          rememberKey: "noDeprecations${logFromFile.version.name}",
        ),
      );
      if (!context.mounted) {
        throw ContextNotMountedError();
      }
    }
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => GameLogScreen(log: logFromFile.value.toUnmodifiableList()),
      ),
    );
  }

  Future<void> _onSavePressed(BuildContext context) async {
    final controller = context.read<GameController>();
    final vgl = VersionedGameLog(controller.gameLog);
    final fileName = "mafia_game_log_${_fileNameDateFormat.format(DateTime.now())}";
    final wasSaved = await saveJsonFile(vgl.toJson(), filename: fileName);
    if (!context.mounted || !wasSaved) {
      return;
    }
    showSnackBar(context, const SnackBar(content: Text("Журнал сохранён")));
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<GameController>();
    final title = this.log != null ? "Загруженный журнал игры" : "Журнал игры";
    final log = this.log ?? controller.gameLog;
    final logDescriptions = <String>[];
    StateChangeGameLogItem? prev;
    for (final curr in log) {
      if (curr is! StateChangeGameLogItem) {
        logDescriptions.addAll(curr.description);
        continue;
      }
      if (prev != null && curr.newState.hasStateChanged(prev.newState)) {
        logDescriptions.addAll(prev.description);
      }
      prev = curr;
    }
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
      body: log.isNotEmpty
          ? ListView(
              children: <ListTile>[
                for (final desc in logDescriptions)
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
