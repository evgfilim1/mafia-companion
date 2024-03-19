import "dart:async";

import "package:flutter/material.dart";

class TextFieldListTile extends StatefulWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final TextCapitalization? textCapitalization;
  final String? initialText;
  final String? labelText;
  final String? Function(String?)? validator;
  final FutureOr<void> Function(String)? onSubmit;

  const TextFieldListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.controller,
    this.keyboardType,
    this.textCapitalization,
    this.initialText,
    this.labelText,
    this.validator,
    this.onSubmit,
  });

  @override
  State<TextFieldListTile> createState() => _TextFieldListTileState();
}

class _TextFieldListTileState extends State<TextFieldListTile> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    if (widget.initialText != null) {
      _controller.text = widget.initialText!;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onSaved(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      await widget.onSubmit?.call(_controller.text);
      if (!context.mounted) {
        return;
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) => ListTile(
        leading: widget.leading ?? const SizedBox.shrink(),
        title: widget.title,
        subtitle: widget.subtitle,
        onTap: () {
          showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: widget.title,
              content: Form(
                key: _formKey,
                child: TextFormField(
                  controller: _controller,
                  keyboardType: widget.keyboardType,
                  textCapitalization: widget.textCapitalization ?? TextCapitalization.none,
                  autofocus: true,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: widget.labelText,
                  ),
                  validator: widget.validator,
                  onFieldSubmitted: (_) async => _onSaved(context),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Отмена"),
                ),
                TextButton(
                  onPressed: () => _onSaved(context),
                  child: const Text("Применить"),
                ),
              ],
            ),
          );
        },
      );
}
