import "package:flutter/material.dart";

import "../utils/ui.dart";

class NotesMenuItemButton extends StatefulWidget {
  const NotesMenuItemButton({super.key});

  @override
  State<NotesMenuItemButton> createState() => _NotesMenuItemButtonState();
}

class _NotesMenuItemButtonState extends State<NotesMenuItemButton> {
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _showNotes(BuildContext context) {
    showSimpleDialog(
      context: context,
      title: const Text("Заметки"),
      content: TextField(
        controller: _notesController,
        maxLines: null,
      ),
      extraActions: [
        TextButton(
          onPressed: _notesController.clear,
          child: const Text("Очистить"),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => MenuItemButton(
        leadingIcon: const Icon(Icons.sticky_note_2, size: Checkbox.width),
        onPressed: () => _showNotes(context),
        child: const Text("Заметки"),
      );
}
