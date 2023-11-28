import "dart:math";

import "../game/player.dart";
import "extensions.dart";

int? findSeed({required int initialSeed, required List<Set<PlayerRole>> requiredRoles}) {
  var newSeed = initialSeed;
  var isOk = true;
  for (; newSeed < initialSeed + 500000; newSeed++) {
    final newRoles =
        generatePlayers(random: Random(newSeed)).map((p) => p.role).toUnmodifiableList();
    isOk = true;
    for (var i = 0; i < 10; i++) {
      if (!requiredRoles[i].contains(newRoles[i])) {
        isOk = false;
        break;
      }
    }
    if (isOk) {
      break;
    }
  }
  return isOk ? newSeed : null;
}

int? findSeedIsolateWrapper((int initialSeed, List<Set<PlayerRole>> requiredRoles) data) =>
    findSeed(initialSeed: data.$1, requiredRoles: data.$2);
