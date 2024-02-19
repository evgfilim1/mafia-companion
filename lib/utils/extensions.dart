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

extension RandomElement<T> on List<T> {
  T get randomElement => this[Random().nextInt(length)];
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
