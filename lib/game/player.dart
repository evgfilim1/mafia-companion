import '../utils.dart';

enum PlayerRole {
  mafia,
  don,
  sheriff,
  citizen,
  ;

  /// Returns true if this role is one of [PlayerRole.mafia] or [PlayerRole.don]
  bool get isMafia => isAnyOf(const [PlayerRole.mafia, PlayerRole.don]);

  /// Returns true if this role is one of [PlayerRole.citizen] or [PlayerRole.sheriff]
  bool get isCitizen => isAnyOf(const [PlayerRole.citizen, PlayerRole.sheriff]);
}

class Player {
  final PlayerRole role;
  final int number;
  final bool isAlive;

  const Player({
    required this.role,
    required this.number,
    this.isAlive = true,
  });

  Player copyWith({
    PlayerRole? role,
    int? number,
    bool? isAlive,
  }) =>
      Player(
        isAlive: isAlive ?? this.isAlive,
        role: role ?? this.role,
        number: number ?? this.number,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Player &&
          runtimeType == other.runtimeType &&
          role == other.role &&
          number == other.number &&
          isAlive == other.isAlive;

  @override
  int get hashCode => Object.hash(role, number, isAlive);
}

List<Player> generatePlayers({
  Map<PlayerRole, int> roles = const {
    PlayerRole.citizen: 6,
    PlayerRole.mafia: 2,
    PlayerRole.sheriff: 1,
    PlayerRole.don: 1,
  },
}) {
  if (roles[PlayerRole.sheriff]! + roles[PlayerRole.don]! != 2) {
    throw ArgumentError("Only one sheriff and one don are allowed");
  }
  if (roles[PlayerRole.mafia]! < 1) {
    throw ArgumentError("At least one mafia is required");
  }
  if (roles[PlayerRole.mafia]! >= roles[PlayerRole.citizen]!) {
    throw ArgumentError("Too many mafia");
  }
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
