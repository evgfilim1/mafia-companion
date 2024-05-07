import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../utils/db/repo.dart";
import "../utils/extensions.dart";
import "../utils/log.dart";
import "../utils/misc.dart";
import "../utils/navigation.dart";
import "../widgets/confirmation_dialog.dart";
import "../widgets/list_tiles/text_field.dart";

class PlayerInfoScreen extends StatelessWidget {
  static final _log = Logger("PlayerInfoScreen");

  final String playerID;

  const PlayerInfoScreen({
    super.key,
    required this.playerID,
  });

  Future<void> _onDeletePressed(
    BuildContext context,
    PlayerRepo players,
    String nickname,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: const Text("Удалить игрока?"),
        content: Text("Вы уверены, что хотите удалить игрока $nickname?"),
      ),
    );
    if (confirmed ?? false) {
      await players.delete(playerID);
      if (!context.mounted) {
        return;
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final players = context.watch<PlayerRepo>();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Информация об игроке"),
      ),
      body: FutureBuilder(
        future: players.get(playerID),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.requireData == null) {
            _log.error("Player $playerID not found");
            return const Center(child: Text("Игрок не найден"));
          }
          final pws = snapshot.requireData!;
          return ListView(
            children: [
              if (kIsDev || kEnableShowIds)
                ListTile(
                  enabled: false,
                  leading: const Icon(Icons.onetwothree),
                  title: const Text("ID"),
                  subtitle: Text(playerID),
                ),
              TextFieldListTile(
                leading: const Icon(Icons.person),
                title: const Text("Никнейм"),
                subtitle: Text(pws.player.nickname),
                initialText: pws.player.nickname,
                textCapitalization: TextCapitalization.words,
                validator: (value) async {
                  if (value == null || value.isEmpty) {
                    return "Введите никнейм";
                  }
                  final playerExists = await context
                      .read<PlayerRepo>()
                      .isNicknameOccupied(value, exceptID: playerID);
                  if (playerExists) {
                    return "Никнейм занят";
                  }
                  return null;
                },
                onSubmit: (value) => players.edit(playerID, pws.player.copyWith(nickname: value)),
              ),
              TextFieldListTile(
                leading: const Icon(Icons.badge),
                title: const Text("Имя"),
                subtitle:
                    Text(pws.player.realName.isNotEmpty ? pws.player.realName : "(не указано)"),
                initialText: pws.player.realName,
                textCapitalization: TextCapitalization.words,
                onSubmit: (value) => players.edit(playerID, pws.player.copyWith(realName: value)),
              ),
              ListTile(
                leading: const Icon(Icons.bar_chart),
                title: const Text("Статистика"),
                subtitle: Text("Сыграно игр: ${pws.stats.gamesByRole.values.sum}"),
                onTap: () => openPlayerStatsPage(context, playerID),
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text("Удалить игрока", style: TextStyle(color: Colors.red)),
                onTap: () => _onDeletePressed(context, players, pws.player.nickname),
              ),
            ],
          );
        },
      ),
    );
  }
}
