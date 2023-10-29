import "dart:convert";
import "dart:ffi";
import "dart:io";

import "package:flutter/foundation.dart";
import "package:http/http.dart" as http;
import "package:package_info_plus/package_info_plus.dart";

import "extensions.dart";

class NewVersionInfo {
  /// Version string
  final String version;

  /// Markdown-formatted release notes
  final String releaseNotes;

  /// Download URL for Android, empty string for web
  final String downloadUrl;

  NewVersionInfo({
    required this.version,
    required this.releaseNotes,
    required this.downloadUrl,
  });
}

Future<NewVersionInfo?> _checkForUpdates() async {
  final uri = Uri.parse("https://api.github.com/repos/evgfilim1/mafia-companion/releases");
  final response = await http.get(uri);
  if (response.statusCode > 299) {
    throw HttpException("Unexpected status code: ${response.statusCode}", uri: uri);
  }
  final json = (jsonDecode(response.body) as List<dynamic>).cast<Map<String, dynamic>>();
  final latestRelease = json.first;
  final packageInfo = await PackageInfo.fromPlatform();
  final currentVersion = packageInfo.version;
  final latestVersion = (latestRelease["tag_name"] as String).removePrefix("v");
  if (currentVersion == latestVersion) {
    return null;
  }
  final releaseNotes = (latestRelease["body"] as String).replaceFirst(RegExp(r"#+ Commits.*$", dotAll: true), "");
  if (kIsWeb) {
    return NewVersionInfo(
      version: latestVersion,
      releaseNotes: releaseNotes,
      downloadUrl: "",
    );
  }
  final currentPlatform = Abi.current();
  final arch = switch (currentPlatform) {
    Abi.androidArm64 => "arm64-v8a",
    Abi.androidArm => "armeabi-v7a",
    Abi.androidX64 => "x86_64",
    _ => throw AssertionError("Unsupported platform: $currentPlatform"),
  };
  final assets = (latestRelease["assets"] as List<dynamic>).cast<Map<String, dynamic>>();
  final asset = assets.singleWhere((e) => e["name"] == "app-$arch-release.apk");
  final downloadUrl = asset["browser_download_url"] as String;
  return NewVersionInfo(
    version: latestVersion,
    releaseNotes: releaseNotes,
    downloadUrl: downloadUrl,
  );
}

Future<NewVersionInfo?> checkForUpdates({bool rethrow_ = false}) async {
  try {
    return await _checkForUpdates();
  } on SocketException catch (e) {
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
