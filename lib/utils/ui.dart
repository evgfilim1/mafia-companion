import "package:flutter/material.dart";

import "../game/player.dart";
import "../game/states.dart";

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
      case GameStateSpeaking(stage: GameStage.speaking, player: final player):
        return "Речь игрока ${player.number}";
      case GameStateWithPlayers(stage: GameStage.preVoting):
        return "Голосование";
      case GameStateVoting(stage: GameStage.voting, player: final player):
        return "Голосование против игрока ${player.number}";
      case GameStateWithCurrentPlayer(stage: GameStage.excuse, player: final player):
        return "Повторная речь игрока ${player.number}";
      case GameStateWithPlayers(stage: GameStage.preFinalVoting):
        return "Повторное голосование";
      case GameStateVoting(stage: GameStage.finalVoting, player: final player):
        return "Повторное голосование против игрока ${player.number}";
      case GameStateDropTableVoting():
        return "Голосование за подъём стола";
      case GameStateWithCurrentPlayer(stage: GameStage.dayLastWords, player: final player):
        return "Последние слова игрока ${player.number}";
      case GameStateNightKill():
        return "Ночь, ход Мафии";
      case GameStateNightCheck(stage: GameStage.nightCheck, player: final player):
        if (player.role == PlayerRole.don) {
          return "Ночь, ход Дона";
        }
        return "Ночь, ход Шерифа";
      case GameStateWithPlayer(stage: GameStage.nightLastWords, player: final player):
        return "Последние слова игрока ${player.number}";
      case GameStateFinish():
        return "Игра окончена";
      default:
        throw AssertionError("Unknown game state: $this");
    }
  }
}

typedef ConverterFunction<T, R> = R Function(T value);

void showSnackBar(BuildContext context, SnackBar snackBar, {bool dismissPrevious = true}) {
  final messenger = ScaffoldMessenger.of(context);
  if (dismissPrevious) {
    messenger.hideCurrentSnackBar();
  }
  messenger.showSnackBar(snackBar);
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
