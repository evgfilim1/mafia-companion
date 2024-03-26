import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../utils/game_controller.dart";
import "../utils/ui.dart";

class RolesScreen extends StatelessWidget {
  const RolesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    final players = controller.players;
    assert(players.isNotEmpty, "Players must be non-empty. Is the game running?");
    return Scaffold(
      appBar: AppBar(
        title: const Text("Раздача ролей"),
      ),
      body: PageView.builder(
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
      ),
    );
  }
}
