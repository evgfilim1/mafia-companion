import "package:flutter/material.dart";

import "../utils/ui.dart";

class ChoiceListTile<T> extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final List<T> items;
  final ConverterFunction<T, String>? itemToString;
  final int index;
  final ValueChanged<T> onChanged;

  const ChoiceListTile({
    super.key,
    this.leading,
    required this.title,
    required this.items,
    this.itemToString,
    required this.index,
    required this.onChanged,
  });

  String _itemToString(T item) => itemToString == null ? item.toString() : itemToString!(item);

  Future<void> _onTileClick(BuildContext context) async {
    final res = await showChoiceDialog(
      context: context,
      items: items,
      itemToString: _itemToString,
      title: title,
      selectedIndex: index,
    );
    if (res != null) {
      onChanged(res);
    }
  }

  @override
  Widget build(BuildContext context) => ListTile(
        leading: leading ?? const SizedBox.shrink(),
        title: title,
        subtitle: Text(_itemToString(items[index])),
        onTap: () => _onTileClick(context),
      );
}
