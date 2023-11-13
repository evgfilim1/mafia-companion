import "dart:async";

import "package:flutter/material.dart";

class TextFieldListTile extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final TextField textField;
  final FutureOr<void> Function()? onSaved;

  const TextFieldListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    required this.textField,
    this.onSaved,
  });

  @override
  Widget build(BuildContext context) => ListTile(
        leading: leading ?? const SizedBox.shrink(),
        title: title,
        subtitle: subtitle,
        onTap: () {
          showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: title,
              content: textField,
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Отмена"),
                ),
                TextButton(
                  onPressed: () async {
                    await onSaved?.call();
                    if (!context.mounted) {
                      return;
                    }
                    Navigator.pop(context);
                  },
                  child: const Text("Применить"),
                ),
              ],
            ),
          );
        },
      );
}
