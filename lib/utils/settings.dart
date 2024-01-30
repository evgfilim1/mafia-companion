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

enum VibrationDuration {
  disabled(0),
  xShort(10),
  short(20),
  medium(30),
  long(40),
  xLong(50),
  ;

  final int milliseconds;

  const VibrationDuration(this.milliseconds);
}

final defaults = SettingsModel(
  timerType: TimerType.strict,
  themeMode: ThemeMode.system,
  colorSchemeType: ColorSchemeType.system,
  checkUpdatesType: CheckUpdatesType.onLaunch,
  seedColor: Colors.purple,
  vibrationDuration: VibrationDuration.medium,
);

enum _SettingsKeys {
  timerType,
  theme,
  colorSchemeType,
  checkUpdatesType,
  seedColor,
  vibrationDuration,
}

Future<SettingsModel> getSettings() async {
  final prefs = await SharedPreferences.getInstance();
  final timerTypeString = prefs.getString(_SettingsKeys.timerType.name) ?? defaults.timerType.name;
  final theme = prefs.getString(_SettingsKeys.theme.name) ?? defaults.themeMode.name;
  final colorSchemeTypeString =
      prefs.getString(_SettingsKeys.colorSchemeType.name) ?? defaults.colorSchemeType.name;
  final checkUpdatesTypeString =
      prefs.getString(_SettingsKeys.checkUpdatesType.name) ?? defaults.checkUpdatesType.name;
  final seedColorInt = prefs.getInt(_SettingsKeys.seedColor.name) ?? defaults.seedColor.value;
  final vibrationDurationString =
      prefs.getString(_SettingsKeys.vibrationDuration.name) ?? defaults.vibrationDuration.name;

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
      timerType = defaults.timerType; // use default for release builds
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
      themeMode = defaults.themeMode; // use default for release builds
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
      colorSchemeType = defaults.colorSchemeType; // use default for release builds
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
      checkUpdatesType = defaults.checkUpdatesType; // use default for release builds
      break;
  }

  final seedColor = Color(seedColorInt);

  final VibrationDuration vibrationDuration;
  switch (vibrationDurationString) {
    case "disabled":
      vibrationDuration = VibrationDuration.disabled;
    case "xShort":
      vibrationDuration = VibrationDuration.xShort;
    case "short":
      vibrationDuration = VibrationDuration.short;
    case "medium":
      vibrationDuration = VibrationDuration.medium;
    case "long":
      vibrationDuration = VibrationDuration.long;
    case "xLong":
      vibrationDuration = VibrationDuration.xLong;
    default:
      assert(false, "Unknown vibration duration: $vibrationDurationString");
      vibrationDuration = defaults.vibrationDuration;
      break;
  }

  return SettingsModel(
    timerType: timerType,
    themeMode: themeMode,
    colorSchemeType: colorSchemeType,
    checkUpdatesType: checkUpdatesType,
    seedColor: seedColor,
    vibrationDuration: vibrationDuration,
  );
}

Future<void> saveSettings(SettingsModel settings) async {
  final prefs = await SharedPreferences.getInstance();
  final timerTypeString = settings.timerType.name;
  final theme = settings.themeMode.name;
  final colorSchemeTypeString = settings.colorSchemeType.name;
  final checkUpdatesTypeString = settings.checkUpdatesType.name;
  final seedColorInt = settings.seedColor.value;
  final vibrationDurationString = settings.vibrationDuration.name;

  await prefs.setString(_SettingsKeys.timerType.name, timerTypeString);
  await prefs.setString(_SettingsKeys.theme.name, theme);
  await prefs.setString(_SettingsKeys.colorSchemeType.name, colorSchemeTypeString);
  await prefs.setString(_SettingsKeys.checkUpdatesType.name, checkUpdatesTypeString);
  await prefs.setInt(_SettingsKeys.seedColor.name, seedColorInt);
  await prefs.setString(_SettingsKeys.vibrationDuration.name, vibrationDurationString);
}

class SettingsModel with ChangeNotifier {
  TimerType _timerType;
  ThemeMode _themeMode;
  ColorSchemeType _colorSchemeType;
  CheckUpdatesType _checkUpdatesType;
  Color _seedColor;
  VibrationDuration _vibrationDuration;

  SettingsModel({
    required TimerType timerType,
    required ThemeMode themeMode,
    required ColorSchemeType colorSchemeType,
    required CheckUpdatesType checkUpdatesType,
    required Color seedColor,
    required VibrationDuration vibrationDuration,
  })  : _timerType = timerType,
        _themeMode = themeMode,
        _colorSchemeType = colorSchemeType,
        _checkUpdatesType = checkUpdatesType,
        _seedColor = seedColor,
        _vibrationDuration = vibrationDuration;

  TimerType get timerType => _timerType;

  ThemeMode get themeMode => _themeMode;

  ColorSchemeType get colorSchemeType => _colorSchemeType;

  CheckUpdatesType get checkUpdatesType => _checkUpdatesType;

  Color get seedColor => _seedColor;

  VibrationDuration get vibrationDuration => _vibrationDuration;

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

  void setSeedColor(Color value, {bool save = true}) {
    _seedColor = value;
    if (save) {
      saveSettings(this);
    }
    notifyListeners();
  }

  void setVibrationDuration(VibrationDuration value, {bool save = true}) {
    _vibrationDuration = value;
    if (save) {
      saveSettings(this);
    }
    notifyListeners();
  }
}
