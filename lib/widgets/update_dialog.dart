import "package:flutter/material.dart";
import "package:flutter_markdown/flutter_markdown.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:provider/provider.dart";

import "../utils/updates_checker.dart";
import "confirmation_dialog.dart";

class UpdateAvailableDialog extends StatelessWidget {
  final NewVersionInfo info;

  const UpdateAvailableDialog({
    super.key,
    required this.info,
  });

  @override
  Widget build(BuildContext context) {
    final packageInfo = context.read<PackageInfo>();
    return ConfirmationDialog(
      title: const Text("Обновить приложение?"),
      content: SingleChildScrollView(
        child: MarkdownBody(
          data: "Текущая версия: **${packageInfo.version}**\n\n"
              "Новая версия: **${info.version}**\n\n"
              "# Что нового?\n\n${info.releaseNotes}",
          listItemCrossAxisAlignment: MarkdownListItemCrossAxisAlignment.start,
        ),
      ),
    );
  }
}
