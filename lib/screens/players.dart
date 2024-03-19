import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../utils/db/adapters.dart";
import "../utils/db/models.dart" as db_models;
import "player_info.dart";

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

class PlayersScreen extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    final players = context.watch<PlayerList>();
    return Scaffold(
      appBar: AppBar(title: const Text("Игроки")),
      body: players.data.isNotEmpty
          ? ListView.builder(
              itemCount: players.data.length,
              itemBuilder: (context, index) {
                final player = players.data[index];
                return ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(player.nickname),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => PlayerInfoScreen(playerKey: players.getKey(player)),
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
