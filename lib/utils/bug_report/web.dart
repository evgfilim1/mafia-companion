import "dart:convert";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:provider/provider.dart";

import "../errors.dart";
import "../game_controller.dart";
import "../ui.dart";
import "stub.dart";

Future<void> reportBug(BuildContext context) async {
  final controller = context.read<GameController>();
  final packageInfo = context.read<PackageInfo>();

  final data = <String, dynamic>{
    "packageInfo": packageInfo.data,
    "game": <String, dynamic>{
      "seed": controller.playerRandomSeed,
      "log": controller.gameLog.map<dynamic>((e) => e.data).toList(),
    },
  };
  final reportString = jsonEncode(
    data,
    toEncodable: (e) => throw UnsupportedError("Cannot encode class ${e.runtimeType} to JSON"),
  );

  await Clipboard.setData(ClipboardData(text: "```json\n$reportString\n```"));
  if (!context.mounted) {
    throw ContextNotMountedError();
  }
  showSnackBar(context, const SnackBar(content: Text("Отчёт скопирован в буфер обмена")));
}
