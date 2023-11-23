import "../github.dart";

typedef UrlChecksum = (String url, String? checksum);

Future<UrlChecksum> getReleaseDownloadUrl({
  required GitHubRelease latestRelease,
}) async =>
    throw UnimplementedError("stub");
