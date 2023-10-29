import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:url_launcher/url_launcher.dart";

import "../game/player.dart";
import "../game/states.dart";
import "../widgets/update_dialog.dart";
import "updates_checker.dart";

extension PlayerRolePrettyString on PlayerRole {
  String get prettyName {
    switch (this) {
      case PlayerRole.citizen:
        return "Мирный житель";
      case PlayerRole.mafia:
        return "Мафия";
      case PlayerRole.don:
        return "Дон";
      case PlayerRole.sheriff:
        return "Шериф";
    }
  }
}

extension GameStatePrettyString on BaseGameState {
  String get prettyName {
    switch (this) {
      case GameState(stage: GameStage.prepare):
        return "Ожидание игроков...";
      case GameStateWithPlayers(stage: GameStage.night0):
        return "Первая ночь";
      case GameStateWithPlayer(stage: GameStage.night0SheriffCheck):
        return "Шериф осматривает стол";
      case GameStateSpeaking(stage: GameStage.speaking, currentPlayerNumber: final playerNumber):
        return "Речь игрока $playerNumber";
      case GameStateWithPlayers(stage: GameStage.preVoting):
        return "Голосование";
      case GameStateVoting(stage: GameStage.voting, currentPlayerNumber: final playerNumber):
        return "Голосование против игрока $playerNumber";
      case GameStateWithCurrentPlayer(
          stage: GameStage.excuse,
          currentPlayerNumber: final playerNumber,
        ):
        return "Повторная речь игрока $playerNumber";
      case GameStateWithPlayers(stage: GameStage.preFinalVoting):
        return "Повторное голосование";
      case GameStateVoting(stage: GameStage.finalVoting, currentPlayerNumber: final playerNumber):
        return "Повторное голосование против игрока $playerNumber";
      case GameStateDropTableVoting():
        return "Голосование за подъём стола";
      case GameStateWithCurrentPlayer(
          stage: GameStage.dayLastWords,
          currentPlayerNumber: final playerNumber,
        ):
        return "Последние слова игрока $playerNumber";
      case GameStateNightKill():
        return "Ночь, ход Мафии";
      case GameStateNightCheck(stage: GameStage.nightCheck, activePlayerRole: final playerRole):
        if (playerRole == PlayerRole.don) {
          return "Ночь, ход Дона";
        }
        return "Ночь, ход Шерифа";
      case GameStateWithPlayer(
          stage: GameStage.nightLastWords,
          currentPlayerNumber: final playerNumber,
        ):
        return "Последние слова игрока $playerNumber";
      case GameStateFinish():
        return "Игра окончена";
      default:
        throw AssertionError("Unknown game state: $this");
    }
  }
}

typedef ConverterFunction<T, R> = R Function(T value);

Future<SnackBarClosedReason> showSnackBar(
  BuildContext context,
  SnackBar snackBar, {
  bool dismissPrevious = true,
}) {
  final messenger = ScaffoldMessenger.of(context);
  if (dismissPrevious) {
    messenger.hideCurrentSnackBar();
  }
  return messenger.showSnackBar(snackBar).closed;
}

/// Shows a simple dialog with a list of [items] and returns the selected item.
///
/// [itemToString] is used to convert the item to a string.
///
/// [selectedIndex] is the index of the item that should be selected by default.
/// If [selectedIndex] is null, no item will be selected, thus no checkmark will
/// be shown.
///
/// Returns the selected item or null if the dialog was dismissed.
Future<T?> showChoiceDialog<T>({
  required BuildContext context,
  required List<T> items,
  ConverterFunction<T, String>? itemToString,
  required Widget title,
  required int? selectedIndex,
}) async =>
    showDialog<T>(
      context: context,
      builder: (context) => SimpleDialog(
        title: title,
        children: [
          for (var i = 0; i < items.length; i++)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, items[i]),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(itemToString?.call(items[i]) ?? items[i].toString()),
                  if (i == selectedIndex) const Icon(Icons.check),
                ],
              ),
            ),
        ],
      ),
    );

void showSimpleDialog({
  required BuildContext context,
  required Widget title,
  required Widget content,
  List<Widget> actions = const [],
}) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: title,
      content: content,
      actions: [
        ...actions,
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("ОК"),
        ),
      ],
    ),
  );
}

Future<void> launchUrlOrCopy(BuildContext context, String url) async {
  final isOk = await launchUrl(
    Uri.parse(url),
    mode: LaunchMode.externalApplication, // it crashes for me otherwise for some reason
  );
  if (isOk) {
    return;
  }
  if (!context.mounted) {
    return;
  }
  unawaited(
    showSnackBar(
      context,
      SnackBar(
        content: const Text("Не удалось открыть ссылку"),
        action: SnackBarAction(
          label: "Скопировать",
          onPressed: () {
            Clipboard.setData(ClipboardData(text: url));
            showSnackBar(
              context,
              const SnackBar(
                content: Text("Ссылка скопирована в буфер обмена"),
              ),
            );
          },
        ),
      ),
    ),
  );
}

Future<void> showUpdateDialog(BuildContext context, NewVersionInfo info) async {
  final doUpdate = await showDialog<bool>(
    context: context,
    builder: (context) => UpdateAvailableDialog(info: info),
  );
  if (!(doUpdate ?? false)) {
    return;
  }
  if (!context.mounted) {
    return;
  }
  if (kIsWeb) {
    unawaited(
      showSnackBar(
        context,
        const SnackBar(
          content: Text("Перезагрузите страницу для обновления"),
        ),
      ),
    );
    return;
  }
  await launchUrlOrCopy(context, info.downloadUrl);
}
