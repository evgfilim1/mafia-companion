import "package:flutter/foundation.dart";
import "package:hive_flutter/hive_flutter.dart";

import "../extensions.dart";
import "models.dart";

typedef PlayerWithID = (int key, Player player);

class ConflictingPlayersError extends ArgumentError {
  final Iterable<String> conflictingNicknames;

  ConflictingPlayersError(this.conflictingNicknames)
      : super(
          "Some players already exist in the database: ${conflictingNicknames.join(", ")}",
        );
}

class PlayerList with ChangeNotifier {
  final _box = Hive.box<Player>("players");

  PlayerWithID _converter(MapEntry<dynamic, Player> e) => (e.key, e.value);

  void _checkConflictsByNickname(Iterable<Player> players, {Set<int> excludeIds = const {}}) {
    final nicknames = players.map((p) => p.nickname).toSet();
    final existingNicknames = _box
        .toMap()
        .entries
        .where((e) => !excludeIds.contains(e.key))
        .map((p) => p.value.nickname)
        .toSet();
    final conflictingNicknames = nicknames.intersection(existingNicknames);
    if (conflictingNicknames.isNotEmpty) {
      throw ConflictingPlayersError(conflictingNicknames);
    }
  }

  List<Player> get data => _box.values.toUnmodifiableList();

  List<PlayerWithID> get dataWithIDs => _box.toMap().entries.map(_converter).toUnmodifiableList();

  Future<void> add(Player player) => addAll([player]);

  Future<void> addAll(Iterable<Player> players) async {
    _checkConflictsByNickname(players);
    await _box.addAll(players);
    notifyListeners();
  }

  Future<Player?> get(int key, {Player? defaultValue}) async =>
      _box.get(key, defaultValue: defaultValue);

  Future<PlayerWithID?> getByNickname(String nickname) async =>
      _box.toMap().entries.where((e) => e.value.nickname == nickname).map(_converter).singleOrNull;

  Future<List<PlayerWithID?>> getManyByNicknames(List<String?> nicknames) async {
    final result = <int, PlayerWithID>{};
    for (final entry in _box.toMap().entries) {
      final index = nicknames.indexOf(entry.value.nickname);
      if (index != -1) {
        result[index] = _converter(entry);
      }
    }
    return [for (var i = 0; i < nicknames.length; i++) result[i]];
  }

  Future<void> edit(int key, Player newPlayer) => editAll({key: newPlayer});

  Future<void> editAll(Map<int, Player> editedPlayers) async {
    _checkConflictsByNickname(editedPlayers.values, excludeIds: editedPlayers.keys.toSet());
    await _box.putAll(editedPlayers);
    notifyListeners();
  }

  Future<void> delete(int key) async {
    await _box.delete(key);
    notifyListeners();
  }

  Future<void> clear() async {
    await _box.clear();
    notifyListeners();
  }
}
