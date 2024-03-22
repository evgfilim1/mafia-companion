import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../utils/db/adapters.dart";
import "../utils/db/models.dart" as db_models;
import "../utils/errors.dart";
import "../utils/game_log.dart";
import "../utils/json/from_json.dart";
import "../utils/json/to_json.dart";
import "../utils/load_save_file.dart";
import "../utils/log.dart";
import "../utils/ui.dart";
import "../widgets/confirmation_dialog.dart";
import "player_info.dart";

enum _LoadStrategy {
  replace,
  append,
  merge,
}

class _AddPlayerDialog extends StatefulWidget {
  const _AddPlayerDialog();

  @override
  State<_AddPlayerDialog> createState() => _AddPlayerDialogState();
}

class _AddPlayerDialogState extends State<_AddPlayerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();

  void _onSubmit() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, _nicknameController.text);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text("Добавить игрока"),
        content: Form(
          key: _formKey,
          child: TextFormField(
            controller: _nicknameController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: "Никнейм",
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              if ((value ?? "").isEmpty) {
                return "Введите никнейм";
              }
              return null;
            },
            onFieldSubmitted: (_) => _onSubmit(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Отмена"),
          ),
          TextButton(
            onPressed: _onSubmit,
            child: const Text("Добавить"),
          ),
        ],
      );
}

class _LoadStrategyDialog extends StatelessWidget {
  const _LoadStrategyDialog();

  @override
  Widget build(BuildContext context) => SimpleDialog(
        title: const Text("Выберите стратегию загрузки"),
        children: [
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text("Заменить"),
            subtitle: const Text("Удалить всех текущих игроков и загрузить новых из файла"),
            onTap: () => Navigator.pop(context, _LoadStrategy.replace),
          ),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text("Добавить"),
            subtitle: const Text("Добавить новых игроков из файла к текущему списку"),
            onTap: () => Navigator.pop(context, _LoadStrategy.append),
          ),
          ListTile(
            leading: const Icon(Icons.merge),
            title: const Text("Объединить"),
            subtitle: const Text("Объединить игроков из файла с текущим списком по никнейму"),
            onTap: () => Navigator.pop(context, _LoadStrategy.merge),
          ),
          ListTile(
            leading: const Icon(Icons.cancel),
            title: const Text("Отмена"),
            subtitle: const Text("Не загружать ничего"),
            onTap: () => Navigator.pop(context),
          ),
        ],
      );
}

class PlayersScreen extends StatelessWidget {
  static final _log = Logger("PlayersScreen");

  const PlayersScreen({super.key});

  Future<void> _onAddPlayerPressed(BuildContext context, PlayerList players) async {
    final nickname = await showDialog<String>(
      context: context,
      builder: (context) => const _AddPlayerDialog(),
    );
    if (nickname != null) {
      await players.add(db_models.Player(nickname: nickname));
    }
  }

  List<db_models.Player> _loadFromJson(dynamic data) {
    if (data is! Map<String, dynamic>) {
      throw ArgumentError("Invalid data type: ${data.runtimeType}");
    }
    final players = (data["players"] as List<dynamic>).parseJsonList(
      (json) => fromJson<db_models.Player>(json, gameLogVersion: GameLogVersion.latest),
    );
    return players;
  }

  void _onLoadFromJsonError(BuildContext context, Object error, StackTrace stackTrace) {
    showSnackBar(context, const SnackBar(content: Text("Ошибка загрузки игроков")));
    _log.error("Error loading player list: e=$error\n$stackTrace");
  }

  Future<void> _onLoadPressed(BuildContext context) async {
    final playersFromFile = await loadJsonFile(
      fromJson: _loadFromJson,
      onError: (e, st) => _onLoadFromJsonError(context, e, st),
    );
    if (playersFromFile == null) {
      return;
    }
    if (!context.mounted) {
      throw ContextNotMountedError();
    }
    final strategy = await showDialog<_LoadStrategy>(
      context: context,
      builder: (context) => const _LoadStrategyDialog(),
    );
    if (strategy == null) {
      return;
    }
    if (!context.mounted) {
      throw ContextNotMountedError();
    }
    final players = context.read<PlayerList>();
    switch (strategy) {
      case _LoadStrategy.replace:
        await players.clear();
        await players.addAll(playersFromFile);
      case _LoadStrategy.append:
        await players.addAll(playersFromFile);
      case _LoadStrategy.merge:
        final allPlayers = players.dataWithIDs;
        for (final player in playersFromFile) {
          final existing = allPlayers.where((e) => e.$2.nickname == player.nickname).firstOrNull;
          if (existing != null) {
            await players.edit(existing.$1, player);
          } else {
            await players.add(player);
          }
        }
    }
    if (!context.mounted) {
      throw ContextNotMountedError();
    }
    showSnackBar(context, const SnackBar(content: Text("Игроки загружены")));
  }

  Future<void> _onSavePressed(BuildContext context) async {
    final players = context.read<PlayerList>();
    final wasSaved = await saveJsonFile(
      {
        "players": players.data.map((e) => e.toJson()).toList(),
      },
      filename: "mafia_players",
    );
    if (!context.mounted || !wasSaved) {
      return;
    }
    showSnackBar(context, const SnackBar(content: Text("Игроки сохранены")));
  }

  Future<void> _onClearPressed(BuildContext context, PlayerList players) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const ConfirmationDialog(
        title: Text("Удалить всех игроков?"),
        content: Text("Вы уверены, что хотите удалить всех игроков?"),
      ),
    );
    if (confirmed ?? false) {
      await players.clear();
      if (!context.mounted) {
        return;
      }
      showSnackBar(context, const SnackBar(content: Text("Все игроки удалены")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final players = context.watch<PlayerList>();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Игроки"),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_open),
            tooltip: "Загрузить список игроков из файла",
            onPressed: () => _onLoadPressed(context),
          ),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: "Сохранить список игроков в файл",
            onPressed: () => _onSavePressed(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            tooltip: "Удалить всех игроков",
            onPressed: () => _onClearPressed(context, players),
          ),
        ],
      ),
      body: players.data.isNotEmpty
          ? ListView.builder(
              itemCount: players.data.length + 1,
              itemBuilder: (context, index) {
                if (index == players.data.length) {
                  return ListTile(
                    title: Text(
                      "Всего игроков: ${players.data.length}",
                      textAlign: TextAlign.center,
                    ),
                    dense: true,
                    enabled: false,
                    titleAlignment: ListTileTitleAlignment.center,
                  );
                }
                final (key, player) = players.dataWithIDs[index];
                return ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(player.nickname),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => PlayerInfoScreen(playerKey: key),
                    ),
                  ),
                );
              },
            )
          : const Center(child: Text("Список игроков пуст")),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onAddPlayerPressed(context, players),
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
