import "dart:async";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:provider/provider.dart";

import "../utils/game_controller.dart";
import "../utils/settings.dart";
import "../utils/ui.dart";
import "../utils/updates_checker.dart";
import "../widgets/app_drawer.dart";
import "../widgets/bottom_controls.dart";
import "../widgets/confirmation_dialog.dart";
import "../widgets/debug_menu_dialog.dart";
import "../widgets/game_state.dart";
import "../widgets/notification_dot.dart";
import "../widgets/orientation_dependent.dart";
import "../widgets/player_buttons.dart";
import "../widgets/restart_dialog.dart";

enum _PopupMenuItems {
  log,
  notes,
  roles,
  debug,
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  var _showRoles = false;
  final _notesController = TextEditingController();

  @override
  void initState() {
    unawaited(_checkForUpdates());
    super.initState();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _checkForUpdates() async {
    if (context.read<SettingsModel>().checkUpdatesType != CheckUpdatesType.onLaunch) {
      return;
    }
    final checker = context.read<UpdatesChecker>();
    final update = await checker.checkForUpdates();
    if (update == null) {
      return;
    }
    if (!context.mounted) {
      return;
    }
    showSnackBar(
      context,
      SnackBar(
        content: const Text("Доступна новая версия приложения"),
        action: SnackBarAction(
          label: "Обновить",
          onPressed: () => showUpdateDialog(context, update),
        ),
      ),
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
    final packageInfo = context.watch<PackageInfo>();
    final checker = context.watch<UpdatesChecker>();

    return PopScope(
      canPop: !controller.isGameActive,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final res = await showDialog<bool>(
          context: context,
          builder: (context) => const ConfirmationDialog(
            title: Text("Выход из игры"),
            content: Text("Вы уверены, что хотите выйти из игры? Все данные будут потеряны."),
          ),
        );
        if ((res ?? false) && context.mounted) {
          // exit flutter app
          await SystemNavigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: controller.isGameActive
              ? Text("День ${controller.state.day}")
              : Text(packageInfo.appName),
          leading: Builder(
            builder: (context) => IconButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
              icon: Stack(
                children: [
                  const Icon(Icons.menu),
                  if (checker.hasUpdate)
                    const Positioned(right: 0, child: NotificationDot(size: 8)),
                ],
              ),
            ),
          ),
          actions: [
            IconButton(
              onPressed: () => _askRestartGame(context),
              tooltip: "Перезапустить игру",
              icon: const Icon(Icons.restart_alt),
            ),
            PopupMenuButton<_PopupMenuItems>(
              onSelected: (value) {
                switch (value) {
                  case _PopupMenuItems.log:
                    Navigator.pushNamed(context, "/log");
                  case _PopupMenuItems.notes:
                    _showNotes(context);
                  case _PopupMenuItems.roles:
                    setState(() => _showRoles = !_showRoles);
                  case _PopupMenuItems.debug:
                    showDialog<void>(
                      context: context,
                      builder: (context) => const DebugMenuDialog(),
                    );
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: _PopupMenuItems.log,
                  child: ListTile(
                    leading: Icon(Icons.list),
                    title: Text("Журнал игры"),
                  ),
                ),
                const PopupMenuItem(
                  value: _PopupMenuItems.notes,
                  child: ListTile(
                    leading: Icon(Icons.sticky_note_2),
                    title: Text("Заметки"),
                  ),
                ),
                CheckedPopupMenuItem(
                  value: _PopupMenuItems.roles,
                  checked: _showRoles,
                  child: const Text("Показывать роли"),
                ),
                const PopupMenuItem(
                  value: _PopupMenuItems.debug,
                  child: ListTile(
                    leading: Icon(Icons.bug_report),
                    title: Text("Отладочное меню"),
                  ),
                ),
              ],
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
  const _MainScreenMainBodyContent();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    final previousState = controller.previousState;
    final nextStateAssumption = controller.nextStateAssumption;

    return Column(
      children: [
        // FIXME: timer resets when the screen is rotated
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
