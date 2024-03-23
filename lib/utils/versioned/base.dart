import "package:flutter/foundation.dart";

typedef VersionFromJson<V extends Enum> = V Function(dynamic value);
typedef ValueFromJson<V extends Enum, T> = T Function(dynamic value, V version);

abstract class Versioned<V extends Enum, T> {
  final V version;
  final T value;

  const Versioned(
    this.value, {
    required this.version,
  });

  @protected
  String get valueKey;

  @protected
  dynamic versionToJson(V value);

  @protected
  dynamic valueToJson(T value);

  Map<String, dynamic> toJson() => {
        "version": versionToJson.call(version),
        valueKey: valueToJson.call(value),
      };

  @protected
  static R fromJsonImpl<V extends Enum, T, R extends Versioned<V, T>>(
    dynamic json, {
    required String valueKey,
    required VersionFromJson<V> versionFromJson,
    required ValueFromJson<V, T> valueFromJson,
    required R Function(T value, {V version}) create,
  }) {
    if (json is! Map<String, dynamic>) {
      throw ArgumentError.value(json, "json", "Expected a map");
    }
    final version = versionFromJson(json["version"]);
    final value = valueFromJson(json[valueKey], version);
    return create(value, version: version);
  }
}
