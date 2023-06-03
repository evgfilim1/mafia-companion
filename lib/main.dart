import "package:flutter/material.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:provider/provider.dart";

import "game_controller.dart";
import "screens/main.dart";
import "settings.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await getSettings();
  final packageInfo = await PackageInfo.fromPlatform();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsModel>(create: (_) => settings),
        Provider<PackageInfo>(create: (_) => packageInfo),
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
    return MaterialApp(
      title: "Mafia companion",
      theme: ThemeData(
        colorSchemeSeed: seedColor,
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: seedColor,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      themeMode: settings.themeMode,
      home: ChangeNotifierProvider<GameController>(
        create: (_) => GameController(),
        child: const MainScreen(),
      ),
    );
  }
}
