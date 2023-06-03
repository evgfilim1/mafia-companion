import "package:flutter/material.dart";

import "../game/player.dart";
import "../utils/ui.dart";

class RolesScreen extends StatefulWidget {
  final List<Player> players;

  const RolesScreen({
    super.key,
    required this.players,
  });

  @override
  State<RolesScreen> createState() => _RolesScreenState();
}

class _RolesScreenState extends State<RolesScreen> {
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text("Раздача ролей"),
        ),
        body: PageView.builder(
          itemCount: widget.players.length,
          itemBuilder: (context, index) {
            final player = widget.players[index];
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
