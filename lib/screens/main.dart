import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:provider/provider.dart";

import "../utils/game_controller.dart";
import "../utils/misc.dart";
import "../utils/settings.dart";
import "../utils/ui.dart";
import "../utils/updates_checker.dart";
import "../widgets/app_drawer.dart";
import "../widgets/bottom_controls.dart";
import "../widgets/confirm_pop_scope.dart";
import "../widgets/confirmation_dialog.dart";
import "../widgets/game_state.dart";
import "../widgets/notes_menu_item_button.dart";
import "../widgets/notification_dot.dart";
import "../widgets/player_buttons.dart";
import "../widgets/restart_game_icon_button.dart";

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  var _showRoles = false;
  final _notes = TextEditingController();
  var _warnMode = false;

  @override
  void initState() {
    unawaited(_checkForUpdates());
    super.initState();
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _checkForUpdates() async {
    if ((kIsWeb || kIsDev) && !kEnableUpdater) {
      return;
    }
    final checker = context.read<UpdatesChecker>();
    final settings = context.read<SettingsModel>();
    if (settings.checkUpdatesType != CheckUpdatesType.onLaunch) {
      return;
    }
    final update = await checker.checkForUpdates();
    if (update == null) {
      return;
    }
    if (!mounted) {
      return;
    }
    showSnackBar(
      context,
      SnackBar(
        content: const Text("Доступна новая версия приложения"),
        action: SnackBarAction(
          label: "Обновить",
          onPressed: () => showUpdateDialog(context),
        ),
      ),
    );
  }

  void _resetWarnMode() => setState(() => _warnMode = false);

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    final packageInfo = context.watch<PackageInfo>();
    final checker = context.watch<UpdatesChecker>();

    return ConfirmPopScope(
      canPop: !controller.isGameActive,
      dialog: const ConfirmationDialog(
        title: Text("Выход из игры"),
        content: Text("Вы уверены, что хотите выйти из игры? Все данные будут потеряны."),
      ),
      onPopConfirmed: SystemNavigator.pop,
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
              onPressed:
                  controller.isGameActive ? () => setState(() => _warnMode = !_warnMode) : null,
              icon: const Icon(Icons.report),
              tooltip: _warnMode ? "Вернуться в нормальный режим" : "Включить режим выдачи фолов",
              color: _warnMode ? Colors.red : null,
            ),
            const RestartGameIconButton(),
            MenuAnchor(
              builder: (context, controller, child) => IconButton(
                onPressed: () {
                  if (controller.isOpen) {
                    controller.close();
                  } else {
                    controller.open();
                  }
                },
                icon: Icon(Icons.adaptive.more),
                tooltip: MaterialLocalizations.of(context).showMenuTooltip,
              ),
              menuChildren: [
                MenuItemButton(
                  leadingIcon: const Icon(Icons.list, size: Checkbox.width),
                  onPressed: () => Navigator.pushNamed(context, "/log"),
                  child: const Text("Журнал игры"),
                ),
                NotesMenuItemButton(context: context, controller: _notes),
                CheckboxMenuButton(
                  value: _showRoles,
                  onChanged: (value) => setState(() => _showRoles = value ?? false),
                  closeOnActivate: false,
                  child: const Text("Показывать роли"),
                ),
              ],
            ),
          ],
        ),
        drawer: const AppDrawer(),
        body: _RotatableMainScreenBody(
          showRoles: _showRoles,
          warnOnTap: _warnMode,
          onPrevStateTap: _resetWarnMode,
          onNextStateTap: _resetWarnMode,
        ),
      ),
    );
  }
}

class _RotatableMainScreenBody extends StatelessWidget {
  final bool showRoles;
  final bool warnOnTap;
  final VoidCallback? onPrevStateTap;
  final VoidCallback? onNextStateTap;

  const _RotatableMainScreenBody({
    required this.showRoles,
    required this.warnOnTap,
    this.onPrevStateTap,
    this.onNextStateTap,
  });

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    final children = <Widget>[
      if (controller.isGameInitialized) PlayerButtons(showRoles: showRoles, warnOnTap: warnOnTap),
      Expanded(
        child: Column(
          children: [
            const Expanded(child: Center(child: GameStateInfo())),
            if (controller.isGameInitialized)
              GameBottomControlBar(
                onTapBack: onPrevStateTap,
                onTapNext: onNextStateTap,
              ),
          ],
        ),
      ),
    ];
    return OrientationBuilder(
      builder: (context, orientation) => switch (orientation) {
        Orientation.portrait => Column(children: children),
        Orientation.landscape => Row(children: children),
      },
    );
  }
}
