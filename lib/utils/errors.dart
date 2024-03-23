class ContextNotMountedError extends AssertionError {
  ContextNotMountedError() : super("Context is not mounted");
}

class ChecksumMismatch extends AssertionError {
  ChecksumMismatch({required String expected, required String actual})
      : super('Checksum mismatch: expected "$expected", got "$actual"');
}

class UnsupportedVersion extends UnsupportedError {
  final int version;

  UnsupportedVersion({
    required this.version,
    String? message,
  }) : super(message ?? "Unsupported version: $version");

  @override
  String toString() => message!;
}

class RemovedVersion extends UnsupportedVersion {
  final String lastSupportedAppVersion;

  RemovedVersion({
    required super.version,
    required this.lastSupportedAppVersion,
    String? message,
  }) : super(
          message: message ??
              "Unsupported version: $version, use app <=v$lastSupportedAppVersion to load this.",
        );
}
