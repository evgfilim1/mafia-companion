import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:provider/provider.dart";

import "../game/log.dart";
import "../game/player.dart";
import "../game/states.dart";
import "../utils/db/models.dart";
import "../utils/db/repo.dart";
import "../utils/errors.dart";
import "../utils/extensions.dart";
import "../utils/game_controller.dart";
import "../utils/settings.dart";
import "../utils/ui.dart";
import "../utils/updates_checker.dart";
import "../widgets/app_drawer.dart";
import "../widgets/bottom_controls.dart";
import "../widgets/confirmation_dialog.dart";
import "../widgets/game_state.dart";
import "../widgets/notification_dot.dart";
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
    if (kIsWeb || kDebugMode) {
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

  Future<void> _askRestartGame(BuildContext context) async {
    final restartGame = await showDialog<bool>(
      context: context,
      builder: (context) => const RestartGameDialog(),
    );
    if (!context.mounted) {
      throw ContextNotMountedError();
    }
    if (restartGame ?? false) {
      context.read<GameController>().stopGame();
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
      extraActions: [
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
        if (res ?? false) {
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
                MenuItemButton(
                  leadingIcon: const Icon(Icons.sticky_note_2, size: Checkbox.width),
                  onPressed: () => _showNotes(context),
                  child: const Text("Заметки"),
                ),
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

  Future<void> _onTapNext(BuildContext context, GameController controller) async {
    final nextStateAssumption = controller.nextStateAssumption;
    if (nextStateAssumption == null) {
      return;
    }
    controller.setNextState();
    if (nextStateAssumption case GameStateFinish(:final players, :final winner)) {
      final playersContainer = context.read<PlayerList>();
      final saveStats = await showDialog<bool>(
        context: context,
        builder: (context) => const ConfirmationDialog(
          title: Text("Сохранить результаты игры?"),
          content: Text(
            "Результат этой игры будет учтён у каждого зарегистрированного игрока в статистике.",
          ),
        ),
      );
      if (!(saveStats ?? false)) {
        return;
      }
      final bestTurn = controller.gameLog
          .whereType<StateChangeGameLogItem>()
          .map((e) => e.oldState)
          .nonNulls
          .whereType<GameStateBestTurn>()
          .last;
      final guessedMafiaCount =
          bestTurn.playerNumbers.where((e) => players[e - 1].role.team == RoleTeam.mafia).length;
      final dbPlayers =
          await playersContainer.getManyByNicknames(players.map((e) => e.nickname).toList());
      final newStats = <PlayerStats>[];
      for (final (dbPlayer, player) in dbPlayers.zip(players)) {
        if (dbPlayer == null) {
          continue;
        }
        newStats.add(
          dbPlayer.$2.stats.copyWithUpdated(
            playedAs: player.role,
            won: winner == player.role.team,
            warnCount: player.warns,
            wasKicked: player.warns >= 4,
            guessedMafiaCount:
                bestTurn.currentPlayerNumber == player.number ? guessedMafiaCount : 0,
          ),
        );
      }
      await playersContainer.editAll(
        Map.fromEntries(
          dbPlayers.nonNulls
              .zip(newStats)
              .map((e) => MapEntry(e.$1.$1, e.$1.$2.copyWith(stats: e.$2))),
        ),
      );
      if (!context.mounted) {
        return;
      }
      showSnackBar(context, const SnackBar(content: Text("Результаты игры сохранены")));
    }
  }

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
          backLabel: previousState?.prettyName ?? "(недоступно)",
          onTapBack: previousState != null ? controller.setPreviousState : null,
          onTapNext: nextStateAssumption != null ? () => _onTapNext(context, controller) : null,
          nextLabel: nextStateAssumption?.prettyName ?? "(недоступно)",
        ),
      ],
    );
  }
}
