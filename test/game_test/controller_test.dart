import "package:flutter_test/flutter_test.dart";
import "package:mafia_companion/game/controller.dart";
import "package:mafia_companion/game/player.dart";
import "package:mafia_companion/game/states.dart";

const players = <Player>[
  Player(role: PlayerRole.citizen, number: 1),
  Player(role: PlayerRole.mafia, number: 2),
  Player(role: PlayerRole.citizen, number: 3),
  Player(role: PlayerRole.citizen, number: 4),
  Player(role: PlayerRole.don, number: 5),
  Player(role: PlayerRole.citizen, number: 6),
  Player(role: PlayerRole.sheriff, number: 7),
  Player(role: PlayerRole.mafia, number: 8),
  Player(role: PlayerRole.citizen, number: 9),
  Player(role: PlayerRole.citizen, number: 10),
];

extension _GameSkipStates on Game {
  void forwardUntilStage(GameStage stage, {int maxIterations = 50}) {
    var iterations = 0;
    while (state.stage != stage && iterations++ <= maxIterations) {
      setNextState();
    }
    if (iterations > maxIterations) {
      throw Exception("Max iterations ($maxIterations) reached");
    }
  }
}

void main() {
  group("Game", () {
    test("Selecting a player at night kills him", () {
      final game = Game.withPlayers(players)
        ..forwardUntilStage(GameStage.nightKill)
        ..togglePlayerSelected(4);
      expect(
        game.state,
        isA<GameStateNightKill>().having(
          (state) => state.thisNightKilledPlayer!.number,
          "thisNightKilledPlayer!.number",
          4,
        ),
      );
      game.forwardUntilStage(GameStage.nightLastWords, maxIterations: 3);
      expect(
        game.state,
        isA<GameStateWithPlayer>()
            .having((state) => state.stage, "stage", GameStage.nightLastWords)
            .having((state) => state.player.number, "player.number", 4),
      );
      game.setNextState();
      expect(game.players.getByNumber(4).isAlive, false);
    });
  });

  group("Game scenarios", () {
    test("No vote game", () {
      final game = Game.withPlayers(players)
        ..forwardUntilStage(GameStage.nightKill)
        ..togglePlayerSelected(4)
        ..forwardUntilStage(GameStage.speaking, maxIterations: 4);

      expect(game.players.getByNumber(4).isAlive, false);
      expect(
        game.state,
        isA<GameStateSpeaking>().having((state) => state.player.number, "player.number", 2),
      );

      game
        ..forwardUntilStage(GameStage.nightKill, maxIterations: 9)
        ..togglePlayerSelected(9)
        ..forwardUntilStage(GameStage.speaking, maxIterations: 4);
      expect(game.players.getByNumber(9).isAlive, false);
      expect(
        game.state,
        isA<GameStateSpeaking>().having((state) => state.player.number, "player.number", 3),
      );

      game
        ..forwardUntilStage(GameStage.nightKill, maxIterations: 8)
        ..togglePlayerSelected(7)
        ..forwardUntilStage(GameStage.speaking, maxIterations: 4);
      expect(game.players.getByNumber(7).isAlive, false);
      expect(
        game.state,
        isA<GameStateSpeaking>().having((state) => state.player.number, "player.number", 5),
      );

      game
        ..forwardUntilStage(GameStage.nightKill, maxIterations: 7)
        ..togglePlayerSelected(1)
        ..forwardUntilStage(GameStage.finish, maxIterations: 4);
      expect(game.players.getByNumber(1).isAlive, false);
      expect(
        game.state,
        isA<GameStateFinish>().having((state) => state.winner, "winner", PlayerRole.mafia),
      );
    });
  });
}
