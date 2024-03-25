import "dart:async";

import "package:flutter/material.dart";

class _EditorDialog extends StatefulWidget {
  final Widget title;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final TextCapitalization? textCapitalization;
  final String? initialText;
  final String? labelText;
  final FutureOr<String?> Function(String?)? validator;
  final FutureOr<void> Function(String)? onSubmit;

  const _EditorDialog({
    required this.title,
    this.controller,
    this.keyboardType,
    this.textCapitalization,
    this.initialText,
    this.labelText,
    this.validator,
    this.onSubmit,
});

  @override
  State<_EditorDialog> createState() => _EditorDialogState();
}

class _EditorDialogState extends State<_EditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;
  String? _currentError;
  var _validationInProgress = false;

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
    setState(() => _validationInProgress = true);
    final error = await widget.validator?.call(_controller.text);
    setState(() {
      _currentError = error;
      _validationInProgress = false;
    });
    if (_formKey.currentState!.validate()) {
      await widget.onSubmit?.call(_controller.text);
      if (!context.mounted) {
        return;
      }
      Navigator.pop(context);
    }
  }

  String? _validator(String? value) => _currentError;

  @override
  Widget build(BuildContext context) => AlertDialog(
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
          suffix: _validationInProgress
              ? const CircularProgressIndicator()
              : null,
        ),
        validator: _validator,
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
  );
}


class TextFieldListTile extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final TextCapitalization? textCapitalization;
  final String? initialText;
  final String? labelText;
  final FutureOr<String?> Function(String?)? validator;
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
  Widget build(BuildContext context) => ListTile(
        leading: leading ?? const SizedBox.shrink(),
        title: title,
        subtitle: subtitle,
        onTap: () {
          showDialog<void>(
            context: context,
            builder: (context) => _EditorDialog(
              title: title,
              controller: controller,
              keyboardType: keyboardType,
              textCapitalization: textCapitalization,
              initialText: initialText,
              labelText: labelText,
              validator: validator,
              onSubmit: onSubmit,
            ),
          );
        },
      );
}
