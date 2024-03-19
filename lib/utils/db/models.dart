import "package:flutter/foundation.dart";
import "package:hive_flutter/hive_flutter.dart";

part "models.g.dart";

@HiveType(typeId: 1)
@immutable
class Player {
  @HiveField(0)
  final String nickname;

  const Player({
    required this.nickname,
  });

  Player copyWith({
    String? nickname,
  }) =>
      Player(
        nickname: nickname ?? this.nickname,
      );
}
