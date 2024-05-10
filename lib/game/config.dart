import "package:meta/meta.dart";

@immutable
class GameConfig {
  /// Whether to continue voting even when a majority is reached and the result is obvious.
  final bool alwaysContinueVoting;

  const GameConfig({
    this.alwaysContinueVoting = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameConfig &&
          runtimeType == other.runtimeType &&
          alwaysContinueVoting == other.alwaysContinueVoting;

  @override
  int get hashCode => alwaysContinueVoting.hashCode;
}
