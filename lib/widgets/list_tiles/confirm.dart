import "package:flutter/material.dart";

import "../confirmation_dialog.dart";

class ConfirmationListTile extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget confirmationContent;
  final VoidCallback onConfirm;
  final String? confirmationRememberKey;

  const ConfirmationListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    required this.confirmationContent,
    required this.onConfirm,
    this.confirmationRememberKey,
  });

  @override
  Widget build(BuildContext context) => ListTile(
        leading: leading ?? const SizedBox.shrink(),
        title: title,
        subtitle: subtitle,
        onTap: () async {
          final res = await showDialog<bool>(
            context: context,
            builder: (context) => ConfirmationDialog(
              title: title,
              content: confirmationContent,
              rememberKey: confirmationRememberKey,
            ),
          );
          if (res ?? false) {
            onConfirm();
          }
        },
      );
}
