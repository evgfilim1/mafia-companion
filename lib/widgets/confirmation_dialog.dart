import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../utils/settings.dart";

class ConfirmationDialog extends StatefulWidget {
  final Widget title;
  final Widget content;
  final String? rememberKey;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.content,
    this.rememberKey,
  });

  @override
  State<ConfirmationDialog> createState() => _ConfirmationDialogState();
}

class _ConfirmationDialogState extends State<ConfirmationDialog> {
  var _rememberChoice = false;

  @override
  void initState() {
    super.initState();
    if (widget.rememberKey != null) {
      final rememberedChoice =
          context.read<SettingsModel>().getRememberedChoice(widget.rememberKey!);
      if (rememberedChoice != null) {
        _onButtonPressed(rememberedChoice);
      }
    }
  }

  void _onButtonPressed(bool value) {
    if (_rememberChoice) {
      context.read<SettingsModel>().setRememberedChoice(widget.rememberKey!, value);
    }
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: widget.title,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            widget.content,
            if (widget.rememberKey != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _rememberChoice = !_rememberChoice),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _rememberChoice,
                        onChanged: (value) => setState(() => _rememberChoice = value!),
                      ),
                      const Text("Запомнить выбор"),
                    ],
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => _onButtonPressed(false),
            child: const Text("Нет"),
          ),
          TextButton(
            onPressed: () => _onButtonPressed(true),
            child: const Text("Да"),
          ),
        ],
      );
}
