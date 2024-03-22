import "package:flutter/foundation.dart";
import "package:hive_flutter/hive_flutter.dart";

import "../extensions.dart";
import "models.dart";

class PlayerList with ChangeNotifier {
  var _data = <int, Player>{};
  final _box = Hive.box<Player>("players");

  List<Player> get data {
    _data = _box.toMap().cast();
    return _data.values.toUnmodifiableList();
  }

  List<(int, Player)> get dataWithIDs {
    _data = _box.toMap().cast();
    return _data.entries.map((e) => (e.key, e.value)).toUnmodifiableList();
  }

  Future<void> add(Player player) async {
    await _box.add(player);
    notifyListeners();
  }

  Future<void> addAll(Iterable<Player> players) async {
    await _box.addAll(players);
    notifyListeners();
  }

  Future<Player?> get(int key, {Player? defaultValue}) async =>
      _box.get(key, defaultValue: defaultValue);

  Future<void> edit(int key, Player newPlayer) async {
    await _box.put(key, newPlayer);
    notifyListeners();
  }

  Future<void> delete(int key) async {
    await _box.delete(key);
    notifyListeners();
  }

  Future<void> clear() async {
    await _box.clear();
    _data.clear();
    notifyListeners();
  }
}
