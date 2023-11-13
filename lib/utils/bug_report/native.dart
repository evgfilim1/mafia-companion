import "dart:convert";
import "dart:io";

import "package:flutter/material.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:path/path.dart" as path;
import "package:path_provider/path_provider.dart" show getTemporaryDirectory;
import "package:provider/provider.dart";
import "package:share_plus/share_plus.dart";

import "../game_controller.dart";
import "stub.dart";

Future<void> reportBug(BuildContext context) async {
  final controller = context.read<GameController>();
  final packageInfo = context.read<PackageInfo>();

  final dir = await getTemporaryDirectory();
  if (!dir.existsSync()) {
    await dir.create(recursive: true);
  }
  final report = File(path.join(dir.path, "report.json"));
  final data = <String, dynamic>{
    "packageInfo": packageInfo.data,
    "game": <String, dynamic>{
      "seed": controller.playerRandomSeed,
      "log": controller.gameLog.map<dynamic>((e) => e.data).toList(),
    },
  };
  await report.writeAsString(jsonEncode(data));
  await Share.shareXFiles(
    [XFile(report.path, mimeType: "application/json", name: "report.json")],
  );
  await report.delete();
}
