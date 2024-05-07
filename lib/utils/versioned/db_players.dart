import "../db/models.dart" as db_models;
import "../errors.dart";
import "../json/from_json.dart";
import "../json/to_json.dart";
import "base.dart";

enum DBPlayerVersion {
  v1(1),
  v2(2),
  ;

  static const latest = v2;

  final int value;

  const DBPlayerVersion(this.value);

  factory DBPlayerVersion.byValue(int value) => values.singleWhere(
        (e) => e.value == value,
        orElse: () => throw ArgumentError(
          "Unknown value, must be one of: ${values.map((e) => e.value).join(", ")}",
        ),
      );
}

typedef VersionedDBPlayersValueType = Map<String, db_models.PlayerWithStats>;

class VersionedDBPlayers extends Versioned<DBPlayerVersion, VersionedDBPlayersValueType> {
  const VersionedDBPlayers(
    super.value, {
    super.version = DBPlayerVersion.latest,
  });

  @override
  String get valueKey => "players";

  @override
  dynamic versionToJson(DBPlayerVersion value) => value.value;

  @override
  dynamic valueToJson(VersionedDBPlayersValueType value) =>
      value.map((k, v) => MapEntry(k, v.toJson()));

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

  static VersionedDBPlayersValueType _valueFromJson(dynamic json, DBPlayerVersion version) =>
      switch (version) {
        DBPlayerVersion.v1 => (json as List<dynamic>)
            .parseJsonList((e) => dbPlayerFromJson(e, version: version))
            .asMap()
            .map((k, v) => MapEntry(k.toString(), v)),
        DBPlayerVersion.v2 => (json as Map<String, dynamic>)
            .parseJsonMap((e) => dbPlayerFromJson(e as Map<String, dynamic>, version: version)),
      };

  factory VersionedDBPlayers.fromJson(dynamic json) => Versioned.fromJsonImpl(
        json,
        valueKey: "players",
        versionFromJson: _versionFromJson,
        valueFromJson: _valueFromJson,
        create: VersionedDBPlayers.new,
      );
}
