import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../utils/db/models.dart" as db_models;
import "../utils/db/repo.dart";
import "../utils/extensions.dart";
import "../utils/log.dart";
import "../utils/misc.dart";
import "../widgets/confirmation_dialog.dart";
import "../widgets/list_tiles/text_field.dart";
import "player_stats.dart";

class PlayerInfoScreen extends StatelessWidget {
  static final _log = Logger("PlayerInfoScreen");

  final int playerKey;

  const PlayerInfoScreen({
    super.key,
    required this.playerKey,
  });

  Future<void> _onDeletePressed(
    BuildContext context,
    PlayerList players,
    db_models.Player player,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: const Text("Удалить игрока?"),
        content: Text("Вы уверены, что хотите удалить игрока ${player.nickname}?"),
      ),
    );
    if (confirmed ?? false) {
      await players.delete(playerKey);
      if (!context.mounted) {
        return;
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final players = context.watch<PlayerList>();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Информация об игроке"),
      ),
      body: FutureBuilder(
        future: players.get(playerKey),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            _log.error("Player $playerKey not found");
            return const Center(child: Text("Игрок не найден"));
          }
          final player = snapshot.requireData!;
          return ListView(
            children: [
              if (kIsDev || kEnableShowIds)
                ListTile(
                  enabled: false,
                  leading: const Icon(Icons.onetwothree),
                  title: const Text("ID"),
                  subtitle: Text(playerKey.toString()),
                ),
              TextFieldListTile(
                leading: const Icon(Icons.person),
                title: const Text("Никнейм"),
                subtitle: Text(player.nickname),
                initialText: player.nickname,
                textCapitalization: TextCapitalization.words,
                validator: (value) async {
                  if (value == null || value.isEmpty) {
                    return "Введите никнейм";
                  }
                  final existingPlayer = await context.read<PlayerList>().getByNickname(value);
                  if (existingPlayer != null && existingPlayer.$1 != playerKey) {
                    return "Никнейм занят";
                  }
                  return null;
                },
                onSubmit: (value) => players.edit(playerKey, player.copyWith(nickname: value)),
              ),
              TextFieldListTile(
                leading: const Icon(Icons.badge),
                title: const Text("Имя"),
                subtitle: Text(player.realName.isNotEmpty ? player.realName : "(не указано)"),
                initialText: player.realName,
                textCapitalization: TextCapitalization.words,
                onSubmit: (value) => players.edit(playerKey, player.copyWith(realName: value)),
              ),
              ListTile(
                leading: const Icon(Icons.bar_chart),
                title: const Text("Статистика"),
                subtitle: Text("Сыграно игр: ${player.stats.gamesByRole.values.sum}"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => PlayerStatsScreen(playerKey: playerKey),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text("Удалить игрока", style: TextStyle(color: Colors.red)),
                onTap: () => _onDeletePressed(context, players, player),
              ),
            ],
          );
        },
      ),
    );
  }
}
