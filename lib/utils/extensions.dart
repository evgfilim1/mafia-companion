import "dart:math";

extension MinMaxItemNum<T extends num> on Iterable<T> {
  T max() => reduce((value, element) => value > element ? value : element);

  T min() => reduce((value, element) => value < element ? value : element);
}

extension ToUnmodifiableList<T> on Iterable<T> {
  List<T> toUnmodifiableList() => List<T>.unmodifiable(this);
}

extension Sum on Iterable<int> {
  int get sum => fold(0, (value, element) => value + element);
}

extension IsAnyOf<T> on T {
  bool isAnyOf(Iterable<T> values) => values.contains(this);
}

extension RandomElement<T> on List<T> {
  T get randomElement => this[Random().nextInt(length)];
}
