import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../game/player.dart";
import "../game/states.dart";
import "../utils/game_controller.dart";
import "../utils/ui.dart";
import "orientation_dependent.dart";
import "player_button.dart";

enum PlayerActions {
  warnPlus("Дать предупреждение"),
  warnMinus("Снять предупреждение"),
  kill("Убить"),
  revive("Воскресить"),
  ;

  final String text;

  const PlayerActions(this.text);
}

class PlayerButtons extends OrientationDependentWidget {
  final bool showRoles;

  const PlayerButtons({
    super.key,
    this.showRoles = false,
  });

  void _onPlayerButtonTap(BuildContext context, Player player) {
    final controller = context.read<GameController>();
    if (controller.state
        case GameStateNightCheck(player: Player(isAlive: final isAlive, role: final role))) {
      if (!isAlive) {
        return; // It's useless to allow dead players check others
      }
      final String result;
      if (role == PlayerRole.don) {
        if (player.role == PlayerRole.sheriff) {
          result = "ШЕРИФ";
        } else {
          result = "НЕ шериф";
        }
      } else if (role == PlayerRole.sheriff) {
        if (player.role.isMafia) {
          result = "МАФИЯ 👎";
        } else {
          result = "НЕ мафия 👍";
        }
      } else {
        throw AssertionError();
      }
      showSimpleDialog(
        context: context,
        title: const Text("Результат проверки"),
        content: Text("Игрок ${player.number} — $result"),
      );
    } else {
      controller.togglePlayerSelected(player.number);
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

  Future<void> _onPlayerActionsTap(BuildContext context, Player player) async {
    final controller = context.read<GameController>();
    final res = await showChoiceDialog(
      context: context,
      items: PlayerActions.values,
      itemToString: (i) => i.text,
      title: Text("Действия для игрока ${player.number}"),
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
        _onWarnPlayerTap(context, player.number);
      case PlayerActions.warnMinus:
        controller.unwarnPlayer(player.number);
      case PlayerActions.kill:
        if (player.isAlive) {
          controller.killPlayer(player.number);
        }
      case PlayerActions.revive:
        if (!player.isAlive) {
          controller.revivePlayer(player.number);
        }
    }
    Navigator.pop(context);
  }

  Widget _buildPlayerButton(BuildContext context, Player player, BaseGameState gameState) {
    final controller = context.watch<GameController>();
    final isActive = switch (gameState) {
      GameState() || GameStateFinish() => false,
      GameStateWithPlayer(player: final p) ||
      GameStateSpeaking(player: final p) ||
      GameStateWithCurrentPlayer(player: final p) ||
      GameStateVoting(player: final p) ||
      GameStateNightCheck(player: final p) =>
        p == player,
      GameStateWithPlayers(players: final players) ||
      GameStateNightKill(mafiaTeam: final players) ||
      GameStateDropTableVoting(players: final players) =>
        players.any((p) => p.number == player.number),
    };
    final isSelected = switch (gameState) {
      GameStateSpeaking(accusations: final accusations) => accusations.containsValue(player),
      GameStateNightKill(thisNightKilledPlayer: final thisNightKilledPlayer) ||
      GameStateNightCheck(thisNightKilledPlayer: final thisNightKilledPlayer) =>
        thisNightKilledPlayer == player,
      _ => false,
    };
    return PlayerButton(
      player: player,
      isSelected: isSelected,
      isActive: isActive,
      warnCount: controller.getPlayerWarnCount(player.number),
      onTap: player.isAlive || gameState.stage == GameStage.nightCheck
          ? () => _onPlayerButtonTap(context, player)
          : null,
      longPressActions: [
        TextButton(
          onPressed: () => _onPlayerActionsTap(context, player),
          child: const Text("Действия"),
        ),
      ],
      showRole: showRoles,
    );
  }

  @override
  Widget buildPortrait(BuildContext context) {
    final controller = context.watch<GameController>();
    const itemsPerRow = 5;
    final totalPlayers = controller.totalPlayersCount;
    final size = (MediaQuery.of(context).size.width / itemsPerRow).floorToDouble();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < totalPlayers; i += itemsPerRow)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var j = i; j < i + itemsPerRow && j < totalPlayers; j++)
                SizedBox(
                  width: size,
                  height: size,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: _buildPlayerButton(context, controller.players[j], controller.state),
                  ),
                ),
            ],
          )
      ],
    );
  }

  @override
  Widget buildLandscape(BuildContext context) {
    final controller = context.watch<GameController>();
    const itemsPerRow = 5;
    final totalPlayers = controller.totalPlayersCount;
    final size = (MediaQuery.of(context).size.height / itemsPerRow).floorToDouble() - 18;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < totalPlayers; i += itemsPerRow)
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var j = i; j < i + itemsPerRow && j < totalPlayers; j++)
                SizedBox(
                  width: size + 24,
                  height: size,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: _buildPlayerButton(
                      context,
                      controller.players[i.isEven ? i + itemsPerRow + i - j - 1 : j],
                      controller.state,
                    ),
                  ),
                ),
            ],
          )
      ],
    );
  }
}
