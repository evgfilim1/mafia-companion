import "package:flutter/material.dart";
import "package:shared_preferences/shared_preferences.dart";

enum TimerType {
  strict,
  plus5,
  extended,
  disabled,
}

enum ColorSchemeType {
  system,
  app,
}

const defaultTimerType = TimerType.plus5;
const defaultThemeMode = ThemeMode.system;
const defaultColorSchemeType = ColorSchemeType.system;

Future<SettingsModel> getSettings() async {
  final prefs = await SharedPreferences.getInstance();
  final timerTypeString = prefs.getString("timerType") ?? defaultTimerType.name;
  final theme = prefs.getString("theme") ?? defaultThemeMode.name;
  final colorSchemeTypeString = prefs.getString("colorSchemeType") ?? defaultColorSchemeType.name;

  final TimerType timerType;
  switch (timerTypeString) {
    case "strict":
      timerType = TimerType.strict;
    case "plus5":
      timerType = TimerType.plus5;
    case "extended":
      timerType = TimerType.extended;
    case "disabled":
      timerType = TimerType.disabled;
    default:
      assert(false, "Unknown timer type: $timerTypeString"); // fail for debug builds
      timerType = defaultTimerType; // use default for release builds
      break;
  }

  final ThemeMode themeMode;
  switch (theme) {
    case "system":
      themeMode = ThemeMode.system;
    case "light":
      themeMode = ThemeMode.light;
    case "dark":
      themeMode = ThemeMode.dark;
    default:
      assert(false, "Unknown theme mode: $theme"); // fail for debug builds
      themeMode = defaultThemeMode; // use default for release builds
      break;
  }

  final ColorSchemeType colorSchemeType;
  switch (colorSchemeTypeString) {
    case "system":
      colorSchemeType = ColorSchemeType.system;
    case "app":
      colorSchemeType = ColorSchemeType.app;
    default:
      assert(false, "Unknown color scheme type: $colorSchemeTypeString"); // fail for debug builds
      colorSchemeType = defaultColorSchemeType; // use default for release builds
      break;
  }

  return SettingsModel(
    timerType: timerType,
    themeMode: themeMode,
    colorSchemeType: colorSchemeType,
  );
}

Future<void> saveSettings(SettingsModel settings) async {
  final prefs = await SharedPreferences.getInstance();
  final timerTypeString = settings.timerType.name;
  final theme = settings.themeMode.name;
  final colorSchemeTypeString = settings.colorSchemeType.name;

  await prefs.setString("timerType", timerTypeString);
  await prefs.setString("theme", theme);
  await prefs.setString("colorSchemeType", colorSchemeTypeString);
}

class SettingsModel with ChangeNotifier {
  TimerType _timerType;
  ThemeMode _themeMode;
  ColorSchemeType _colorSchemeType;

  SettingsModel({
    required TimerType timerType,
    required ThemeMode themeMode,
    required ColorSchemeType colorSchemeType,
  })  : _timerType = timerType,
        _themeMode = themeMode,
        _colorSchemeType = colorSchemeType;

  TimerType get timerType => _timerType;

  ThemeMode get themeMode => _themeMode;

  ColorSchemeType get colorSchemeType => _colorSchemeType;

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

  void setColorSchemeType(ColorSchemeType value, {bool save = true}) {
    _colorSchemeType = value;
    if (save) {
      saveSettings(this);
    }
    notifyListeners();
  }
}
