import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TimerType {
  strict,
  plus5,
  extended,
  disabled,
}

Future<SettingsModel> getSettings() async {
  final prefs = await SharedPreferences.getInstance();
  final timerTypeString = prefs.getString("timerType") ?? "plus5";
  final cancellable = prefs.getBool("cancellable") ?? false;
  final TimerType timerType;
  switch (timerTypeString) {
    case "strict":
      timerType = TimerType.strict;
      break;
    case "plus5":
      timerType = TimerType.plus5;
      break;
    case "extended":
      timerType = TimerType.extended;
      break;
    case "disabled":
      timerType = TimerType.disabled;
      break;
    default:
      throw Exception("Unknown timer type: $timerTypeString");
  }
  return SettingsModel(
    timerType: timerType,
    cancellable: cancellable,
  );
}

Future<void> saveSettings(SettingsModel settings) async {
  final prefs = await SharedPreferences.getInstance();
  final String timerTypeString;
  switch (settings.timerType) {
    case TimerType.strict:
      timerTypeString = "strict";
      break;
    case TimerType.plus5:
      timerTypeString = "plus5";
      break;
    case TimerType.extended:
      timerTypeString = "extended";
      break;
    case TimerType.disabled:
      timerTypeString = "disabled";
      break;
  }
  await prefs.setString("timerType", timerTypeString);
  await prefs.setBool("cancellable", settings.cancellable);
}

class SettingsModel with ChangeNotifier {
  TimerType _timerType;
  bool _cancellable;

  SettingsModel({
    required TimerType timerType,
    required bool cancellable,
  })  : _timerType = timerType,
        _cancellable = cancellable;

  TimerType get timerType => _timerType;

  bool get cancellable => _cancellable;

  void setTimerType(TimerType value, {bool save = true}) {
    _timerType = value;
    if (save) {
      saveSettings(this);
    }
    notifyListeners();
  }

  void setCancellable(bool value, {bool save = true}) {
    _cancellable = value;
    if (save) {
      saveSettings(this);
    }
    notifyListeners();
  }
}
