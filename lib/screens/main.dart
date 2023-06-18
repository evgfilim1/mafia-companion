import "package:flutter/material.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:provider/provider.dart";

import "../game/player.dart";
import "../game/states.dart";
import "../game_controller.dart";
import "../utils/extensions.dart";
import "../utils/ui.dart";
import "../widgets/app_drawer.dart";
import "../widgets/bottom_controls.dart";
import "../widgets/exit_dialog.dart";
import "../widgets/game_state.dart";
import "../widgets/player_button.dart";
import "../widgets/restart_dialog.dart";

enum PlayerActions {
  warnPlus("Дать предупреждение"),
  warnMinus("Снять предупреждение"),
  kill("Убить"),
  revive("Воскресить"),
  ;

  final String text;

  const PlayerActions(this.text);
}

class MainScreen extends StatefulWidget {
  const MainScreen({
    super.key,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  var _showRole = false;
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _onPlayerButtonTap(BuildContext context, int playerNumber) {
    final controller = context.read<GameController>();
    if (controller.state
        case GameStateNightCheck(player: Player(isAlive: final isAlive, role: final role))) {
      if (!isAlive) {
        return; // It's useless to allow dead players check others
      }
      final String result;
      if (role == PlayerRole.don) {
        if (controller.getPlayerByNumber(playerNumber).role == PlayerRole.sheriff) {
          result = "ШЕРИФ";
        } else {
          result = "НЕ шериф";
        }
      } else if (role == PlayerRole.sheriff) {
        if (controller.getPlayerByNumber(playerNumber).role.isMafia) {
          result = "МАФИЯ";
        } else {
          result = "НЕ мафия";
        }
      } else {
        throw AssertionError();
      }
      showSimpleDialog(
        context: context,
        title: const Text("Результат проверки"),
        content: Text("Игрок $playerNumber — $result"),
      );
    } else {
      controller.togglePlayerSelected(playerNumber);
    }
  }

  void _onWarnPlayerTap(BuildContext context, int playerNumber) {
    final controller = context.read<GameController>()..warnPlayer(playerNumber);
    showSnackBar(
      context,
      SnackBar(
        content: Text("Выдано предупреждение игроку $playerNumber"),
        action: SnackBarAction(
          label: "Отменить",
          onPressed: () => controller.unwarnPlayer(playerNumber),
        ),
      ),
    );
  }

  Future<void> _onPlayerActionsTap(BuildContext context, int playerNumber) async {
    final controller = context.read<GameController>();
    final res = await showChoiceDialog(
      context: context,
      items: PlayerActions.values,
      itemToString: (i) => i.text,
      title: Text("Действия для игрока $playerNumber"),
      selectedIndex: null,
    );
    if (res == null) {
      return;
    }
    // https://dart-lang.github.io/linter/lints/use_build_context_synchronously.html
    // False positive on `!context.mounted` here
    // ignore: use_build_context_synchronously
    if (!context.mounted) {
      throw StateError("Context is not mounted");
    }
    switch (res) {
      case PlayerActions.warnPlus:
        _onWarnPlayerTap(context, playerNumber);
      case PlayerActions.warnMinus:
        controller.unwarnPlayer(playerNumber);
      case PlayerActions.kill:
        if (controller.getPlayerByNumber(playerNumber).isAlive) {
          controller.killPlayer(playerNumber);
        }
      case PlayerActions.revive:
        if (!controller.getPlayerByNumber(playerNumber).isAlive) {
          controller.revivePlayer(playerNumber);
        }
    }
    Navigator.pop(context);
  }

  Widget _playerButtonBuilder(BuildContext context, int index) {
    final controller = context.watch<GameController>();
    final currentPlayer = controller.players[index];
    final playerNumber = currentPlayer.number;
    final gameState = controller.state;
    final isActive = switch (gameState) {
      GameState() || GameStateFinish() => false,
      GameStateWithPlayer(player: final player) ||
      GameStateSpeaking(player: final player) ||
      GameStateWithCurrentPlayer(player: final player) ||
      GameStateVoting(player: final player) ||
      GameStateNightCheck(player: final player) =>
        player == currentPlayer,
      GameStateWithPlayers(players: final players) ||
      GameStateNightKill(mafiaTeam: final players) ||
      GameStateDropTableVoting(players: final players) =>
        players.contains(currentPlayer),
    };
    final isSelected = switch (gameState) {
      GameStateSpeaking(accusations: final accusations) => accusations.containsValue(currentPlayer),
      GameStateNightKill(thisNightKilledPlayer: final thisNightKilledPlayer) ||
      GameStateNightCheck(thisNightKilledPlayer: final thisNightKilledPlayer) =>
        thisNightKilledPlayer == currentPlayer,
      _ => false,
    };

    return PlayerButton(
      player: currentPlayer,
      isSelected: isSelected,
      isActive: isActive,
      warnCount: controller.getPlayerWarnCount(playerNumber),
      onTap: currentPlayer.isAlive || gameState.stage == GameStage.nightCheck
          ? () => _onPlayerButtonTap(context, playerNumber)
          : null,
      longPressActions: [
        TextButton(
          onPressed: () => _onPlayerActionsTap(context, playerNumber),
          child: const Text("Действия"),
        ),
      ],
      showRole: _showRole,
    );
  }

  Future<void> _askRestartGame(BuildContext context) async {
    final restartGame = await showDialog<bool>(
      context: context,
      builder: (context) => const RestartGameDialog(),
    );
    if (context.mounted && (restartGame ?? false)) {
      context.read<GameController>().restart();
      showSnackBar(context, const SnackBar(content: Text("Игра перезапущена")));
    }
  }

  void _showNotes(BuildContext context) {
    showSimpleDialog(
      context: context,
      title: const Text("Заметки"),
      content: TextField(
        controller: _notesController,
        maxLines: null,
      ),
      actions: [
        TextButton(
          onPressed: _notesController.clear,
          child: const Text("Очистить"),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    final gameState = controller.state;
    final isGameRunning = !gameState.stage.isAnyOf([GameStage.prepare, GameStage.finish]);
    final nextStateAssumption = controller.nextStateAssumption;
    final packageInfo = context.watch<PackageInfo>();
    final previousState = controller.previousState;

    return WillPopScope(
      onWillPop: () async {
        if (controller.state.stage == GameStage.prepare) {
          return true;
        }
        final res = await showDialog<bool>(
          context: context,
          builder: (context) => const ExitDialog(),
        );
        return res ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: isGameRunning ? Text("День ${controller.state.day}") : Text(packageInfo.appName),
          actions: [
            IconButton(
              onPressed: () => _showNotes(context),
              tooltip: "Заметки",
              icon: const Icon(Icons.sticky_note_2),
            ),
            IconButton(
              onPressed: () => setState(() => _showRole = !_showRole),
              tooltip: "${!_showRole ? "Показать" : "Скрыть"} роли",
              icon: const Icon(Icons.person_search),
            ),
            IconButton(
              onPressed: () => _askRestartGame(context),
              tooltip: "Перезапустить игру",
              icon: const Icon(Icons.restart_alt),
            ),
          ],
        ),
        drawer: const AppDrawer(),
        body: Column(
          // TODO: fix layout, it's weird
          children: [
            SizedBox(
              height: 200, // maxCrossAxisExtent * 2
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 100,
                ),
                itemCount: controller.totalPlayersCount,
                itemBuilder: _playerButtonBuilder,
              ),
            ),
            Expanded(
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  const Center(child: GameStateInfo()),
                  Positioned(
                    bottom: 40,
                    width: MediaQuery.of(context).size.width,
                    child: BottomControlBar(
                      backLabel: previousState?.prettyName ?? "(отмена невозможна)",
                      onTapBack: previousState != null ? controller.setPreviousState : null,
                      onTapNext: nextStateAssumption != null ? controller.setNextState : null,
                      nextLabel: nextStateAssumption?.prettyName ?? "(игра окончена)",
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
