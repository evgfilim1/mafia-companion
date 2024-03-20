import "dart:convert";

import "package:file_picker/file_picker.dart";
import "package:file_saver/file_saver.dart";
import "package:flutter/foundation.dart";

import "log.dart";

typedef FromJson<T> = T Function(dynamic json);
typedef ToJson<T> = dynamic Function(T value);
typedef ErrorHandler = void Function(Object error, StackTrace stackTrace);

void _defaultErrorHandler(Object error, StackTrace stackTrace, String message) {
  Logger("load_save_file").error("$message: $error\n$stackTrace");
}

Future<T?> loadJsonFile<T>({
  required FromJson<T> fromJson,
  ErrorHandler? onError,
}) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ["json"],
    withData: true,
  );
  if (result == null) {
    return null;
  }
  if (!result.isSinglePick) {
    throw AssertionError("Only single file pick is supported");
  }
  final file = result.files.single;
  try {
    final rawJsonString = String.fromCharCodes(file.bytes!);
    final data = jsonDecode(rawJsonString);
    return fromJson(data);
  } catch (e, st) {
    if (onError != null) {
      onError(e, st);
    } else {
      _defaultErrorHandler(e, st, "Failed to load json file ${file.name}");
    }
    return null;
  }
}

Future<bool> saveJsonFile(
  dynamic data, {
  required String filename,
  // ErrorHandler? onError,
}) async {
  final json = jsonEncode(data);
  final bytes = Uint8List.fromList(json.codeUnits);
  final fs = FileSaver.instance;
  final String? path;
  if (kIsWeb) {
    path = await fs.saveFile(name: filename, ext: "json", bytes: bytes, mimeType: MimeType.json);
  } else {
    path = await fs.saveAs(name: filename, ext: "json", bytes: bytes, mimeType: MimeType.json);
  }
  return path != null;
}
