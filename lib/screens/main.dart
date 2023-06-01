import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vibration/vibration.dart';

import '../game/player.dart';
import '../game/states.dart';
import '../game_controller.dart';
import '../settings.dart';
import '../utils.dart';
import '../widgets/bottom_controls.dart';
import '../widgets/counter.dart';
import '../widgets/player_button.dart';
import '../widgets/player_timer.dart';
import 'roles.dart';
import 'settings.dart';

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
  bool _showRole = false;

  void _pushRolesScreen(BuildContext context, GameController controller) {
    final roles = Iterable.generate(10).map((i) => controller.getPlayer(i + 1).role);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RolesScreen(roles: roles.toList()),
      ),
    );
  }

  Future<bool> _showRestartGameDialog(BuildContext context) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Перезапустить игру"),
        content: const Text("Вы уверены? Весь прогресс будет потерян."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Нет"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, true);
              showSnackBar(context, const SnackBar(content: Text("Игра перезапущена")));
            },
            child: const Text("Да"),
          ),
        ],
      ),
    );
    return res!;
  }

  Widget? _getBottomTextWidget(
    BuildContext context,
    GameController controller,
    SettingsModel settings,
  ) {
    final gameState = controller.state;
    if (gameState.stage == GameStage.prepare) {
      return TextButton(
        onPressed: () => _pushRolesScreen(context, controller),
        child: const Text("Раздача ролей", style: TextStyle(fontSize: 20)),
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
      assert(selectedPlayers.isNotEmpty);
      final onlyOneSelected = selectedPlayers.length == 1;
      final aliveCount = controller.alivePlayersCount;
      final currentPlayerVotes = gameState.currentPlayerVotes ?? 0;
      return Counter(
        min: onlyOneSelected ? aliveCount : 0,
        max: aliveCount - controller.totalVotes,
        onValueChanged: (value) => controller.vote(gameState.player.number, value),
        value: onlyOneSelected ? aliveCount : currentPlayerVotes,
      );
    }
    if (gameState.stage == GameStage.finish) {
      final winRole =
          controller.winTeamAssumption! == PlayerRole.citizen ? "мирных жителей" : "мафии";
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Победа команды $winRole", style: const TextStyle(fontSize: 20)),
          TextButton(
            onPressed: () async {
              if (await _showRestartGameDialog(context)) {
                controller.restart();
              }
            },
            child: const Text("Начать заново", style: TextStyle(fontSize: 20)),
          ),
        ],
      );
    }
    if (gameState.stage == GameStage.dropTableVoting) {
      return TextButton(
        onPressed: () {
          controller.deselectAllPlayers();
          controller.setNextState();
        },
        child: const Text("Нет", style: TextStyle(fontSize: 20)),
      );
    }
    final Duration? timeLimit;
    switch (settings.timerType) {
      case TimerType.disabled:
        timeLimit = null;
        break;
      case TimerType.plus5:
        final t = timeLimits[gameState.stage];
        timeLimit = t != null ? t + const Duration(seconds: 5) : null;
        break;
      case TimerType.extended:
        timeLimit = timeLimitsExtended[gameState.stage] ?? timeLimits[gameState.stage];
        break;
      case TimerType.strict:
        timeLimit = timeLimits[gameState.stage];
        break;
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
            Vibration.vibrate(duration: 100);
            await Future.delayed(const Duration(milliseconds: 300)); // 100 vibration + 200 pause
            Vibration.vibrate(duration: 100);
          } else if (duration <= const Duration(seconds: 5)) {
            Vibration.vibrate(duration: 20);
          }
        },
      );
    }
    return null;
  }

  void _onPlayerButtonTap(BuildContext context, GameController controller, int playerNumber) {
    final gameState = controller.state;
    if (gameState is GameStateNightCheck) {
      final String result;
      if (gameState.player.role == PlayerRole.don) {
        if (controller.getPlayer(playerNumber).role == PlayerRole.commissar) {
          result = "КОМИССАР";
        } else {
          result = "НЕ комиссар";
        }
      } else if (gameState.player.role == PlayerRole.commissar) {
        if (controller.getPlayer(playerNumber).role.isMafia) {
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

  void _onWarnPlayerTap(BuildContext context, int playerNumber, GameController controller) {
    controller.warnPlayer(playerNumber);
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

  void _onPlayerActionsTap(
    BuildContext context,
    int playerNumber,
    GameController controller,
  ) async {
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
    if (!context.mounted) {
      throw StateError("Context is not mounted");
    }
    switch (res) {
      case PlayerActions.warnPlus:
        _onWarnPlayerTap(context, playerNumber, controller);
        break;
      case PlayerActions.warnMinus:
        controller.unwarnPlayer(playerNumber);
        break;
      case PlayerActions.kill:
        if (controller.getPlayer(playerNumber).isAlive) {
          controller.killPlayer(playerNumber);
        }
        break;
      case PlayerActions.revive:
        if (!controller.getPlayer(playerNumber).isAlive) {
          controller.revivePlayer(playerNumber);
        }
        break;
    }
    Navigator.pop(context);
  }

  Widget _playerButtonBuilder(BuildContext context, int index, GameController controller) {
    final playerNumber = index + 1;
    final isAlive = controller.getPlayer(playerNumber).isAlive;
    final gameState = controller.state;
    final isActive = switch (gameState) {
      GameState() || GameStateFinish() => false,
      GameStateWithPlayer(player: final player) ||
      GameStateSpeaking(player: final player) ||
      GameStateWithCurrentPlayer(player: final player) ||
      GameStateVoting(player: final player) ||
      GameStateNightCheck(player: final player) =>
        player.number == playerNumber,
      GameStateWithPlayers(players: final players) ||
      GameStateNightKill(mafiaTeam: final players) =>
        players.any((p) => p.number == playerNumber),
    };
    final isSelected = switch (gameState) {
      GameStateSpeaking(accusations: final accusations) =>
        accusations.containsValue(controller.getPlayer(playerNumber)),
      GameStateNightKill(thisNightKilledPlayer: final thisNightKilledPlayer) ||
      GameStateNightCheck(thisNightKilledPlayer: final thisNightKilledPlayer) =>
        thisNightKilledPlayer == controller.getPlayer(playerNumber),
      _ => false,
    };
    return PlayerButton(
      number: playerNumber,
      role: controller.getPlayer(playerNumber).role,
      isAlive: isAlive,
      isSelected: isSelected,
      isActive: isActive,
      warnCount: controller.getPlayerWarnCount(playerNumber),
      onTap: isAlive || gameState.stage == GameStage.nightCheck
          ? () => _onPlayerButtonTap(context, controller, playerNumber)
          : null,
      longPressActions: [
        TextButton(
          onPressed: () => _onPlayerActionsTap(context, playerNumber, controller),
          child: const Text("Действия"),
        ),
      ],
      showRole: _showRole,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    final gameState = controller.state;
    final isGameRunning = !gameState.stage.isAnyOf([GameStage.prepare, GameStage.finish]);
    final nextStateAssumption = controller.nextStateAssumption;
    final settings = context.watch<SettingsModel>();
    final packageInfo = context.watch<PackageInfo>();
    final previousState = controller.previousState;
    return Scaffold(
      appBar: AppBar(
        title: isGameRunning ? Text("День ${controller.state.day}") : Text(packageInfo.appName),
        actions: [
          IconButton(
            onPressed: () => setState(() => _showRole = !_showRole),
            tooltip: "${!_showRole ? "Показать" : "Скрыть"} роли",
            icon: const Icon(Icons.person_search),
          ),
          IconButton(
            icon: const Icon(Icons.restart_alt),
            tooltip: "Перезапустить игру",
            onPressed: () async {
              if (await _showRestartGameDialog(context)) {
                controller.restart();
              }
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              child: Center(
                child: Text(
                  packageInfo.appName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("Раздача ролей"),
              onTap: () {
                Navigator.pop(context);
                _pushRolesScreen(context, controller);
              },
            ),
            ListTile(
              leading: const Icon(Icons.format_list_numbered),
              title: const Text("Официальные правила"),
              onTap: () => launchUrl(
                Uri.parse("https://mafiaworldtour.com/fiim-rules"),
                mode: LaunchMode.externalApplication, // it crashes for me otherwise for some reason
              ).then((isOk) {
                Navigator.pop(context);
                if (isOk) {
                  return;
                }
                showSnackBar(
                  context,
                  SnackBar(
                    content: const Text("Не удалось открыть ссылку"),
                    action: SnackBarAction(
                        label: "Скопировать",
                        onPressed: () {
                          Clipboard.setData(
                            const ClipboardData(text: "https://mafiaworldtour.com/fiim-rules"),
                          );
                          showSnackBar(
                            context,
                            const SnackBar(
                              content: Text("Ссылка скопирована в буфер обмена"),
                            ),
                          );
                        }),
                  ),
                );
              }),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Настройки"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            )
          ],
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 200, // maxCrossAxisExtent * 2
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 100,
              ),
              itemCount: controller.totalPlayersCount,
              itemBuilder: (context, index) => _playerButtonBuilder(context, index, controller),
            ),
          ),
          Expanded(
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        gameState.prettyName,
                        style: const TextStyle(fontSize: 32),
                        textAlign: TextAlign.center,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: _getBottomTextWidget(context, controller, settings),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 40,
                  width: MediaQuery.of(context).size.width,
                  child: BottomControlBar(
                    backLabel: settings.cancellable
                        ? previousState?.prettyName ?? "(отмена невозможна)"
                        : "(отключено)",
                    onTapBack: settings.cancellable && previousState != null
                        ? () => controller.setPreviousState()
                        : null,
                    onTapNext: nextStateAssumption != null ? () => controller.setNextState() : null,
                    nextLabel: nextStateAssumption?.prettyName ?? "(игра окончена)",
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
