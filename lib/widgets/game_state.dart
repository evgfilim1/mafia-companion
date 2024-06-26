import "dart:async";

import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../game/player.dart";
import "../game/states.dart";
import "../utils/errors.dart";
import "../utils/game_controller.dart";
import "../utils/navigation.dart";
import "../utils/ui.dart";
import "confirmation_dialog.dart";
import "counter.dart";
import "player_timer.dart";
import "restart_dialog.dart";

class GameStateInfo extends StatelessWidget {
  const GameStateInfo({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          controller.isGameInitialized ? controller.state.prettyName : "Игра не начата",
          style: const TextStyle(fontSize: 32),
          textAlign: TextAlign.center,
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: BottomGameStateWidget(),
        ),
      ],
    );
  }
}

class BottomGameStateWidget extends StatelessWidget {
  const BottomGameStateWidget({super.key});

  Future<void> _onStartGamePressed(BuildContext context, GameController controller) async {
    final randomizeSeats = await showDialog<bool>(
      context: context,
      builder: (context) => const ConfirmationDialog(
        title: Text("Провести случайную рассадку?"),
        content: Text("Перед началом игры можно провести случайную рассадку"),
        rememberKey: "randomizeSeats",
      ),
    );
    if (randomizeSeats == null) {
      return;
    }
    if (randomizeSeats) {
      if (!context.mounted) {
        throw ContextNotMountedError();
      }
      await openSeatRandomizerPage(context);
    }
    if (!context.mounted) {
      throw ContextNotMountedError();
    }
    await openRoleChooserPage(context);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();

    if (!controller.isGameInitialized) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () => _onStartGamePressed(context, controller),
            child: const Text("Начать игру", style: TextStyle(fontSize: 20)),
          ),
        ],
      );
    }

    final gameState = controller.state;
    if (gameState is GameStatePrepare) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () => openRolesPage(context),
            child: const Text("Раздача ролей", style: TextStyle(fontSize: 20)),
          ),
          TextButton(
            onPressed: () => openRoleChooserPage(context),
            child: const Text("Редактирование игроков", style: TextStyle(fontSize: 20)),
          ),
        ],
      );
    }

    if (gameState
        case GameStateWithPlayers(
          stage: GameStage.preVoting || GameStage.preExcuse || GameStage.preFinalVoting,
          playerNumbers: final selectedPlayers
        )) {
      return Text(
        "${gameState.stage == GameStage.preExcuse ? "Игроки" : "Выставлены"}:"
        " ${selectedPlayers.join(", ")}",
        style: const TextStyle(fontSize: 20),
      );
    }

    if (gameState is GameStateVoting) {
      assert(gameState.votes.keys.length > 1, "One or less vote candidates (bug?)");
      final aliveCount = controller.players.aliveCount;
      final currentPlayerVotes = gameState.currentPlayerVotes ?? 0;
      final int minVotes;
      if (gameState.votes.keys.last == gameState.currentPlayerNumber) {
        minVotes = currentPlayerVotes;
      } else {
        minVotes = 0;
      }
      return Counter(
        key: ValueKey(gameState.currentPlayerNumber),
        min: minVotes,
        max: aliveCount - controller.totalVotes,
        onValueChanged: controller.vote,
        initialValue: currentPlayerVotes,
      );
    }

    if (gameState is GameStateKnockoutVoting) {
      return Counter(
        key: const ValueKey("dropTableVoting"),
        min: 0,
        max: controller.players.aliveCount,
        onValueChanged: controller.vote,
        initialValue: gameState.votes,
      );
    }

    if (gameState case GameStateFinish(winner: final winner)) {
      final resultText = switch (winner) {
        RoleTeam.citizen => "Победа команды мирных жителей",
        RoleTeam.mafia => "Победа команды мафии",
        null => "Ничья",
      };
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(resultText, style: const TextStyle(fontSize: 20)),
          TextButton(
            onPressed: () async {
              final restartGame = await showDialog<bool>(
                context: context,
                builder: (context) => const RestartGameDialog(),
              );
              if (restartGame ?? false) {
                controller.stopGame();
                if (!context.mounted) {
                  throw ContextNotMountedError();
                }
                showSnackBar(context, const SnackBar(content: Text("Игра перезапущена")));
              }
            },
            child: const Text("Начать заново", style: TextStyle(fontSize: 20)),
          ),
        ],
      );
    }

    return const PlayerTimer();
  }
}
