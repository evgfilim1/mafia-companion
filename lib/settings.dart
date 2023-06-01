import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TimerType {
  strict,
  plus5,
  extended,
  disabled,
}

const defaultTimerType = TimerType.plus5;
const defaultThemeMode = ThemeMode.system;

Future<SettingsModel> getSettings() async {
  final prefs = await SharedPreferences.getInstance();
  final timerTypeString = prefs.getString("timerType") ?? defaultTimerType.name;
  final theme = prefs.getString("theme") ?? defaultThemeMode.name;

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
      assert(false, "Unknown timer type: $timerTypeString"); // fail for debug builds
      timerType = defaultTimerType; // use default for release builds
      break;
  }

  final ThemeMode themeMode;
  switch (theme) {
    case "system":
      themeMode = ThemeMode.system;
      break;
    case "light":
      themeMode = ThemeMode.light;
      break;
    case "dark":
      themeMode = ThemeMode.dark;
      break;
    default:
      assert(false, "Unknown theme mode: $theme"); // fail for debug builds
      themeMode = defaultThemeMode; // use default for release builds
      break;
  }

  return SettingsModel(
    timerType: timerType,
    themeMode: themeMode,
  );
}

Future<void> saveSettings(SettingsModel settings) async {
  final prefs = await SharedPreferences.getInstance();
  final timerTypeString = settings.timerType.name;
  final theme = settings.themeMode.name;

  await prefs.setString("timerType", timerTypeString);
  await prefs.setString("theme", theme);
}

class SettingsModel with ChangeNotifier {
  TimerType _timerType;
  ThemeMode _themeMode;

  SettingsModel({
    required TimerType timerType,
    required ThemeMode themeMode,
  })  : _timerType = timerType,
        _themeMode = themeMode;

  TimerType get timerType => _timerType;

  ThemeMode get themeMode => _themeMode;

  void setTimerType(TimerType value, {bool save = true}) {
    _timerType = value;
    if (save) {
      saveSettings(this);
    }
    notifyListeners();
  }

  void setThemeMode(ThemeMode value, {bool save = true}) {
    _themeMode = value;
    if (save) {
      saveSettings(this);
    }
    notifyListeners();
  }
}
