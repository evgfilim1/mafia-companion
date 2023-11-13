class ContextNotMountedError extends AssertionError {
  ContextNotMountedError() : super("Context is not mounted");
}
