import "dart:async";

import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:vibration/vibration.dart";

import "../game/player.dart";
import "../game/states.dart";
import "../utils/errors.dart";
import "../utils/game_controller.dart";
import "../utils/settings.dart";
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
    if (randomizeSeats ?? false) {
      if (!context.mounted) {
        throw ContextNotMountedError();
      }
      await Navigator.pushNamed(context, "/seats");
    }
    if (!context.mounted) {
      throw ContextNotMountedError();
    }
    await Navigator.pushNamed(context, "/chooseRoles");
    if (controller.rolesSeed != null) {
      // roles were initialized, so we can start the game
      controller.startNewGame();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    final settings = context.watch<SettingsModel>();

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
      return TextButton(
        onPressed: () => Navigator.pushNamed(context, "/roles"),
        child: const Text("Раздача ролей", style: TextStyle(fontSize: 20)),
      );
    }

    if (gameState
        case GameStateWithPlayers(
          stage: GameStage.preVoting || GameStage.preFinalVoting,
          playerNumbers: final selectedPlayers
        )) {
      return Text(
        "Выставлены: ${selectedPlayers.join(", ")}",
        style: const TextStyle(fontSize: 20),
      );
    }

    if (gameState is GameStateVoting) {
      assert(gameState.votes.keys.length > 1, "One or less vote candidates (bug?)");
      final aliveCount = controller.alivePlayersCount;
      final currentPlayerVotes = gameState.currentPlayerVotes ?? 0;
      return Counter(
        key: ValueKey(gameState.currentPlayerNumber),
        min: 0,
        max: aliveCount - controller.totalVotes,
        onValueChanged: controller.vote,
        initialValue: currentPlayerVotes,
      );
    }

    if (gameState is GameStateKnockoutVoting) {
      return Counter(
        key: const ValueKey("dropTableVoting"),
        min: 0,
        max: controller.alivePlayersCount,
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

    Duration? timeLimit;
    switch (settings.timerType) {
      case TimerType.disabled:
        timeLimit = null;
      case TimerType.plus5:
        final t = timeLimits[gameState.stage];
        timeLimit = t != null ? t + const Duration(seconds: 5) : null;
      case TimerType.extended:
        timeLimit = timeLimitsExtended[gameState.stage] ?? timeLimits[gameState.stage];
      case TimerType.strict:
        timeLimit = timeLimits[gameState.stage];
      case TimerType.shortened:
        timeLimit = timeLimitsShortened[gameState.stage] ?? timeLimits[gameState.stage];
    }
    if (gameState case GameStateSpeaking(hasHalfTime: true)) {
      timeLimit = timeLimit != null ? timeLimit ~/ 2 : null;
    }
    if (timeLimit != null) {
      return PlayerTimer(
        key: GameStateKey(gameState),
        duration: timeLimit,
        onTimerTick: (duration) async {
          if (settings.vibrationDuration == VibrationDuration.disabled) {
            return;
          }
          if (duration == Duration.zero) {
            await Vibration.vibrate(duration: 100);
            await Future<void>.delayed(
              const Duration(milliseconds: 300),
            ); // 100 vibration + 200 pause
            await Vibration.vibrate(duration: 100);
          } else if (duration <= const Duration(seconds: 5)) {
            await Vibration.vibrate(duration: settings.vibrationDuration.milliseconds);
          }
        },
      );
    }
    return const SizedBox.shrink(); // empty widget
  }
}
