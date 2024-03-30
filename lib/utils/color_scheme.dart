import "package:dynamic_color/dynamic_color.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:material_color_utilities/material_color_utilities.dart";

extension _DynamicSchemeToColorScheme on DynamicScheme {
  ColorScheme toColorScheme() => ColorScheme(
    primary: Color(MaterialDynamicColors.primary.getArgb(this)),
    onPrimary: Color(MaterialDynamicColors.onPrimary.getArgb(this)),
    primaryContainer: Color(MaterialDynamicColors.primaryContainer.getArgb(this)),
    onPrimaryContainer: Color(MaterialDynamicColors.onPrimaryContainer.getArgb(this)),
    primaryFixed: Color(MaterialDynamicColors.primaryFixed.getArgb(this)),
    primaryFixedDim: Color(MaterialDynamicColors.primaryFixedDim.getArgb(this)),
    onPrimaryFixed: Color(MaterialDynamicColors.onPrimaryFixed.getArgb(this)),
    onPrimaryFixedVariant: Color(MaterialDynamicColors.onPrimaryFixedVariant.getArgb(this)),
    secondary: Color(MaterialDynamicColors.secondary.getArgb(this)),
    onSecondary: Color(MaterialDynamicColors.onSecondary.getArgb(this)),
    secondaryContainer: Color(MaterialDynamicColors.secondaryContainer.getArgb(this)),
    onSecondaryContainer: Color(MaterialDynamicColors.onSecondaryContainer.getArgb(this)),
    secondaryFixed: Color(MaterialDynamicColors.secondaryFixed.getArgb(this)),
    secondaryFixedDim: Color(MaterialDynamicColors.secondaryFixedDim.getArgb(this)),
    onSecondaryFixed: Color(MaterialDynamicColors.onSecondaryFixed.getArgb(this)),
    onSecondaryFixedVariant: Color(MaterialDynamicColors.onSecondaryFixedVariant.getArgb(this)),
    tertiary: Color(MaterialDynamicColors.tertiary.getArgb(this)),
    onTertiary: Color(MaterialDynamicColors.onTertiary.getArgb(this)),
    tertiaryContainer: Color(MaterialDynamicColors.tertiaryContainer.getArgb(this)),
    onTertiaryContainer: Color(MaterialDynamicColors.onTertiaryContainer.getArgb(this)),
    tertiaryFixed: Color(MaterialDynamicColors.tertiaryFixed.getArgb(this)),
    tertiaryFixedDim: Color(MaterialDynamicColors.tertiaryFixedDim.getArgb(this)),
    onTertiaryFixed: Color(MaterialDynamicColors.onTertiaryFixed.getArgb(this)),
    onTertiaryFixedVariant: Color(MaterialDynamicColors.onTertiaryFixedVariant.getArgb(this)),
    error: Color(MaterialDynamicColors.error.getArgb(this)),
    onError: Color(MaterialDynamicColors.onError.getArgb(this)),
    errorContainer: Color(MaterialDynamicColors.errorContainer.getArgb(this)),
    onErrorContainer: Color(MaterialDynamicColors.onErrorContainer.getArgb(this)),
    outline: Color(MaterialDynamicColors.outline.getArgb(this)),
    outlineVariant: Color(MaterialDynamicColors.outlineVariant.getArgb(this)),
    surface: Color(MaterialDynamicColors.surface.getArgb(this)),
    surfaceDim: Color(MaterialDynamicColors.surfaceDim.getArgb(this)),
    surfaceBright: Color(MaterialDynamicColors.surfaceBright.getArgb(this)),
    surfaceContainerLowest: Color(MaterialDynamicColors.surfaceContainerLowest.getArgb(this)),
    surfaceContainerLow: Color(MaterialDynamicColors.surfaceContainerLow.getArgb(this)),
    surfaceContainer: Color(MaterialDynamicColors.surfaceContainer.getArgb(this)),
    surfaceContainerHigh: Color(MaterialDynamicColors.surfaceContainerHigh.getArgb(this)),
    surfaceContainerHighest: Color(MaterialDynamicColors.surfaceContainerHighest.getArgb(this)),
    onSurface: Color(MaterialDynamicColors.onSurface.getArgb(this)),
    onSurfaceVariant: Color(MaterialDynamicColors.onSurfaceVariant.getArgb(this)),
    inverseSurface: Color(MaterialDynamicColors.inverseSurface.getArgb(this)),
    onInverseSurface: Color(MaterialDynamicColors.inverseOnSurface.getArgb(this)),
    inversePrimary: Color(MaterialDynamicColors.inversePrimary.getArgb(this)),
    shadow: Color(MaterialDynamicColors.shadow.getArgb(this)),
    scrim: Color(MaterialDynamicColors.scrim.getArgb(this)),
    surfaceTint: Color(MaterialDynamicColors.primary.getArgb(this)),
    brightness: isDark ? Brightness.dark : Brightness.light,
  );
}

extension _CorePaletteToDynamicScheme on CorePalette {
  DynamicScheme toDynamicScheme({required Brightness brightness}) => DynamicScheme(
        sourceColorArgb: primary.get(
          switch (brightness) {
            Brightness.light => 40,
            Brightness.dark => 80,
          },
        ),
        variant: Variant.tonalSpot,
        isDark: brightness == Brightness.dark,
        primaryPalette: primary,
        secondaryPalette: secondary,
        tertiaryPalette: tertiary,
        neutralPalette: neutral,
        neutralVariantPalette: neutralVariant,
      );
}

Future<BrightnessAwareColorScheme> loadColorScheme({required Color fallbackSeedColor}) async {
  try {
    final corePalette = await DynamicColorPlugin.getCorePalette();

    if (corePalette != null) {
      return BrightnessAwareColorScheme.fromCorePaletteWorkaround(corePalette);
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

  BrightnessAwareColorScheme.fromCorePaletteWorkaround(CorePalette palette)
      : this(
          light: palette.toDynamicScheme(brightness: Brightness.light).toColorScheme(),
          dark: palette.toDynamicScheme(brightness: Brightness.dark).toColorScheme(),
          isDynamicColorSupported: true,
        );

  @Deprecated(
      "Use fromCorePaletteWorkaround instead for Flutter 3.21+."
      " See https://github.com/material-foundation/flutter-packages/issues/574"
  )
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
