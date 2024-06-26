import "dart:async";
import "dart:io";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:permission_handler/permission_handler.dart";
import "package:provider/provider.dart";
import "package:url_launcher/url_launcher.dart";

import "../game/player.dart";
import "../game/states.dart";
import "../widgets/information_dialog.dart";
import "../widgets/update_available_dialog.dart";
import "../widgets/update_dialog.dart";
import "errors.dart";
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
      case GameStatePrepare(stage: GameStage.prepare):
        return "Ожидание игроков...";
      case GameStateWithPlayers(stage: GameStage.firstNight):
        return "Первая ночь";
      case GameStateWithPlayer(stage: GameStage.firstNightWakeUps):
        return "Шериф осматривает стол";
      case GameStateNightRest():
        return "Свободная посадка";
      case GameStateSpeaking(
          stage: GameStage.speaking,
          :final currentPlayerNumber,
          :final canOnlyAccuse,
          :final hasHalfTime,
        ):
        if (canOnlyAccuse && !hasHalfTime) {
          return "Кандидатура от игрока $currentPlayerNumber";
        }
        return "Речь игрока $currentPlayerNumber";
      case GameStateWithPlayers(stage: GameStage.preVoting):
        return "Голосование";
      case GameStateVoting(stage: GameStage.voting, :final currentPlayerNumber):
        return "Голосование против игрока $currentPlayerNumber";
      case GameStateWithPlayers(stage: GameStage.preExcuse):
        return "Повторные речи";
      case GameStateWithIterablePlayers(stage: GameStage.excuse, :final currentPlayerNumber):
        return "Повторная речь игрока $currentPlayerNumber";
      case GameStateWithPlayers(stage: GameStage.preFinalVoting):
        return "Повторное голосование";
      case GameStateVoting(stage: GameStage.finalVoting, :final currentPlayerNumber):
        return "Повторное голосование против игрока $currentPlayerNumber";
      case GameStateKnockoutVoting():
        return "Голосование за подъём всех игроков";
      case GameStateWithIterablePlayers(stage: GameStage.dayLastWords, :final currentPlayerNumber):
        return "Последние слова игрока $currentPlayerNumber";
      case GameStateNightKill():
        return "Ночь, ход Мафии";
      case GameStateNightCheck(stage: GameStage.nightCheck, :final activePlayerTeam):
        if (activePlayerTeam == RoleTeam.mafia) {
          return "Ночь, ход Дона";
        }
        return "Ночь, ход Шерифа";
      case GameStateBestTurn(:final currentPlayerNumber):
        return "Лучший ход игрока $currentPlayerNumber";
      case GameStateWithPlayer(stage: GameStage.nightLastWords, :final currentPlayerNumber):
        return "Последние слова игрока $currentPlayerNumber";
      case GameStateFinish():
        return "Игра окончена";
      default:
        throw AssertionError("Unknown game state: $this");
    }
  }
}

void showSnackBar(
  BuildContext context,
  SnackBar snackBar, {
  bool dismissPrevious = true,
}) {
  final messenger = ScaffoldMessenger.of(context);
  if (dismissPrevious) {
    messenger.hideCurrentSnackBar();
  }
  messenger.showSnackBar(snackBar);
}

Future<void> showSimpleDialog({
  required BuildContext context,
  required Widget title,
  required Widget content,
  List<Widget> extraActions = const [],
  String? rememberKey,
}) =>
    showDialog<void>(
      context: context,
      builder: (context) => InformationDialog(
        title: title,
        content: content,
        extraActions: extraActions,
        rememberKey: rememberKey,
      ),
    );

Future<void> launchUrlOrCopy(BuildContext context, String url, {LaunchMode? launchMode}) async {
  final isOk = await launchUrl(Uri.parse(url), mode: launchMode ?? LaunchMode.inAppBrowserView);
  if (isOk) {
    return;
  }
  if (!context.mounted) {
    throw ContextNotMountedError();
  }
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
  );
}

Future<void> showUpdateDialog(BuildContext context) async {
  assert(!kIsWeb, "Updates checking is not supported on web");
  final updater = context.read<UpdatesChecker>();
  if (!updater.hasUpdate) {
    throw StateError("No update available");
  }
  final doUpdate = await showDialog<bool>(
    context: context,
    builder: (context) => UpdateAvailableDialog(info: updater.updateInfo!),
  );
  if (!(doUpdate ?? false)) {
    return;
  }
  if (!context.mounted) {
    throw ContextNotMountedError();
  }
  if (!Platform.isAndroid) {
    throw UnsupportedError("Unsupported platform: ${Platform.operatingSystem}");
  }
  assert(updater.updateInfo!.downloadUrl.isNotEmpty, "Download URL is empty");
  try {
    const requiredPermission = Permission.requestInstallPackages;
    if (await requiredPermission.status != PermissionStatus.granted) {
      if (!context.mounted) {
        throw ContextNotMountedError();
      }
      await showSimpleDialog(
        context: context,
        title: const Text("Необходимо разрешение"),
        content: const Text(
          "Для установки обновления необходимо разрешение на установку приложений из неизвестных"
          " источников.",
        ),
      );
      if (await requiredPermission.request() != PermissionStatus.granted) {
        if (context.mounted) {
          showSnackBar(
            context,
            const SnackBar(content: Text("Не удалось получить разрешение")),
          );
        }
        return;
      }
    }
    if (!context.mounted) {
      throw ContextNotMountedError();
    }
    unawaited(updater.startOtaUpdateSession());
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final updater = context.watch<UpdatesChecker>();
        if (updater.currentAction == OtaAction.error) {
          return InformationDialog(
            title: const Text("Ошибка"),
            content:
                const Text("Не удалось установить обновление, попробуйте сделать это вручную."),
            extraActions: [
              TextButton(
                onPressed: () => launchUrlOrCopy(context, updater.updateInfo!.downloadUrl),
                child: const Text("Открыть ссылку"),
              ),
            ],
          );
        }
        return const PopScope(canPop: false, child: UpdateDialog());
      },
    );
  } on Exception {
    if (!context.mounted) {
      throw ContextNotMountedError();
    }
    await launchUrlOrCopy(context, updater.updateInfo!.downloadUrl);
  }
}

class GameStateKey extends ValueKey<BaseGameState> {
  const GameStateKey(super.value);

  @override
  // It's totally fine to use `hashCode` of `ValueKey<BaseGameState>` here
  // ignore: hash_and_equals
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is GameStateKey && !value.hasStateChanged(other.value) || super == other;
  }
}

extension PlayerNicknameOrNumber on Player {
  String get nicknameOrNumber => nickname ?? "Игрок #$number";
}
