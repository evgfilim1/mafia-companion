import "package:flutter/material.dart";

class InformationDialog extends StatelessWidget {
  final Widget title;
  final Widget content;
  final List<Widget> extraActions;

  const InformationDialog({
    super.key,
    required this.title,
    required this.content,
    this.extraActions = const [],
  });

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: title,
        content: content,
        actions: [
          ...extraActions,
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ОК"),
          ),
        ],
      );
}
