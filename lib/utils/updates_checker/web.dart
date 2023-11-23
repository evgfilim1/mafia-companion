import "../github.dart";
import "stub.dart";

Future<UrlChecksum> getReleaseDownloadUrl({
  required GitHubRelease latestRelease,
}) =>
    throw UnsupportedError("Cannot download releases on web");
