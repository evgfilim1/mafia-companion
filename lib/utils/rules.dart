import "package:flutter/material.dart";
import "package:shared_preferences/shared_preferences.dart";

enum _Keys {
  alwaysContinueVoting,
  ;

  String get value => "rules.$name";
}

final defaults = GameRulesModel(
  alwaysContinueVoting: false,
);

class GameRulesModel with ChangeNotifier {
  bool _alwaysContinueVoting;

  GameRulesModel({
    required bool alwaysContinueVoting,
  }) : _alwaysContinueVoting = alwaysContinueVoting;

  bool get alwaysContinueVoting => _alwaysContinueVoting;

  // ignore: avoid_positional_boolean_parameters
  void setAlwaysContinueVoting(bool value, {bool save = true}) {
    _alwaysContinueVoting = value;
    if (save) {
      this.save();
    }
    notifyListeners();
  }

  static Future<GameRulesModel> load() async {
    final prefs = await SharedPreferences.getInstance();
    final noFastVoting =
        prefs.getBool(_Keys.alwaysContinueVoting.value) ?? defaults.alwaysContinueVoting;

    return GameRulesModel(
      alwaysContinueVoting: noFastVoting,
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_Keys.alwaysContinueVoting.value, alwaysContinueVoting);
  }
}
