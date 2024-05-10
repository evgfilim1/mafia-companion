import "package:flutter/material.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:provider/provider.dart";

import "screens/main.dart";
import "utils/color_scheme.dart";
import "utils/db/methods.dart" as db;
import "utils/db/repo.dart";
import "utils/game_controller.dart";
import "utils/misc.dart";
import "utils/rules.dart";
import "utils/settings.dart";
import "utils/timer.dart";
import "utils/updates_checker.dart";
import "widgets/color_scheme_wrapper.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await db.init();
  final settings = await getSettings();
  final packageInfo = await PackageInfo.fromPlatform();
  final appColorScheme = await loadColorScheme(fallbackSeedColor: settings.seedColor);
  final rules = await GameRulesModel.load();
  logFlags();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsModel>.value(value: settings),
        ChangeNotifierProvider<GameRulesModel>.value(value: rules),
        Provider<PackageInfo>.value(value: packageInfo),
        ChangeNotifierProvider<GameController>(create: (context) => GameController()),
        ChangeNotifierProvider<UpdatesChecker>(create: (context) => UpdatesChecker()),
        Provider<BrightnessAwareColorScheme>.value(value: appColorScheme),
        ChangeNotifierProvider<PlayerRepo>(create: (_) => PlayerRepo()),
        ChangeNotifierProvider<TimerService>(
          create: (context) => TimerService(controller: context.read(), settings: context.read()),
        ),
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
        home: const MainScreen(),
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
