import "package:file_saver/file_saver.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";

import "stub.dart";

Future<void> reportBug(BuildContext context) async {
  final jsonData = await reportBugCommonImpl(context);

  await FileSaver.instance.saveFile(
    name: "bug_report",
    ext: "json",
    bytes: Uint8List.fromList(jsonData.codeUnits),
    mimeType: MimeType.json,
  );
}
