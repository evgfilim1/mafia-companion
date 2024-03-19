import "dart:math";

import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../game/player.dart";
import "../utils/game_controller.dart";
import "../utils/log.dart";
import "../utils/ui.dart";

class RolesScreen extends StatelessWidget {
  static final _log = Logger("RolesScreen");

  const RolesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    final players = controller.isGameInitialized
        ? controller.players
        : controller.rolesSeed != null
            ? generatePlayers(random: Random(controller.rolesSeed), nicknames: controller.nicknames)
            : const <Player>[];
    if (players.isEmpty) {
      _log.warning("Players is empty");
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text("Раздача ролей"),
      ),
      body: players.isNotEmpty
          ? PageView.builder(
              itemCount: players.length,
              itemBuilder: (context, index) {
                final player = players[index];
                final String topText;
                if (player.nickname != null) {
                  topText = "${player.nickname} (Игрок #${player.number})";
                } else {
                  topText = "Игрок #${player.number}";
                }
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        topText,
                        style: const TextStyle(fontSize: 20),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        player.role.prettyName,
                        style: const TextStyle(fontSize: 48),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            )
          : const Center(child: Text(r"¯\_(ツ)_/¯", style: TextStyle(fontSize: 48))),
    );
  }
}
