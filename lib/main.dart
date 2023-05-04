import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'game/controller.dart';
import 'screens/main.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
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
      themeMode: ThemeMode.system,
      home: Provider<GameController>(
        create: (_) => GameController(),
        child: const MainScreen(),
      ),
    );
  }
}
