import "dart:async";
import "dart:io";

import "package:async/async.dart";
import "package:http/http.dart" as http;

typedef ProgressCallback = void Function(int downloaded, int? total);

Future<CancelableOperation<void>> downloadFile(
  String url, {
  required String destination,
  ProgressCallback? onProgress,
}) async {
  final uri = Uri.parse(url);
  final response = await http.Client().send(http.Request("GET", uri));

  if (response.statusCode >= 400) {
    throw Exception("Failed to download file: ${response.statusCode} ${response.reasonPhrase}");
  }

  var downloaded = 0;
  final stream = response.stream;
  onProgress?.call(0, response.contentLength);
  final file = await File(destination).open(mode: FileMode.write);
  final ss = stream.listen((chunk) {
    downloaded += chunk.length;
    onProgress?.call(downloaded, response.contentLength);
    file.writeFromSync(chunk);
  });
  return CancelableOperation.fromFuture(
    ss.asFuture(),
    onCancel: () async {
      await ss.cancel();
      await file.flush();
      await file.close();
    },
  );
}
