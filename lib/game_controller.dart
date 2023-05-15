import 'package:flutter/material.dart';

import 'game/controller.dart';
import 'game/player.dart';
import 'game/states.dart';

class GameController with ChangeNotifier {
  Game _game = Game();

  GameStateWithPlayer get state => _game.state;

  int get day => _game.day;

  GameStateWithPlayer? get nextStateAssumption => _game.nextStateAssumption;

  GameStateWithPlayer? get previousState => _game.previousState;

  int get totalPlayersCount => _game.players.length;

  int get alivePlayersCount => _game.players.aliveCount;

  List<int> get voteCandidates => _game.voteCandidates;

  int get totalVotes => _game.totalVotes;

  int getPlayerVotes(int player) => _game.getPlayerVotes(player);

  PlayerRole? get winTeamAssumption => _game.winTeamAssumption;

  void restart() {
    _game = Game();
    notifyListeners();
  }

  PlayerRole getPlayerRole(int player) => _game.players.getRole(player);

  bool isPlayerAlive(int player) => _game.players.isAlive(player);

  void vote(int player, int count) {
    _game.vote(player, count);
    notifyListeners();
  }

  void selectPlayer(int player) {
    _game.selectPlayer(player);
    notifyListeners();
  }

  bool isPlayerSelected(int player) => _game.isPlayerSelected(player);

  void deselectPlayer(int player) {
    _game.deselectPlayer(player);
    notifyListeners();
  }

  void deselectAllPlayers() {
    _game.deselectAllPlayers();
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

  int getPlayerWarnCount(int player) => _game.players.getWarnCount(player);

  void unwarnPlayer(int player) {
    _game.unwarnPlayer(player);
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
