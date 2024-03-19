import "package:flutter/foundation.dart";
import "package:hive_flutter/hive_flutter.dart";

import "../extensions.dart";
import "models.dart";

class PlayerList with ChangeNotifier {
  var _data = <dynamic, Player>{};
  final _box = Hive.box<Player>("players");

  List<Player> get data {
    _data = _box.toMap();
    return _data.values.toUnmodifiableList();
  }

  Future<void> add(Player player) async {
    await _box.add(player);
    notifyListeners();
  }

  Future<Player?> get(dynamic key, {Player? defaultValue}) async =>
      _box.get(key, defaultValue: defaultValue);

  Future<void> edit(Player oldPlayer, Player newPlayer) async {
    final key = getKey(oldPlayer);
    if (key == null) {
      return;
    }
    await _box.put(key, newPlayer);
    notifyListeners();
  }

  Future<void> delete(Player player) async {
    final key = getKey(player);
    if (key == null) {
      return;
    }
    await _box.delete(key);
    notifyListeners();
  }

  dynamic getKey(Player player) =>
      _data.entries.where((entry) => entry.value == player).singleOrNull?.key;
}
