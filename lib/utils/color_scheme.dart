import "package:dynamic_color/dynamic_color.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:material_color_utilities/material_color_utilities.dart";

Future<BrightnessAwareColorScheme> loadColorScheme({required Color fallbackSeedColor}) async {
  try {
    final corePalette = await DynamicColorPlugin.getCorePalette();

    if (corePalette != null) {
      return BrightnessAwareColorScheme.fromCorePalette(corePalette);
    }
  } on PlatformException {
    // ignore
  }

  try {
    final accentColor = await DynamicColorPlugin.getAccentColor();

    if (accentColor != null) {
      return BrightnessAwareColorScheme.fromAccentColor(accentColor, isDynamicColorSupported: true);
    }
  } on PlatformException {
    // ignore
  }

  return BrightnessAwareColorScheme.fromAccentColor(
    fallbackSeedColor,
    isDynamicColorSupported: false,
  );
}

class BrightnessAwareColorScheme {
  final ColorScheme light;
  final ColorScheme dark;
  final bool isDynamicColorSupported;

  BrightnessAwareColorScheme({
    required this.light,
    required this.dark,
    required this.isDynamicColorSupported,
  });

  BrightnessAwareColorScheme.fromCorePalette(CorePalette palette)
      : this(
          light: palette.toColorScheme(brightness: Brightness.light),
          dark: palette.toColorScheme(brightness: Brightness.dark),
          isDynamicColorSupported: true,
        );

  BrightnessAwareColorScheme.fromAccentColor(
    Color accentColor, {
    required bool isDynamicColorSupported,
  }) : this(
          light: ColorScheme.fromSeed(seedColor: accentColor, brightness: Brightness.light),
          dark: ColorScheme.fromSeed(seedColor: accentColor, brightness: Brightness.dark),
          isDynamicColorSupported: isDynamicColorSupported,
        );
}
