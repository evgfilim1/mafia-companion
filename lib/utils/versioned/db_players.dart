import "../db/models.dart" as db_models;
import "../errors.dart";
import "../json/from_json.dart";
import "../json/to_json.dart";
import "base.dart";

enum DBPlayerVersion {
  v1(1),
  ;

  static const latest = v1;

  final int value;

  const DBPlayerVersion(this.value);

  factory DBPlayerVersion.byValue(int value) => values.singleWhere(
        (e) => e.value == value,
        orElse: () => throw ArgumentError(
          "Unknown value, must be one of: ${values.map((e) => e.value).join(", ")}",
        ),
      );
}

class VersionedDBPlayers extends Versioned<DBPlayerVersion, List<db_models.Player>> {
  const VersionedDBPlayers(
    super.value, {
    super.version = DBPlayerVersion.latest,
  });

  @override
  String get valueKey => "players";

  @override
  dynamic versionToJson(DBPlayerVersion value) => value.value;

  @override
  dynamic valueToJson(List<db_models.Player> value) => value.map((e) => e.toJson()).toList();

  static DBPlayerVersion _versionFromJson(dynamic value) {
    final versionInt = value as int;
    final DBPlayerVersion version;
    try {
      version = DBPlayerVersion.byValue(versionInt);
    } on ArgumentError {
      throw UnsupportedVersion(version: versionInt);
    }
    return version;
  }

  factory VersionedDBPlayers.fromJson(dynamic json) => Versioned.fromJsonImpl(
        json,
        valueKey: "players",
        versionFromJson: _versionFromJson,
        valueFromJson: (json, version) =>
            (json as List<dynamic>).parseJsonList((e) => dbPlayerFromJson(e, version: version)),
        create: VersionedDBPlayers.new,
      );
}
