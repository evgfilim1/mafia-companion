import "package:flutter/material.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:provider/provider.dart";

import "screens/choose_roles_screen.dart";
import "screens/debug_menu_screen.dart";
import "screens/game_log.dart";
import "screens/main.dart";
import "screens/players.dart";
import "screens/roles.dart";
import "screens/seat_randomizer.dart";
import "screens/settings/appearance.dart";
import "screens/settings/behavior.dart";
import "screens/settings/main.dart";
import "utils/color_scheme.dart";
import "utils/db/adapters.dart";
import "utils/db/methods.dart" as db;
import "utils/game_controller.dart";
import "utils/settings.dart";
import "utils/updates_checker.dart";
import "widgets/color_scheme_wrapper.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await db.init();
  final settings = await getSettings();
  final packageInfo = await PackageInfo.fromPlatform();
  final appColorScheme = await loadColorScheme(fallbackSeedColor: settings.seedColor);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsModel>.value(value: settings),
        Provider<PackageInfo>.value(value: packageInfo),
        ChangeNotifierProvider<GameController>(create: (context) => GameController()),
        ChangeNotifierProvider<UpdatesChecker>(create: (context) => UpdatesChecker()),
        Provider<BrightnessAwareColorScheme>.value(value: appColorScheme),
        ChangeNotifierProvider<PlayerList>(create: (_) => PlayerList()),
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
    return BrightnessAwareColorSchemeBuilder(
      builder: (colorScheme) => MaterialApp(
        title: "Mafia companion",
        theme: ThemeData(
          colorScheme: colorScheme.light,
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: colorScheme.dark,
          useMaterial3: true,
        ),
        themeMode: settings.themeMode,
        routes: {
          "/": (context) => const MainScreen(),
          "/roles": (context) => const RolesScreen(),
          "/settings": (context) => const SettingsScreen(),
          "/settings/appearance": (context) => const AppearanceSettingsScreen(),
          "/settings/behavior": (context) => const BehaviorSettingsScreen(),
          "/seats": (context) => const SeatRandomizerScreen(),
          "/log": (context) => const GameLogScreen(),
          "/chooseRoles": (context) => const ChooseRolesScreen(),
          "/debug": (context) => const DebugMenuScreen(),
          "/players": (context) => const PlayersScreen(),
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
