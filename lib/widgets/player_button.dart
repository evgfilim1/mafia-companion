import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../game/player.dart";
import "../utils/game_controller.dart";
import "../utils/ui.dart";

class PlayerButton extends StatelessWidget {
  final int playerNumber;
  final bool isSelected;
  final bool isActive;
  final bool showRole;
  final VoidCallback? onTap;

  const PlayerButton({
    super.key,
    required this.playerNumber,
    required this.isSelected,
    this.isActive = false,
    this.showRole = false,
    this.onTap,
  });

  void _onLongPress(BuildContext context, GameController controller, Player player) {
    final isAliveText = player.isAlive ? "Жив" : "Мёртв";
    showDialog<void>(
      context: context,
      builder: (context) {
        final controller = context.watch<GameController>();
        final player = controller.getPlayerByNumber(playerNumber);
        return AlertDialog(
          title: Text("Игрок ${player.number}"),
          content: Text(
            "Состояние: $isAliveText\n"
            "Роль: ${player.role.prettyName}\n"
            "Фолов: ${player.warns}",
          ),
          actions: [
            MenuAnchor(
              menuChildren: [
                MenuItemButton(
                  child: const Text("+ Фол"),
                  onPressed: () => controller.warnPlayer(playerNumber),
                ),
                MenuItemButton(
                  child: const Text("- Фол"),
                  onPressed: () => controller.warnMinusPlayer(playerNumber),
                ),
                MenuItemButton(
                  child: const Text("Дисквалификация"),
                  onPressed: () => controller.kickPlayer(playerNumber),
                ),
                MenuItemButton(
                  child: const Text("ППК"),
                  onPressed: () => controller.kickPlayerTeam(playerNumber),
                ),
              ],
              builder: (context, menuController, _) => TextButton(
                onPressed: () {
                  if (menuController.isOpen) {
                    menuController.close();
                  } else {
                    menuController.open();
                  }
                },
                child: const Text("Действия"),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Закрыть"),
            ),
          ],
        );
      },
    );
  }

  Color? _getBorderColor(BuildContext context, Player player) {
    if (isActive) {
      return Theme.of(context).colorScheme.primary;
    }
    if (isSelected) {
      return Colors.green;
    }
    return null;
  }

  Color? _getBackgroundColor(Player player) {
    if (!player.isAlive) {
      return Colors.red.withOpacity(0.25);
    }
    return null;
  }

  Color? _getForegroundColor(Player player) {
    if (isSelected) {
      return Colors.green;
    }
    if (!player.isAlive) {
      return Colors.red;
    }
    return null;
  }

  String _getRoleSuffix(Player player) {
    if (!showRole) {
      return "";
    }
    if (player.role == PlayerRole.citizen) {
      return "";
    } else if (player.role == PlayerRole.mafia) {
      return "М";
    } else if (player.role == PlayerRole.don) {
      return "ДМ";
    } else if (player.role == PlayerRole.sheriff) {
      return "Ш";
    } else {
      throw AssertionError("Unknown role: ${player.role}");
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    final player = controller.getPlayerByNumber(playerNumber);
    final borderColor = _getBorderColor(context, player);
    final cardText = "${player.number}${_getRoleSuffix(player)}";
    return Stack(
      children: [
        ElevatedButton(
          style: ButtonStyle(
            shape: MaterialStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            side: borderColor != null
                ? MaterialStateProperty.all(
                    BorderSide(
                      color: borderColor,
                      width: 1,
                    ),
                  )
                : null,
            backgroundColor: MaterialStateProperty.all(_getBackgroundColor(player)),
            foregroundColor: MaterialStateProperty.all(_getForegroundColor(player)),
          ),
          onPressed: onTap,
          onLongPress: () => _onLongPress(context, controller, player),
          child: Center(child: Text(cardText, textAlign: TextAlign.center)),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: Text(
            player.warns < 4 ? "!" * player.warns : "x",
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }
}
