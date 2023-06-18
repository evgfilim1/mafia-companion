import "package:flutter/material.dart";

import "../game/player.dart";
import "../utils/ui.dart";

class PlayerButton extends StatelessWidget {
  final Player player;
  final bool isSelected;
  final bool isActive;
  final int warnCount;
  final VoidCallback? onTap;
  final List<Widget> longPressActions;
  final bool showRole;

  const PlayerButton({
    super.key,
    required this.player,
    required this.isSelected,
    this.isActive = false,
    required this.warnCount,
    this.onTap,
    this.longPressActions = const [],
    this.showRole = false,
  });

  void _onLongPress(BuildContext context) {
    final isAliveText = player.isAlive ? "Жив" : "Мёртв";
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Игрок ${player.number}"),
        content: Text(
          "Состояние: $isAliveText\n"
          "Роль: ${player.role.prettyName}\n"
          "Предупреждений: $warnCount",
        ),
        actions: [
          ...longPressActions,
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Закрыть"),
          ),
        ],
      ),
    );
  }

  Color? _getBorderColor(BuildContext context) {
    if (isActive) {
      return Theme.of(context).colorScheme.primary;
    }
    if (isSelected) {
      return Colors.green;
    }
    return null;
  }

  Color? _getBackgroundColor(BuildContext context) {
    if (!player.isAlive) {
      return Colors.red.withOpacity(0.25);
    }
    return null;
  }

  Color? _getForegroundColor(BuildContext context) {
    if (isSelected) {
      return Colors.green;
    }
    if (!player.isAlive) {
      return Colors.red;
    }
    return null;
  }

  String _getRoleSuffix() {
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
    final borderColor = _getBorderColor(context);
    final cardText = "${player.number}${_getRoleSuffix()}";
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Stack(
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
              backgroundColor: MaterialStateProperty.all(_getBackgroundColor(context)),
              foregroundColor: MaterialStateProperty.all(_getForegroundColor(context)),
            ),
            onPressed: onTap,
            onLongPress: () => _onLongPress(context),
            child: Center(child: Text(cardText)),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: Text(
              "!" * warnCount,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
