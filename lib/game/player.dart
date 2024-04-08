import "package:meta/meta.dart";

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

  factory RoleTeam.byName(String name) => RoleTeam.values.byName(name);

  RoleTeam get other => switch (this) {
        RoleTeam.mafia => RoleTeam.citizen,
        RoleTeam.citizen => RoleTeam.mafia,
      };
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

  factory PlayerRole.byName(String name) => PlayerRole.values.byName(name);
}

@immutable
class Player {
  final PlayerRole role;
  final int number;
  final String? nickname;

  const Player({
    required this.role,
    required this.number,
    required this.nickname,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Player &&
          runtimeType == other.runtimeType &&
          role == other.role &&
          number == other.number &&
          nickname == other.nickname;

  @override
  int get hashCode => Object.hash(role, number, nickname);

  @useResult
  PlayerWithState withState({
    PlayerState? state,
  }) =>
      PlayerWithState(
        role: role,
        number: number,
        nickname: nickname,
        state: state ?? const PlayerState(),
      );
}

@immutable
class PlayerState {
  final bool isAlive;
  final int warns;
  final bool isKicked;

  const PlayerState({
    this.isAlive = true,
    this.warns = 0,
    this.isKicked = false,
  });

  @useResult
  PlayerState copyWith({
    bool? isAlive,
    int? warns,
    bool? isKicked,
  }) =>
      PlayerState(
        isAlive: isAlive ?? this.isAlive,
        warns: warns ?? this.warns,
        isKicked: isKicked ?? this.isKicked,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerState &&
          runtimeType == other.runtimeType &&
          isAlive == other.isAlive &&
          warns == other.warns &&
          isKicked == other.isKicked;

  @override
  int get hashCode => Object.hash(isAlive, warns, isKicked);
}

@immutable
class PlayerWithState extends Player {
  final PlayerState state;

  const PlayerWithState({
    required super.role,
    required super.number,
    required super.nickname,
    required this.state,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerWithState &&
          runtimeType == other.runtimeType &&
          role == other.role &&
          number == other.number &&
          nickname == other.nickname &&
          state == other.state;

  @override
  int get hashCode => Object.hash(super.hashCode, state);
}

List<Player> generatePlayers({
  List<String?>? nicknames,
  List<PlayerRole>? roles,
}) {
  final playerRoles = roles ?? (List.of(rolesList)..shuffle());
  return [
    for (var i = 0; i < playerRoles.length; i++)
      Player(
        role: playerRoles[i],
        number: i + 1,
        nickname: nicknames?.elementAt(i),
      ),
  ].toUnmodifiableList();
}
