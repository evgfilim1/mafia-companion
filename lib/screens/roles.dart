import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../utils/game_controller.dart";
import "../utils/ui.dart";

class RolesScreen extends StatelessWidget {
  const RolesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final players = context.watch<GameController>().players;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Раздача ролей"),
      ),
      body: PageView.builder(
        itemCount: players.length,
        itemBuilder: (context, index) {
          final player = players[index];
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Игрок #${player.number}", style: const TextStyle(fontSize: 48)),
                Text(
                  "Твоя роль — ${player.role.prettyName}",
                  style: const TextStyle(fontSize: 20),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
