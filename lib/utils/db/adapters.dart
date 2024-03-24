import "package:hive_flutter/hive_flutter.dart";

import "../../game/player.dart";

class PlayerRoleAdapter extends TypeAdapter<PlayerRole> {
  @override
  final int typeId = 0;

  @override
  PlayerRole read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PlayerRole.citizen;
      case 1:
        return PlayerRole.sheriff;
      case 2:
        return PlayerRole.mafia;
      case 3:
        return PlayerRole.don;
      default:
        throw const FormatException("Unknown PlayerRole");
    }
  }

  @override
  void write(BinaryWriter writer, PlayerRole obj) {
    writer.writeByte(
      switch (obj) {
        PlayerRole.citizen => 0,
        PlayerRole.sheriff => 1,
        PlayerRole.mafia => 2,
        PlayerRole.don => 3,
      },
    );
  }
}
