class ContextNotMountedError extends AssertionError {
  ContextNotMountedError() : super("Context is not mounted");
}

class ChecksumMismatch extends AssertionError {
  ChecksumMismatch({required String expected, required String actual})
      : super('Checksum mismatch: expected "$expected", got "$actual"');
}

class UnsupportedGameLogVersion extends UnsupportedError {
  final int version;

  UnsupportedGameLogVersion({
    required this.version,
    String? message,
  }) : super(message ?? "Unsupported game log version: $version");

  @override
  String toString() => message!;
}

class RemovedGameLogVersion extends UnsupportedGameLogVersion {
  final String lastSupportedAppVersion;

  RemovedGameLogVersion({
    required super.version,
    required this.lastSupportedAppVersion,
    String? message,
  }) : super(
          message: message ??
              "Unsupported game log version: $version, use app"
                  " <=v$lastSupportedAppVersion to open it.",
        );
}
