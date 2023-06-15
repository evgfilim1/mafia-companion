import "package:flutter_test/flutter_test.dart";
import "package:mafia_companion/game/player.dart";

void main() {
  group("generatePlayers", () {
    test("Player generator should yield valid result", () {
      final config = <PlayerRole, int>{
        PlayerRole.citizen: 4,
        PlayerRole.mafia: 1,
        PlayerRole.don: 1,
        PlayerRole.sheriff: 1,
      };
      final players = generatePlayers(roles: config);

      expect(players.length, config.values.reduce((a, b) => a + b));
      for (final entry in config.entries) {
        expect(
          players.where((p) => p.role == entry.key).length,
          entry.value,
          reason: "Role ${entry.key} count must be ${entry.value}",
        );
      }
    });

    test("Player generator should disallow invalid config", () {
      expect(() => generatePlayers(roles: {}), throwsArgumentError);
      expect(
        () => generatePlayers(
          roles: {
            PlayerRole.citizen: 6,
            PlayerRole.mafia: 1,
            PlayerRole.don: 1,
            PlayerRole.sheriff: 2,
          },
        ),
        throwsArgumentError,
        reason: "More than one sheriff is not allowed",
      );
      expect(
        () => generatePlayers(
          roles: {
            PlayerRole.citizen: 6,
            PlayerRole.mafia: 1,
            PlayerRole.don: 2,
            PlayerRole.sheriff: 1,
          },
        ),
        throwsArgumentError,
        reason: "More than one don is not allowed",
      );
      expect(
        () => generatePlayers(
          roles: {
            PlayerRole.citizen: 6,
            PlayerRole.mafia: 1,
            PlayerRole.don: 1,
            PlayerRole.sheriff: 0,
          },
        ),
        throwsArgumentError,
        reason: "Less than one sheriff is not allowed",
      );
      expect(
        () => generatePlayers(
          roles: {
            PlayerRole.citizen: 6,
            PlayerRole.mafia: 1,
            PlayerRole.don: 0,
            PlayerRole.sheriff: 1,
          },
        ),
        throwsArgumentError,
        reason: "Less than one don is not allowed",
      );
      expect(
        () => generatePlayers(
          roles: {
            PlayerRole.citizen: 1,
            PlayerRole.mafia: 1,
            PlayerRole.don: 1,
            PlayerRole.sheriff: 1,
          },
        ),
        throwsArgumentError,
        reason: "There must be more citizens than mafia",
      );
    });
  });
}
