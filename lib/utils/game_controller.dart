import "package:flutter/material.dart";

import "../game/config.dart";
import "../game/controller.dart";
import "../game/log.dart";
import "../game/player.dart";
import "../game/players_view.dart";
import "../game/states.dart";
import "log.dart";
import "rules.dart";

extension _EnsureInitialized on Game? {
  Game get ensureInitialized => this ?? (throw StateError("Game is not initialized"));
}

extension _GameRulesModelToGameConfig on GameRulesModel {
  GameConfig toGameConfig() => GameConfig(
        alwaysContinueVoting: alwaysContinueVoting,
      );
}

int getNewSeed() => DateTime.now().millisecondsSinceEpoch;

class GameController with ChangeNotifier {
  static final _log = Logger("GameController");

  Game? _game;

  List<String?>? _nicknames;

  List<String?>? get nicknames => _nicknames;

  set nicknames(List<String?>? value) {
    assert(value == null || value.length == 10, "Nicknames list must have 10 elements");
    _nicknames = value;
  }

  List<PlayerRole>? _roles;

  List<PlayerRole>? get roles => _roles;

  set roles(List<PlayerRole>? value) {
    assert(value == null || value.length == 10, "Roles list must have 10 elements");
    _roles = value;
  }

  GameController();

  bool get isGameInitialized => _game != null;

  bool get isGameActive => _game?.isActive ?? false;

  Iterable<BaseGameLogItem> get gameLog => _game?.log ?? const [];

  BaseGameState get state => _game.ensureInitialized.state;

  BaseGameState? get nextStateAssumption => _game?.nextStateAssumption;

  BaseGameState? get previousState => _game?.previousState;

  int get totalVotes => _game?.totalVotes ?? 0;

  RoleTeam? get winTeamAssumption => _game?.winTeamAssumption;

  PlayersView get players => _game.ensureInitialized.players;

  void startNewGame({
    required GameRulesModel rules,
  }) {
    _game = Game.withPlayers(
      generatePlayers(nicknames: _nicknames, roles: _roles),
      config: rules.toGameConfig(),
    );
    notifyListeners();
  }

  void stopGame() {
    _game = null;
    _roles = null;
    _nicknames = null;
    _log.debug("Game stopped");
    notifyListeners();
  }

  void vote(int count) {
    _game.ensureInitialized.vote(count);
    notifyListeners();
  }

  void togglePlayerSelected(int player) {
    _game.ensureInitialized.togglePlayerSelected(player);
    notifyListeners();
  }

  void setNextState() {
    _game.ensureInitialized.setNextState();
    notifyListeners();
  }

  void setPreviousState() {
    _game.ensureInitialized.setPreviousState();
    notifyListeners();
  }

  void warnPlayer(int player) {
    _game.ensureInitialized.warnPlayer(player);
    notifyListeners();
  }

  void warnMinusPlayer(int player) {
    _game.ensureInitialized.warnMinusPlayer(player);
    notifyListeners();
  }

  void kickPlayer(int player) {
    _game.ensureInitialized.kickPlayer(player);
    notifyListeners();
  }

  void kickPlayerTeam(int player) {
    _game.ensureInitialized.kickPlayerTeam(player);
    notifyListeners();
  }

  int getPlayerWarnCount(int player) => _game.ensureInitialized.getPlayerWarnCount(player);

  bool checkPlayer(int number) => _game.ensureInitialized.checkPlayer(number);
}
