import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../utils/db/models.dart" as db_models;
import "../utils/db/repo.dart";
import "../utils/errors.dart";
import "../utils/load_save_file.dart";
import "../utils/log.dart";
import "../utils/ui.dart";
import "../utils/versioned/db_players.dart";
import "../widgets/confirmation_dialog.dart";
import "player_info.dart";

enum _LoadStrategy {
  replace,
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
  final _realNameController = TextEditingController();
  var _isNicknameAvailable = true;

  @override
  void dispose() {
    _nicknameController.dispose();
    _realNameController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit(BuildContext context) async {
    final nickname = _nicknameController.text.trim();
    final existingPlayer = await context.read<PlayerList>().getByNickname(nickname);
    setState(() {
      _isNicknameAvailable = existingPlayer == null;
    });
    if (_formKey.currentState?.validate() ?? false) {
      if (!context.mounted) {
        return;
      }
      Navigator.pop(
        context,
        db_models.Player(
          nickname: nickname,
          realName: _realNameController.text.trim(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text("Добавить игрока"),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
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
                  if (!_isNicknameAvailable) {
                    return "Никнейм занят";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _realNameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Имя",
                ),
                autofocus: false,
                textCapitalization: TextCapitalization.words,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Отмена"),
          ),
          TextButton(
            onPressed: () => _onSubmit(context),
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
            leading: const Icon(Icons.merge),
            title: const Text("Объединить по никнейму"),
            subtitle: const Text("Существующие игроки заменяются из файла, новые добавляются"),
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

class _PlayerTile extends StatelessWidget {
  final db_models.Player player;
  final VoidCallback onTap;

  const _PlayerTile({
    required this.player,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => ListTile(
        leading: const Icon(Icons.person),
        title: Text(player.nickname),
        subtitle: player.realName.isNotEmpty ? Text(player.realName) : null,
        onTap: onTap,
      );
}

class PlayersScreen extends StatelessWidget {
  static final _log = Logger("PlayersScreen");

  const PlayersScreen({super.key});

  Future<void> _onAddPlayerPressed(BuildContext context, PlayerList players) async {
    final newPlayer = await showDialog<db_models.Player>(
      context: context,
      builder: (context) => const _AddPlayerDialog(),
    );
    if (newPlayer != null) {
      await players.add(newPlayer);
    }
  }

  Future<void> _onSearchPressed(BuildContext context, PlayerList players) async {
    final result = await showSearch(
      context: context,
      delegate: _PlayerSearchDelegate(players.dataWithIDs),
    );
    if (result == null || !context.mounted) {
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => PlayerInfoScreen(playerKey: result),
      ),
    );
  }

  void _onLoadFromJsonError(BuildContext context, Object error, StackTrace stackTrace) {
    showSnackBar(context, const SnackBar(content: Text("Ошибка загрузки игроков")));
    _log.error("Error loading player list: e=$error\n$stackTrace");
  }

  Future<void> _onLoadPressed(BuildContext context) async {
    final playersFromFile = await loadJsonFile(
      fromJson: VersionedDBPlayers.fromJson,
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
        await players.addAll(playersFromFile.value);
      case _LoadStrategy.merge:
        final nicknameToID = <String, int>{};
        for (final (key, player) in players.dataWithIDs) {
          nicknameToID[player.nickname] = key;
        }
        final edits = <int, db_models.Player>{};
        final adds = <db_models.Player>[];
        for (final player in playersFromFile.value) {
          final key = nicknameToID[player.nickname];
          if (key != null) {
            edits[key] = player;
          } else {
            adds.add(player);
          }
        }
        await players.editAll(edits);
        await players.addAll(adds);
    }
    if (!context.mounted) {
      throw ContextNotMountedError();
    }
    showSnackBar(context, const SnackBar(content: Text("Игроки загружены")));
  }

  Future<void> _onSavePressed(BuildContext context) async {
    final players = context.read<PlayerList>();
    final wasSaved = await saveJsonFile(
      VersionedDBPlayers(players.data).toJson(),
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
            icon: const Icon(Icons.search),
            tooltip: "Искать",
            onPressed: () => _onSearchPressed(context, players),
          ),
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
                return _PlayerTile(
                  player: player,
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

class _PlayerSearchDelegate extends SearchDelegate<int> {
  final List<PlayerWithID> data;

  _PlayerSearchDelegate(this.data) : super(searchFieldLabel: "Никнейм");

  List<PlayerWithID> get filteredData => data.where((e) {
        final p = e.$2;
        final q = query.toLowerCase();
        return p.nickname.toLowerCase().contains(q) || p.realName.toLowerCase().contains(q);
      }).toList();

  @override
  List<Widget>? buildActions(BuildContext context) => [
        IconButton(onPressed: () => query = "", icon: const Icon(Icons.clear)),
      ];

  @override
  Widget? buildLeading(BuildContext context) => const BackButton();

  @override
  Widget buildResults(BuildContext context) => buildSuggestions(context);

  @override
  Widget buildSuggestions(BuildContext context) {
    final results = filteredData;
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final (key, player) = results[index];
        return _PlayerTile(
          player: player,
          onTap: () => close(context, key),
        );
      },
    );
  }
}
