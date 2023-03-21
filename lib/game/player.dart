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
  var warns = 0;
  final int number;

  Player({required this.role, required this.number});

  Player.randomRole({required int number})
      : this(
          role: PlayerRole.values.randomItem,
          number: number,
        );

  bool get isAlive => _isAlive;

  void kill() => _isAlive = false;

  void warn() {
    warns++;
    if (warns > 3) {
      kill();
    }
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
