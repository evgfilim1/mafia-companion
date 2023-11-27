import "dart:async";
import "dart:convert";
import "dart:io";

import "package:async/async.dart";
import "package:crypto/crypto.dart";
import "package:flutter/foundation.dart";
import "package:flutter/services.dart";
import "package:http/http.dart" as http;
import "package:intl/intl.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:path/path.dart" as path;
import "package:path_provider/path_provider.dart" as pp;

import "apk_installer.dart";
import "downloader.dart";
import "errors.dart";
import "extensions.dart";
import "github.dart";
import "json.dart";
import "log.dart";
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

  /// Download URL for the release
  final String downloadUrl;

  /// SHA1 checksum for the file to be downloaded from [downloadUrl], `null` when not available
  final String? sha1sum;

  const NewVersionInfo({
    required this.version,
    required this.releaseNotes,
    required this.downloadUrl,
    required this.sha1sum,
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
  return (jsonDecode(response.body) as List<dynamic>).parseJsonList(GitHubRelease.fromJson);
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
  if (currentVersion == latestVersion) {
    return null;
  }
  if (currentVersion > latestVersion) {
    if (!kDebugMode) {
      throw StateError("Current version is greater than latest version and not in debug mode");
    }
    return null;
  }
  final changelog = _formatChangelog(
    releases: releases,
    from: currentVersion,
    to: latestVersion,
  );
  final (downloadUrl, checksum) = await getReleaseDownloadUrl(latestRelease: releases.first);
  return NewVersionInfo(
    version: latestVersion.toString(),
    releaseNotes: changelog,
    downloadUrl: downloadUrl,
    sha1sum: checksum,
  );
}

class _OtaUpdateSession {
  final NewVersionInfo _info;
  CancelableOperation<void>? _downloadOperation;
  bool _downloadFinished = false;

  _OtaUpdateSession(this._info);

  bool get isDownloading => _downloadOperation != null;

  bool get isDownloadFinished => _downloadFinished;

  static Future<String> getUpdateFilePath() async =>
      path.join((await pp.getApplicationCacheDirectory()).path, "update.apk");

  Future<void> download({ProgressCallback? onProgress}) async {
    if (_downloadOperation != null) {
      throw StateError("Update is already running");
    }
    try {
      _downloadOperation = await downloadFile(
        _info.downloadUrl,
        destination: await getUpdateFilePath(),
        onProgress: onProgress,
      );
      await _downloadOperation!.valueOrCancellation();
      if (!_downloadOperation!.isCanceled) {
        _downloadFinished = true;
      }
    } finally {
      _downloadOperation = null;
    }
  }

  Future<bool> checkSha1sum({bool throwOnMismatch = false}) async {
    if (_info.sha1sum == null) {
      throw StateError("SHA1 checksum is not available");
    }
    final completer = Completer<Digest>();
    final output =
        ChunkedConversionSink<Digest>.withCallback((data) => completer.complete(data.single));
    final input = sha1.startChunkedConversion(output);
    final file = File(await getUpdateFilePath());
    await file.openRead().forEach(input.add);
    input.close();
    final digest = await completer.future;
    final result = digest.toString() == _info.sha1sum!;
    if (!result && throwOnMismatch) {
      throw ChecksumMismatch(actual: digest.toString(), expected: _info.sha1sum!);
    }
    return result;
  }

  Stream<double> installWithProgress() async* {
    yield* requestSelfUpdateWithProgress(path: await getUpdateFilePath());
  }

  Future<void> cancel() async {
    await _downloadOperation?.cancel();
  }
}

enum OtaAction {
  downloading,
  installing,
  error,
}

class UpdatesChecker with ChangeNotifier {
  static final _log = Logger("UpdatesChecker");

  NewVersionInfo? _info;
  _OtaUpdateSession? _currentOtaSession;

  var _downloaded = 0;
  int? _total;
  OtaAction? _currentAction;

  NewVersionInfo? get updateInfo => _info;

  bool get hasUpdate => _info != null;

  bool get isOtaRunning => _currentOtaSession != null;

  bool get isCancellable => _currentAction != OtaAction.installing;

  double? get progress {
    if (_total == null) {
      return null;
    }
    return _downloaded / _total!;
  }

  OtaAction? get currentAction => _currentAction;

  Future<NewVersionInfo?> checkForUpdates({bool rethrow_ = false}) async {
    if (kIsWeb) {
      throw UnsupportedError("Web platform is not supported");
    }
    NewVersionInfo? info;
    try {
      info = await _checkForUpdates();
    } on http.ClientException catch (e) {
      _log.w("Error while checking for updates: $e");
      if (rethrow_) {
        rethrow;
      }
    } catch (e, stackTrace) {
      _log.e("Error while checking for updates: $e\n$stackTrace");
      if (rethrow_) {
        rethrow;
      }
    }
    if (info != _info) {
      _info = info;
      notifyListeners();
    }
    return _info;
  }

  Future<void> startOtaUpdateSession() async {
    if (!hasUpdate) {
      return;
    }
    if (isOtaRunning) {
      throw StateError("Update is already running");
    }
    _currentOtaSession = _OtaUpdateSession(_info!);
    _currentAction = OtaAction.downloading;
    notifyListeners();
    var checksumOk = false;
    if (File(await _OtaUpdateSession.getUpdateFilePath()).existsSync() && _info!.sha1sum != null) {
      checksumOk = await _currentOtaSession!.checkSha1sum();
    }
    _log.d("Checksum check result: $checksumOk");
    try {
      if (!checksumOk) {
        await _currentOtaSession!.download(
          onProgress: (downloaded, total) {
            _downloaded = downloaded;
            _total = total;
            notifyListeners();
          },
        );
        if (!_currentOtaSession!.isDownloadFinished) {
          return;
        }
      }
      _currentAction = OtaAction.installing;
      _downloaded = 0;
      _total = null;
      notifyListeners();
      if (_info!.sha1sum != null) {
        checksumOk = await _currentOtaSession!.checkSha1sum(throwOnMismatch: true);
        assert(checksumOk, "Checksum mismatched, but no error thrown");
      }
      await for (final progress in _currentOtaSession!.installWithProgress()) {
        _total = 100;
        _downloaded = (progress * _total!).round();
        notifyListeners();
      }
    } on Exception catch (e, s) {
      _log.e("Error while running OTA update: $e\n$s");
      _currentAction = OtaAction.error;
      if (e is! PlatformException) {
        rethrow;
      }
      if (e.code != "UPDATE_SESSION_FAILED") {
        rethrow;
      }
    } finally {
      _currentOtaSession = null;
      _downloaded = 0;
      _total = null;
      notifyListeners();
    }
  }

  Future<void> cancelOtaUpdate() async {
    if (!isCancellable) {
      throw StateError("Update is not cancellable");
    }
    await _currentOtaSession?.cancel();
  }

  @override
  Future<void> dispose() async {
    await _currentOtaSession?.cancel();
    super.dispose();
  }
}
