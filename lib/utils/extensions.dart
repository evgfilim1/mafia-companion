import "dart:math";

import "package:http/http.dart" as http;

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

extension RandomElement<T> on Iterable<T> {
  T get randomElement =>
      length != 0 ? elementAt(Random().nextInt(length)) : (throw StateError("no element"));
}

extension RemovePrefix on String {
  String removePrefix(String prefix) {
    if (startsWith(prefix)) {
      return substring(prefix.length);
    }
    return this;
  }
}

extension RaiseForStatus on http.Response {
  void raiseForStatus({bool Function(int)? isOk}) {
    if (isOk?.call(statusCode) ?? statusCode < 300) {
      return;
    }
    throw http.ClientException("Unexpected status code: $statusCode", request?.url);
  }
}

extension CountWhere<T> on Iterable<T> {
  int countWhere(bool Function(T) test) => where(test).length;
}

extension Zip<T> on Iterable<T> {
  Iterable<(T, T0)> zip<T0>(Iterable<T0> other) sync* {
    final it1 = iterator;
    final it2 = other.iterator;
    while (it1.moveNext() && it2.moveNext()) {
      yield (it1.current, it2.current);
    }
  }
}

extension PrettyDuration on Duration {
  String toMinSecString() {
    final minutes = inMinutes.toString().padLeft(2, "0");
    final seconds = (inSeconds % 60).toString().padLeft(2, "0");
    return "$minutes:$seconds";
  }
}
