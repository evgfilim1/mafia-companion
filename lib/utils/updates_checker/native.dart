import "dart:ffi";

import "package:http/http.dart" as http;

import "../github.dart";
import "stub.dart";

Future<UrlChecksum> getReleaseDownloadUrl({
  required GitHubRelease latestRelease,
}) async {
  final currentPlatform = Abi.current();
  final arch = switch (currentPlatform) {
    Abi.androidArm64 => "arm64-v8a",
    Abi.androidArm => "armeabi-v7a",
    Abi.androidX64 => "x86_64",
    _ => throw AssertionError("Unsupported platform: $currentPlatform"),
  };
  final asset = latestRelease.assets.singleWhere((e) => e.name == "app-$arch-release.apk");
  final checksumAsset =
      latestRelease.assets.where((e) => e.name == "${asset.name}.sha1").singleOrNull;
  final String? checksum;
  if (checksumAsset != null) {
    checksum = await http.read(Uri.parse(checksumAsset.browserDownloadUrl));
  } else {
    checksum = null;
  }
  return (asset.browserDownloadUrl, checksum?.trim());
}
