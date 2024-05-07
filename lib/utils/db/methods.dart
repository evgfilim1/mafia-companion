import "package:hive_flutter/hive_flutter.dart";

import "adapters.dart";
import "models.dart";

Future<void> init() async {
  await Hive.initFlutter();
  Hive
    ..registerAdapter(PlayerRoleAdapter())
    ..registerAdapter(PlayerAdapter())
    ..registerAdapter(PlayerStatsAdapter());
  await Hive.openBox<Player>("players");
  await Hive.openBox<Player>("players2");
  await Hive.openBox<PlayerStats>("playerStats");
}
