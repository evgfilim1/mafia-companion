import "dart:collection";

import "../utils/extensions.dart";
import "player.dart";

class PlayersView with IterableMixin<PlayerWithState> {
  final List<PlayerWithState> _players;

  const PlayersView({
    required List<PlayerWithState> players,
  }) : _players = players;

  PlayerWithState operator [](int index) => _players[index];

  @override
  Iterator<PlayerWithState> get iterator => _players.iterator;

  @override
  int get length => _players.length;

  PlayerWithState getByNumber(int number) => this[number - 1];

  int get count => length;

  int get aliveCount => where((player) => player.state.isAlive).length;

  int get aliveMafiaCount =>
      where((player) => player.role.team == RoleTeam.mafia && player.state.isAlive).length;

  PlayerWithState get don => singleWhere((player) => player.role == PlayerRole.don);

  PlayerWithState get sheriff => singleWhere((player) => player.role == PlayerRole.sheriff);

  List<PlayerWithState> get mafiaTeam =>
      where((player) => player.role.team == RoleTeam.mafia).toUnmodifiableList();
}
