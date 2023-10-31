import "dart:math";

import "package:flutter/material.dart";

import "../game/controller.dart";
import "../game/log.dart";
import "../game/player.dart";
import "../game/states.dart";
import "extensions.dart";

int _getNewRandomSeed() => DateTime.now().millisecondsSinceEpoch;

class GameController with ChangeNotifier {
  int _seed;
  Random _random;
  Game _game;
  bool skipBestTurnStage;

  factory GameController({bool skipBestTurnStage = false}) {
    final seed = _getNewRandomSeed();
    final random = Random(seed);
    final game = Game.withPlayers(
      generatePlayers(random: random),
      skipBestTurnStage: skipBestTurnStage,
    );
    return GameController._(seed, random, game, skipBestTurnStage);
  }

  GameController._(this._seed, this._random, this._game, this.skipBestTurnStage);

  int get playerRandomSeed => _seed;

  Iterable<BaseGameLogItem> get gameLog => _game.log;

  BaseGameState get state => _game.state;

  BaseGameState? get nextStateAssumption => _game.nextStateAssumption;

  BaseGameState? get previousState => _game.previousState;

  int get totalPlayersCount => _game.players.count;

  int get alivePlayersCount => _game.players.aliveCount;

  List<int> get voteCandidates => _game.voteCandidates;

  int get totalVotes => _game.totalVotes;

  PlayerRole? get winTeamAssumption => _game.winTeamAssumption;

  void restart({int? seed}) {
    _seed = seed ?? _getNewRandomSeed();
    _random = Random(_seed);
    _game = Game.withPlayers(
      generatePlayers(random: _random),
      skipBestTurnStage: skipBestTurnStage,
    );
    notifyListeners();
  }

  Player getPlayerByNumber(int number) => _game.players.getByNumber(number);

  List<Player> get players => _game.players.toUnmodifiableList();

  void vote(int? player, int count) {
    _game.vote(player, count);
    notifyListeners();
  }

  void togglePlayerSelected(int player) {
    _game.togglePlayerSelected(player);
    notifyListeners();
  }

  void setNextState() {
    _game.setNextState();
    notifyListeners();
  }

  void setPreviousState() {
    _game.setPreviousState();
    notifyListeners();
  }

  void warnPlayer(int player) {
    _game.warnPlayer(player);
    notifyListeners();
  }

  int getPlayerWarnCount(int player) => _game.getPlayerWarnCount(player);

  void removePlayerWarn(int player) {
    _game.removePlayerWarn(player);
    notifyListeners();
  }

  void killPlayer(int player) {
    _game.players.kill(player);
    notifyListeners();
  }

  void revivePlayer(int player) {
    _game.players.revive(player);
    notifyListeners();
  }

  bool checkPlayer(int number) => _game.checkPlayer(number);
}
