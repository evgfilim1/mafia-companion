import 'package:flutter/material.dart';

import 'game/controller.dart';
import 'game/player.dart';
import 'game/states.dart';

class GameController with ChangeNotifier {
  Game _game = Game();

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

  Player getPlayer(int number) => _game.players.getByNumber(number);

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
    _game.players.warn(player);
    notifyListeners();
  }

  int getPlayerWarnCount(int player) => _game.players.getWarnCount(player);

  void unwarnPlayer(int player) {
    _game.players.unwarn(player);
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
}
