import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../game/player.dart";
import "../utils/db/repo.dart";
import "../utils/extensions.dart";
import "../utils/ui.dart";

class PlayerStatsScreen extends StatelessWidget {
  final String playerID;

  const PlayerStatsScreen({
    super.key,
    required this.playerID,
  });

  @override
  Widget build(BuildContext context) {
    final players = context.watch<PlayerRepo>();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Статистика игрока"),
      ),
      body: FutureBuilder(
        future: players.get(playerID),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.requireData == null) {
            return const Center(child: Text("Игрок не найден"));
          }
          final pws = snapshot.requireData!;
          final stats = pws.stats;
          var name = pws.player.nickname;
          if (pws.player.realName.isNotEmpty) {
            name += " (${pws.player.realName})";
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
                title: const Text("Всего найдено Мафий за роль Шерифа"),
                subtitle: Text(stats.totalFoundMafia.toString()),
              ),
              ListTile(
                title: const Text("Всего найдено Шерифов за роль Дона"),
                subtitle: Text(stats.totalFoundSheriff.toString()),
              ),
              ListTile(
                title: const Text("Всего предупреждений"),
                subtitle: Text(stats.totalWarns.toString()),
              ),
              ListTile(
                title: const Text("Всего дисквалификаций (удалений)"),
                subtitle: Text(stats.totalKicks.toString()),
              ),
              ListTile(
                title: const Text("... из них с объявлением ППК"),
                subtitle: Text(stats.totalOtherTeamWins.toString()),
              ),
              ListTile(
                title: const Text("Всего убит в первую ночь"),
                subtitle: Text(stats.totalWasKilledFirstNight.toString()),
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
