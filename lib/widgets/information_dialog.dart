import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../utils/settings.dart";

class InformationDialog extends StatefulWidget {
  final Widget title;
  final Widget content;
  final List<Widget> extraActions;
  final String? rememberKey;

  const InformationDialog({
    super.key,
    required this.title,
    required this.content,
    this.extraActions = const [],
    this.rememberKey,
  });

  @override
  State<InformationDialog> createState() => _InformationDialogState();
}

class _InformationDialogState extends State<InformationDialog> {
  var _dontShowAgain = false;

  @override
  void initState() {
    super.initState();
    if (widget.rememberKey != null &&
        (context.read<SettingsModel>().getRememberedChoice(widget.rememberKey!) ?? false)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: widget.title,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            widget.content,
            if (widget.rememberKey != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _dontShowAgain = !_dontShowAgain),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _dontShowAgain,
                        onChanged: (value) => setState(() => _dontShowAgain = value!),
                      ),
                      const Text("Больше не показывать"),
                    ],
                  ),
                ),
              ),
          ],
        ),
        actions: [
          ...widget.extraActions,
          TextButton(
            onPressed: () {
              if (widget.rememberKey != null && _dontShowAgain) {
                context.read<SettingsModel>().setRememberedChoice(widget.rememberKey!, true);
              }
              Navigator.pop(context);
            },
            child: const Text("ОК"),
          ),
        ],
      );
}
