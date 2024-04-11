import "package:flutter/material.dart";

import "../utils/ui.dart";

class NotesMenuItemButton extends StatelessWidget {
  final BuildContext context;
  final TextEditingController controller;

  const NotesMenuItemButton({
    super.key,
    required this.context,
    required this.controller,
  });

  void _showNotes(BuildContext context) {
    showSimpleDialog(
      context: context,
      title: const Text("Заметки"),
      content: TextField(
        controller: controller,
        maxLines: null,
        decoration: InputDecoration(
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: controller.clear,
          ),
          suffixIconColor: Colors.grey,
        ),
        textCapitalization: TextCapitalization.sentences,
        autofocus: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => MenuItemButton(
    leadingIcon: const Icon(Icons.sticky_note_2, size: Checkbox.width),
    onPressed: () => _showNotes(this.context),
    child: const Text("Заметки"),
  );
}
