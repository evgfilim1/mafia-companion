import '../utils.dart';

enum PlayerRole {
  mafia,
  don,
  commissar,
  citizen,
  ;
}

class Player {
  bool _isAlive = true;
  final PlayerRole role;
  var _warns = 0;
  final int number;

  Player({required this.role, required this.number});

  Player.randomRole({required int number})
      : this(
          role: PlayerRole.values.randomItem,
          number: number,
        );

  bool get isAlive => _isAlive;

  int get warns => _warns;

  void kill() {
    assert(isAlive, "Player is already dead");
    _isAlive = false;
  }

  void revive() {
    assert(!isAlive, "Player is already alive");
    _isAlive = true;
  }

  void warn() => _warns++;

  void unwarn() {
    if (_warns == 0) {
      return;
    }
    _warns--;
  }
}

List<Player> generatePlayers({
  Map<PlayerRole, int> roles = const {
    PlayerRole.citizen: 6,
    PlayerRole.mafia: 2,
    PlayerRole.commissar: 1,
    PlayerRole.don: 1,
  },
}) {
  final playerRoles = roles.entries
      .expand((entry) => List.filled(entry.value, entry.key))
      .toList(growable: false)
    ..shuffle();
  return playerRoles
      .asMap()
      .entries
      .map((entry) => Player(role: entry.value, number: entry.key + 1))
      .toList(growable: false)
    ..sort((a, b) => a.number.compareTo(b.number))
    ..toUnmodifiableList();
}
