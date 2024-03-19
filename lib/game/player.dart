import "dart:math";

import "package:flutter/foundation.dart";

import "../utils/extensions.dart";

const roles = {
  PlayerRole.citizen: 6,
  PlayerRole.mafia: 2,
  PlayerRole.sheriff: 1,
  PlayerRole.don: 1,
};

final rolesList =
    roles.entries.expand((entry) => List.filled(entry.value, entry.key)).toUnmodifiableList();

enum RoleTeam {
  mafia,
  citizen,
  ;

  factory RoleTeam.byName(String name) => RoleTeam.values.singleWhere((e) => e.name == name);
}

enum PlayerRole {
  mafia(RoleTeam.mafia),
  don(RoleTeam.mafia),
  sheriff(RoleTeam.citizen),
  citizen(RoleTeam.citizen),
  ;

  /// The team this role belongs to.
  final RoleTeam team;

  const PlayerRole(this.team);

  factory PlayerRole.byName(String name) => PlayerRole.values.singleWhere((e) => e.name == name);
}

@immutable
class Player {
  final PlayerRole role;
  final int number;
  final bool isAlive;
  final int warns;
  final String? nickname;

  const Player({
    required this.role,
    required this.number,
    required this.nickname,
    this.isAlive = true,
    this.warns = 0,
  });

  Player copyWith({
    bool? isAlive,
    int? warns,
  }) =>
      Player(
        isAlive: isAlive ?? this.isAlive,
        role: role,
        number: number,
        nickname: nickname,
        warns: warns ?? this.warns,
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
  List<String?>? nicknames,
  Random? random,
}) {
  final playerRoles = List.of(rolesList)..shuffle(random);
  return [
    for (var i = 0; i < playerRoles.length; i++)
      Player(
        role: playerRoles[i],
        number: i + 1,
        nickname: nicknames?.elementAt(i),
        isAlive: true,
        warns: 0,
      ),
  ].toUnmodifiableList();
}
