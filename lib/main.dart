import "package:dynamic_color/dynamic_color.dart";
import "package:flutter/material.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:provider/provider.dart";

import "game_controller.dart";
import "screens/main.dart";
import "screens/roles.dart";
import "screens/seat_randomizer.dart";
import "screens/settings.dart";
import "settings.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await getSettings();
  final packageInfo = await PackageInfo.fromPlatform();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsModel>.value(value: settings),
        Provider<PackageInfo>.value(value: packageInfo),
        ChangeNotifierProvider<GameController>(create: (context) => GameController()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsModel>();
    const seedColor = Colors.purple;
    return DynamicColorBuilder(
      builder: (light, dark) => MaterialApp(
        title: "Mafia companion",
        theme: ThemeData(
          colorScheme: (settings.colorSchemeType == ColorSchemeType.system ? light : null) ??
              ColorScheme.fromSeed(
                seedColor: seedColor,
                brightness: Brightness.light,
              ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: (settings.colorSchemeType == ColorSchemeType.system ? dark : null) ??
              ColorScheme.fromSeed(
                seedColor: seedColor,
                brightness: Brightness.dark,
              ),
          useMaterial3: true,
        ),
        themeMode: settings.themeMode,
        routes: {
          "/": (context) => const MainScreen(),
          "/roles": (context) => const RolesScreen(),
          "/settings": (context) => const SettingsScreen(),
          "/seats": (context) => const SeatRandomizerScreen(),
        },
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale("ru"),
        ],
      ),
    );
  }
}
