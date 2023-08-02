import "dart:collection";

import "../utils/extensions.dart";
import "player.dart";

class PlayersView with IterableMixin<Player> {
  final List<Player> _players;

  PlayersView(List<Player> players)
      : assert(
          players.asMap().entries.every((element) => element.value.number == element.key + 1),
          "Players must be sorted by numbers sequentially 1..10",
        ),
        _players = players;

  Player operator [](int index) => _players[index];

  @override
  Iterator<Player> get iterator => _players.iterator;

  @override
  int get length => _players.length;

  Player getByNumber(int number) => _players[number - 1];

  int get count => length;

  int get aliveCount => _players.where((player) => player.isAlive).length;

  int get aliveMafiaCount =>
      _players.where((player) => player.role.isMafia && player.isAlive).length;

  Player get don => _players.firstWhere((player) => player.role == PlayerRole.don);

  Player get sheriff => _players.firstWhere((player) => player.role == PlayerRole.sheriff);

  List<Player> get citizen =>
      _players.where((player) => player.role == PlayerRole.citizen).toUnmodifiableList();

  List<Player> get mafia =>
      _players.where((player) => player.role == PlayerRole.mafia).toUnmodifiableList();

  List<Player> get mafiaTeam =>
      _players.where((player) => player.role.isMafia).toUnmodifiableList();

  List<Player> get citizenTeam =>
      _players.where((player) => player.role.isCitizen).toUnmodifiableList();

  void kill(int number) => _players[number - 1] = _players[number - 1].copyWith(isAlive: false);

  void revive(int number) => _players[number - 1] = _players[number - 1].copyWith(isAlive: true);
}
