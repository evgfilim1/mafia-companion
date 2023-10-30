class GitHubAsset {
  final String name;
  final String browserDownloadUrl;

  const GitHubAsset({
    required this.name,
    required this.browserDownloadUrl,
  });

  GitHubAsset.fromJson(Map<String, dynamic> json)
      : this(
          name: json["name"] as String,
          browserDownloadUrl: json["browser_download_url"] as String,
        );
}

class GitHubRelease {
  final String htmlUrl;
  final String tagName;
  final DateTime publishedAt;
  final List<GitHubAsset> assets;
  final String body;

  const GitHubRelease({
    required this.htmlUrl,
    required this.tagName,
    required this.publishedAt,
    required this.assets,
    required this.body,
  });

  GitHubRelease.fromJson(Map<String, dynamic> json)
      : this(
          htmlUrl: json["html_url"] as String,
          tagName: json["tag_name"] as String,
          publishedAt: DateTime.parse(json["published_at"] as String),
          assets: (json["assets"] as List<dynamic>)
              .cast<Map<String, dynamic>>()
              .map(GitHubAsset.fromJson)
              .toList(),
          body: json["body"] as String,
        );
}
