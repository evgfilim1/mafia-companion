import "dart:io";

import "package:flutter/material.dart";
import "package:path/path.dart" as path;
import "package:path_provider/path_provider.dart" show getTemporaryDirectory;
import "package:share_plus/share_plus.dart";

import "stub.dart";

Future<void> reportBug(BuildContext context) async {
  final jsonData = await reportBugCommonImpl(context);
  final dir = await getTemporaryDirectory();
  if (!dir.existsSync()) {
    await dir.create(recursive: true);
  }
  final report = File(path.join(dir.path, "report.json"));
  await report.writeAsString(jsonData);
  await Share.shareXFiles(
    [XFile(report.path, mimeType: "application/json", name: "report.json")],
  );
  await report.delete();
}
