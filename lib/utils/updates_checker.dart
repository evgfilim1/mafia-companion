import "dart:convert";

import "package:flutter/foundation.dart";
import "package:http/http.dart" as http;
import "package:intl/intl.dart";
import "package:package_info_plus/package_info_plus.dart";

import "extensions.dart";
import "github.dart";
import "updates_checker/stub.dart"
    if (dart.library.ffi) "updates_checker/native.dart"
    if (dart.library.html) "updates_checker/web.dart" show getReleaseDownloadUrl;
import "version.dart";

export "" show NewVersionInfo, UpdatesChecker;

final _releasesUri = Uri.parse("https://api.github.com/repos/evgfilim1/mafia-companion/releases");
final _commitsRegexp = RegExp(r"#+\s*Commits\r?\n.+$", dotAll: true);
final _changelogDateFormat = DateFormat("yyyy-MM-dd");

@immutable
class NewVersionInfo {
  /// Version string
  final String version;

  /// Markdown-formatted release notes
  final String releaseNotes;

  /// Download URL for Android, empty string for web
  final String downloadUrl;

  const NewVersionInfo({
    required this.version,
    required this.releaseNotes,
    required this.downloadUrl,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NewVersionInfo &&
          runtimeType == other.runtimeType &&
          version == other.version &&
          releaseNotes == other.releaseNotes &&
          downloadUrl == other.downloadUrl;

  @override
  int get hashCode => Object.hash(version, releaseNotes, downloadUrl);
}

Future<List<GitHubRelease>> _getAllReleases([http.Client? client]) async {
  client ??= http.Client();
  final response = await client.get(_releasesUri);
  response.raiseForStatus();
  return (jsonDecode(response.body) as List<dynamic>)
      .cast<Map<String, dynamic>>()
      .map(GitHubRelease.fromJson)
      .toList();
}

String _formatChangelog({
  required List<GitHubRelease> releases,
  required Version from,
  Version? to,
}) {
  if (from == to) {
    return "";
  }
  final changelog = StringBuffer();
  final fromIndex = releases.indexWhere((e) => e.tagName.removePrefix("v") == "$from");
  final toIndex = to == null ? 0 : releases.indexWhere((e) => e.tagName.removePrefix("v") == "$to");
  for (var i = fromIndex - 1; i >= toIndex; i--) {
    final release = releases[i];
    final date = _changelogDateFormat.format(release.publishedAt);
    changelog
      ..write("## [${release.tagName}](${release.htmlUrl}) - $date\n\n")
      ..write(
        release.body
            .replaceFirst(_commitsRegexp, "")
            .replaceAllMapped(RegExp("^(#+)", multiLine: true), (m) => "${m[1]!}#")
            .trim(),
      )
      ..write("\n\n");
  }
  return changelog.toString().trim();
}

Future<NewVersionInfo?> _checkForUpdates() async {
  final releases = await _getAllReleases();
  final packageInfo = await PackageInfo.fromPlatform();
  final currentVersion = Version.fromString(packageInfo.version);
  final latestReleaseTag = releases.first.tagName;
  final latestVersion = Version.fromString(latestReleaseTag.removePrefix("v"));
  if (currentVersion <= latestVersion) {
    return null;
  }
  final changelog = _formatChangelog(
    releases: releases,
    from: currentVersion,
    to: latestVersion,
  );
  final downloadUrl = getReleaseDownloadUrl(latestRelease: releases.first);
  return NewVersionInfo(
    version: latestVersion.toString(),
    releaseNotes: changelog,
    downloadUrl: downloadUrl,
  );
}

Future<NewVersionInfo?> _checkForUpdatesImpl({bool rethrow_ = false}) async {
  try {
    return await _checkForUpdates();
  } on http.ClientException catch (e) {
    // TODO: log warning
    // ignore: avoid_print
    print("Error while checking for updates: $e");
    if (rethrow_) {
      rethrow;
    }
    return null;
  } catch (e, stackTrace) {
    // TODO: log error
    // ignore: avoid_print
    print("Error while checking for updates: $e\n$stackTrace");
    if (rethrow_) {
      rethrow;
    }
    return null;
  }
}

class UpdatesChecker with ChangeNotifier {
  NewVersionInfo? _info;

  NewVersionInfo? get updateInfo => _info;

  bool get hasUpdate => _info != null;

  Future<NewVersionInfo?> checkForUpdates({bool rethrow_ = false}) async {
    final info = await _checkForUpdatesImpl(rethrow_: rethrow_);
    if (info != _info) {
      _info = info;
      notifyListeners();
    }
    return _info;
  }
}
