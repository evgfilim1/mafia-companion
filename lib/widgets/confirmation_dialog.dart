import "package:flutter/material.dart";

class ConfirmationDialog extends StatelessWidget {
  final Widget title;
  final Widget content;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: title,
        content: content,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Нет"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Да"),
          ),
        ],
      );
}
