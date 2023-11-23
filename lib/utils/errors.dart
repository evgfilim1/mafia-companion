class ContextNotMountedError extends AssertionError {
  ContextNotMountedError() : super("Context is not mounted");
}

class ChecksumMismatch extends AssertionError {
  ChecksumMismatch({required String expected, required String actual})
      : super('Checksum mismatch: expected "$expected", got "$actual"');
}
