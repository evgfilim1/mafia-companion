import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../utils/color_scheme.dart";
import "../utils/settings.dart";

class BrightnessAwareColorSchemeBuilder extends StatelessWidget {
  final Widget Function(BrightnessAwareColorScheme colorScheme) builder;

  const BrightnessAwareColorSchemeBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsModel>();
    final systemColorScheme = context.read<BrightnessAwareColorScheme>();
    final customColorScheme = BrightnessAwareColorScheme.fromAccentColor(
      settings.seedColor,
      isDynamicColorSupported: systemColorScheme.isDynamicColorSupported,
    );

    if (!systemColorScheme.isDynamicColorSupported) {
      return builder(customColorScheme);
    }

    switch (settings.colorSchemeType) {
      case ColorSchemeType.system:
        return builder(systemColorScheme);
      case ColorSchemeType.custom:
        return builder(customColorScheme);
    }
  }
}
