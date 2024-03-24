import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../game/player.dart";
import "../utils/db/repo.dart";
import "../utils/extensions.dart";
import "../utils/ui.dart";

class PlayerStatsScreen extends StatelessWidget {
  final int playerKey;

  const PlayerStatsScreen({
    super.key,
    required this.playerKey,
  });

  @override
  Widget build(BuildContext context) {
    final players = context.watch<PlayerList>();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Статистика игрока"),
      ),
      body: FutureBuilder(
        future: players.get(playerKey),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("Игрок не найден"));
          }
          final player = snapshot.data!;
          final stats = player.stats;
          var name = player.nickname;
          if (player.realName.isNotEmpty) {
            name += " (${player.realName})";
          }
          return ListView(
            children: [
              ListTile(
                title: const Text("Игрок"),
                subtitle: Text(name),
              ),
              ListTile(
                title: const Text("Всего побед"),
                subtitle: Text("${stats.winsByRole.values.sum}/${stats.gamesByRole.values.sum}"),
              ),
              for (final role in PlayerRole.values)
                ListTile(
                  title: Text("Побед за роль ${role.prettyName}"),
                  subtitle: Text("${stats.winsByRole[role]}/${stats.gamesByRole[role]}"),
                ),
              ListTile(
                title: const Text("Всего предупреждений"),
                subtitle: Text(stats.totalWarns.toString()),
              ),
              ListTile(
                title: const Text("Всего дисквалификаций"),
                subtitle: Text(stats.totalKicks.toString()),
              ),
              ListTile(
                title: const Text("Всего угаданных мафий в ЛХ"),
                subtitle: Text(stats.totalGuessedMafia.toString()),
              ),
            ],
          );
        },
      ),
    );
  }
}
