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
