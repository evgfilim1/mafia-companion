import "package:flutter/foundation.dart";

// Taken from https://regex101.com/r/vkijKf/1/, link itself from https://semver.org/.
final _versionRegex = RegExp(
  r"^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)"
  r"(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?"
  r"(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$",
);

@immutable
class Version implements Comparable<Version> {
  final int major;
  final int minor;
  final int patch;
  final String? preRelease;
  final String? build;

  final String _versionString;

  const Version({
    required int major,
    required int minor,
    required int patch,
    String? preRelease,
    String? build,
  }) : this._(
          major: major,
          minor: minor,
          patch: patch,
          preRelease: preRelease,
          build: build,
          versionString: "$major.$minor.$patch"
              "${preRelease == null ? "" : "-$preRelease"}"
              "${build == null ? "" : "+$build"}",
        );

  const Version._({
    required this.major,
    required this.minor,
    required this.patch,
    required this.preRelease,
    required this.build,
    required String versionString,
  }) : _versionString = versionString;

  factory Version.fromString(String versionString) {
    final match = _versionRegex.firstMatch(versionString);
    if (match == null) {
      throw ArgumentError.value(versionString, "versionString", "Invalid version string");
    }
    final major = int.parse(match[1]!);
    final minor = int.parse(match[2]!);
    final patch = int.parse(match[3]!);
    final preRelease = match[4];
    final build = match[5];
    return Version._(
      major: major,
      minor: minor,
      patch: patch,
      preRelease: preRelease,
      build: build,
      versionString: versionString,
    );
  }

  @override
  String toString() => _versionString;

  @override
  int compareTo(Version other) {
    // 0 if equal, <0 if this < other, >0 if this > other
    if (identical(this, other)) {
      return 0;
    }
    if (major != other.major) {
      return major.compareTo(other.major);
    }
    if (minor != other.minor) {
      return minor.compareTo(other.minor);
    }
    if (patch != other.patch) {
      return patch.compareTo(other.patch);
    }
    if (preRelease == null) {
      if (other.preRelease != null) {
        return 1;
      }
      return 0;
    }
    if (other.preRelease == null) {
      return -1;
    }
    final preReleaseParts = preRelease!.split(".");
    final otherPreReleaseParts = other.preRelease!.split(".");
    for (var i = 0; i < preReleaseParts.length && i < otherPreReleaseParts.length; i++) {
      final part = preReleaseParts[i];
      final otherPart = otherPreReleaseParts[i];
      if (part == otherPart) {
        continue;
      }
      final parsedInt = int.tryParse(part);
      final otherParsedInt = int.tryParse(otherPart);
      if (parsedInt != null && otherParsedInt != null) {
        return parsedInt.compareTo(otherParsedInt);
      }
      if (parsedInt != null /* && otherParsedInt == null */) {
        return -1;
      }
      if (/* parsedInt == null && */ otherParsedInt != null) {
        return 1;
      }
      final cmpResult = part.compareTo(otherPart);
      if (cmpResult != 0) {
        return cmpResult;
      }
    }
    return preReleaseParts.length.compareTo(otherPreReleaseParts.length);
  }

  bool operator <(Version other) => compareTo(other) < 0;

  bool operator <=(Version other) => compareTo(other) <= 0;

  bool operator >(Version other) => compareTo(other) > 0;

  bool operator >=(Version other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) => other is Version && compareTo(other) == 0;

  @override
  int get hashCode => Object.hash(major, minor, patch, preRelease, build);
}
