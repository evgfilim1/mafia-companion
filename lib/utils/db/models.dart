import "package:flutter/foundation.dart";
import "package:hive_flutter/hive_flutter.dart";

part "models.g.dart";

@HiveType(typeId: 1)
@immutable
class Player {
  @HiveField(0)
  final String nickname;

  @HiveField(1, defaultValue: "")
  final String realName;

  const Player({
    required this.nickname,
    required this.realName,
  });

  Player copyWith({
    String? nickname,
    String? realName,
  }) =>
      Player(
        nickname: nickname ?? this.nickname,
        realName: realName ?? this.realName,
      );
}
