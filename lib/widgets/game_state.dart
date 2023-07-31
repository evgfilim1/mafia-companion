import "dart:async";

import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:vibration/vibration.dart";

import "../game/player.dart";
import "../game/states.dart";
import "../utils/extensions.dart";
import "../utils/game_controller.dart";
import "../utils/settings.dart";
import "../utils/ui.dart";
import "counter.dart";
import "player_timer.dart";
import "restart_dialog.dart";

class GameStateInfo extends StatelessWidget {
  const GameStateInfo({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameController>().state;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          gameState.prettyName,
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

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    final settings = context.watch<SettingsModel>();
    final gameState = controller.state;

    if (gameState.stage == GameStage.prepare) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () => Navigator.pushNamed(context, "/seats"),
            child: const Text("Случайная рассадка", style: TextStyle(fontSize: 20)),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, "/roles"),
            child: const Text("Раздача ролей", style: TextStyle(fontSize: 20)),
          ),
        ],
      );
    }

    if (gameState.stage.isAnyOf([GameStage.preVoting, GameStage.preFinalVoting])) {
      final selectedPlayers = controller.voteCandidates;
      return Text(
        "Выставлены: ${selectedPlayers.join(", ")}",
        style: const TextStyle(fontSize: 20),
      );
    }

    if (gameState is GameStateVoting) {
      final selectedPlayers = controller.voteCandidates;
      assert(selectedPlayers.isNotEmpty, "No vote candidates (bug?)");
      final onlyOneSelected = selectedPlayers.length == 1;
      final aliveCount = controller.alivePlayersCount;
      final currentPlayerVotes = gameState.currentPlayerVotes ?? 0;
      return Counter(
        key: ValueKey(gameState.currentPlayerNumber),
        min: onlyOneSelected ? aliveCount : 0,
        max: aliveCount - controller.totalVotes,
        onValueChanged: (value) => controller.vote(gameState.currentPlayerNumber, value),
        initialValue: onlyOneSelected ? aliveCount : currentPlayerVotes,
      );
    }

    if (gameState is GameStateDropTableVoting) {
      return Counter(
        key: const ValueKey("dropTableVoting"),
        min: 0,
        max: controller.alivePlayersCount,
        onValueChanged: (value) => controller.vote(null, value),
        initialValue: gameState.votesForDropTable,
      );
    }

    if (gameState case GameStateFinish(winner: final winner)) {
      final resultText = switch (winner) {
        PlayerRole.citizen => "Победа команды мирных жителей",
        PlayerRole.mafia => "Победа команды мафии",
        null => "Ничья",
        _ => throw AssertionError(),
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
                controller.restart();
                if (context.mounted) {
                  unawaited(
                    showSnackBar(context, const SnackBar(content: Text("Игра перезапущена"))),
                  );
                }
              }
            },
            child: const Text("Начать заново", style: TextStyle(fontSize: 20)),
          ),
        ],
      );
    }

    final Duration? timeLimit;
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
    }
    if (timeLimit != null) {
      return PlayerTimer(
        key: ValueKey(controller.state),
        duration: timeLimit,
        onTimerTick: (duration) async {
          if (await Vibration.hasVibrator() != true) {
            return;
          }
          if (duration == Duration.zero) {
            await Vibration.vibrate(duration: 100);
            await Future<void>.delayed(
              const Duration(milliseconds: 300),
            ); // 100 vibration + 200 pause
            await Vibration.vibrate(duration: 100);
          } else if (duration <= const Duration(seconds: 5)) {
            await Vibration.vibrate(duration: 20);
          }
        },
      );
    }
    return const SizedBox.shrink(); // empty widget
  }
}
