import "package:flutter/material.dart";

class ToggleListTile extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const ToggleListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  Future<void> _onTap(bool newValue) async => onChanged(newValue);

  @override
  Widget build(BuildContext context) => ListTile(
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing: Switch(
          value: value,
          onChanged: _onTap,
        ),
        onTap: () => _onTap(!value),
      );
}
