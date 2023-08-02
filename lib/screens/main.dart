import "dart:async";

import "package:flutter/material.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:provider/provider.dart";

import "../game/states.dart";
import "../utils/extensions.dart";
import "../utils/game_controller.dart";
import "../utils/ui.dart";
import "../widgets/app_drawer.dart";
import "../widgets/bottom_controls.dart";
import "../widgets/exit_dialog.dart";
import "../widgets/game_state.dart";
import "../widgets/orientation_dependent.dart";
import "../widgets/player_buttons.dart";
import "../widgets/restart_dialog.dart";

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  var _showRoles = false;
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _askRestartGame(BuildContext context) async {
    final restartGame = await showDialog<bool>(
      context: context,
      builder: (context) => const RestartGameDialog(),
    );
    if (context.mounted && (restartGame ?? false)) {
      context.read<GameController>().restart();
      unawaited(showSnackBar(context, const SnackBar(content: Text("Игра перезапущена"))));
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
    final packageInfo = context.watch<PackageInfo>();

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
              onPressed: () => Navigator.pushNamed(context, "/log"),
              tooltip: "Журнал игры",
              icon: const Icon(Icons.list),
            ),
            IconButton(
              onPressed: () => _showNotes(context),
              tooltip: "Заметки",
              icon: const Icon(Icons.sticky_note_2),
            ),
            IconButton(
              onPressed: () => setState(() => _showRoles = !_showRoles),
              tooltip: "${!_showRoles ? "Показать" : "Скрыть"} роли",
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
        body: _RotatableMainScreenBody(showRoles: _showRoles),
      ),
    );
  }
}

class _RotatableMainScreenBody extends OrientationDependentWidget {
  final bool showRoles;

  const _RotatableMainScreenBody({
    super.key,
    this.showRoles = false,
  });

  @override
  Widget buildPortrait(BuildContext context) => Column(
        children: [
          PlayerButtons(showRoles: showRoles),
          const Flexible(child: _MainScreenMainBodyContent()),
        ],
      );

  @override
  Widget buildLandscape(BuildContext context) => Row(
        children: [
          PlayerButtons(showRoles: showRoles),
          const Flexible(child: _MainScreenMainBodyContent()),
        ],
      );
}

class _MainScreenMainBodyContent extends StatelessWidget {
  const _MainScreenMainBodyContent({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    final previousState = controller.previousState;
    final nextStateAssumption = controller.nextStateAssumption;

    return Column(
      children: [
        const Expanded(child: Center(child: GameStateInfo())),
        BottomControlBar(
          backLabel: previousState?.prettyName ?? "(отмена невозможна)",
          onTapBack: previousState != null ? controller.setPreviousState : null,
          onTapNext: nextStateAssumption != null ? controller.setNextState : null,
          nextLabel: nextStateAssumption?.prettyName ?? "(игра окончена)",
        ),
      ],
    );
  }
}
