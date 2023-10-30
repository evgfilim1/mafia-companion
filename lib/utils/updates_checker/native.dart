import "dart:ffi";

import "../github.dart";

String getReleaseDownloadUrl({
  required GitHubRelease latestRelease,
}) {
  final currentPlatform = Abi.current();
  final arch = switch (currentPlatform) {
    Abi.androidArm64 => "arm64-v8a",
    Abi.androidArm => "armeabi-v7a",
    Abi.androidX64 => "x86_64",
    _ => throw AssertionError("Unsupported platform: $currentPlatform"),
  };
  final asset = latestRelease.assets.singleWhere((e) => e.name == "app-$arch-release.apk");
  return asset.browserDownloadUrl;
}
