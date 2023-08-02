import "package:flutter/material.dart";

import "../game/controller.dart";
import "../game/log.dart";
import "../game/player.dart";
import "../game/states.dart";
import "extensions.dart";

class GameController with ChangeNotifier {
  Game _game = Game();

  Iterable<BaseGameLogItem> get gameLog => _game.log;

  BaseGameState get state => _game.state;

  BaseGameState? get nextStateAssumption => _game.nextStateAssumption;

  BaseGameState? get previousState => _game.previousState;

  int get totalPlayersCount => _game.players.count;

  int get alivePlayersCount => _game.players.aliveCount;

  List<int> get voteCandidates => _game.voteCandidates;

  int get totalVotes => _game.totalVotes;

  PlayerRole? get winTeamAssumption => _game.winTeamAssumption;

  void restart() {
    _game = Game();
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
