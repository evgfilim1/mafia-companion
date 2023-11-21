import "package:flutter/services.dart";

const _methods = MethodChannel("me.evgfilim1.mafia_companion/methods");
const _installProgress = EventChannel("me.evgfilim1.mafia_companion/installProgress");

Future<void> requestSelfUpdate({required String path}) async {
  await _methods.invokeMethod("selfUpdate", {"path": path});
}

Stream<double> requestSelfUpdateWithProgress({required String path}) {
  requestSelfUpdate(path: path);
  return _installProgress.receiveBroadcastStream().cast<double>();
}
