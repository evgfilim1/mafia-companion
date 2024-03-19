import "package:hive_flutter/hive_flutter.dart";

import "models.dart";

Future<void> init() async {
  await Hive.initFlutter();
  Hive.registerAdapter<Player>(PlayerAdapter());
  await Hive.openBox<Player>("players");
}
