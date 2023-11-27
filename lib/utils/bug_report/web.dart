import "package:flutter/material.dart";
import "package:flutter/services.dart";

import "../errors.dart";
import "../ui.dart";
import "stub.dart";

Future<void> reportBug(BuildContext context) async {
  final jsonData = await reportBugCommonImpl(context);

  await Clipboard.setData(ClipboardData(text: "```json\n$jsonData\n```"));
  if (!context.mounted) {
    throw ContextNotMountedError();
  }
  showSnackBar(context, const SnackBar(content: Text("Отчёт скопирован в буфер обмена")));
}
