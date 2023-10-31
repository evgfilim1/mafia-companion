import "package:flutter/material.dart";
import "package:shared_preferences/shared_preferences.dart";

enum TimerType {
  shortened,
  strict,
  plus5,
  extended,
  disabled,
}

enum ColorSchemeType {
  system,
  app,
}

enum CheckUpdatesType {
  onLaunch,
  manually,
}

const defaultTimerType = TimerType.plus5;
const defaultThemeMode = ThemeMode.system;
const defaultColorSchemeType = ColorSchemeType.system;
const defaultCheckUpdatesType = CheckUpdatesType.onLaunch;
const defaultBestTurnEnabled = true;

Future<SettingsModel> getSettings() async {
  final prefs = await SharedPreferences.getInstance();
  final timerTypeString = prefs.getString("timerType") ?? defaultTimerType.name;
  final theme = prefs.getString("theme") ?? defaultThemeMode.name;
  final colorSchemeTypeString = prefs.getString("colorSchemeType") ?? defaultColorSchemeType.name;
  final checkUpdatesTypeString =
      prefs.getString("checkUpdatesType") ?? defaultCheckUpdatesType.name;

  final TimerType timerType;
  switch (timerTypeString) {
    case "shortened":
      timerType = TimerType.shortened;
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

  final CheckUpdatesType checkUpdatesType;
  switch (checkUpdatesTypeString) {
    case "onLaunch":
      checkUpdatesType = CheckUpdatesType.onLaunch;
    case "manually":
      checkUpdatesType = CheckUpdatesType.manually;
    default:
      assert(false, "Unknown check updates type: $checkUpdatesTypeString"); // fail for debug builds
      checkUpdatesType = defaultCheckUpdatesType; // use default for release builds
      break;
  }

  final bestTurnEnabled = prefs.getBool("bestTurnEnabled") ?? defaultBestTurnEnabled;

  return SettingsModel(
    timerType: timerType,
    themeMode: themeMode,
    colorSchemeType: colorSchemeType,
    checkUpdatesType: checkUpdatesType,
    bestTurnEnabled: bestTurnEnabled,
  );
}

Future<void> saveSettings(SettingsModel settings) async {
  final prefs = await SharedPreferences.getInstance();
  final timerTypeString = settings.timerType.name;
  final theme = settings.themeMode.name;
  final colorSchemeTypeString = settings.colorSchemeType.name;
  final checkUpdatesTypeString = settings.checkUpdatesType.name;

  await prefs.setString("timerType", timerTypeString);
  await prefs.setString("theme", theme);
  await prefs.setString("colorSchemeType", colorSchemeTypeString);
  await prefs.setString("checkUpdatesType", checkUpdatesTypeString);
  await prefs.setBool("bestTurnEnabled", settings.bestTurnEnabled);
}

class SettingsModel with ChangeNotifier {
  TimerType _timerType;
  ThemeMode _themeMode;
  ColorSchemeType _colorSchemeType;
  CheckUpdatesType _checkUpdatesType;
  bool _bestTurnEnabled;

  SettingsModel({
    required TimerType timerType,
    required ThemeMode themeMode,
    required ColorSchemeType colorSchemeType,
    required CheckUpdatesType checkUpdatesType,
    required bool bestTurnEnabled,
  })  : _timerType = timerType,
        _themeMode = themeMode,
        _colorSchemeType = colorSchemeType,
        _checkUpdatesType = checkUpdatesType,
        _bestTurnEnabled = bestTurnEnabled;

  TimerType get timerType => _timerType;

  ThemeMode get themeMode => _themeMode;

  ColorSchemeType get colorSchemeType => _colorSchemeType;

  CheckUpdatesType get checkUpdatesType => _checkUpdatesType;

  bool get bestTurnEnabled => _bestTurnEnabled;

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

  void setCheckUpdatesType(CheckUpdatesType value, {bool save = true}) {
    _checkUpdatesType = value;
    if (save) {
      saveSettings(this);
    }
    notifyListeners();
  }

  // It's obvious from the function name what the first parameter means.
  // ignore: avoid_positional_boolean_parameters
  void setBestTurnEnabled(bool value, {bool save = true}) {
    _bestTurnEnabled = value;
    if (save) {
      saveSettings(this);
    }
    notifyListeners();
  }
}
