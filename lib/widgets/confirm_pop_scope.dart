import "package:flutter/material.dart";

import "confirmation_dialog.dart";

class ConfirmPopScope extends StatelessWidget {
  final bool canPop;
  final ConfirmationDialog dialog;
  final VoidCallback? onPopConfirmed;
  final Widget child;

  const ConfirmPopScope({
    super.key,
    required this.canPop,
    required this.dialog,
    this.onPopConfirmed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: canPop,
        onPopInvoked: (didPop) async {
          if (didPop) return;
          final res = await showDialog<bool>(
            context: context,
            builder: (context) => dialog,
          );
          if (res ?? false) {
            if (onPopConfirmed != null) {
              onPopConfirmed!();
            } else {
              if (!context.mounted) {
                return;
              }
              Navigator.pop(context);
            }
          }
        },
        child: child,
      );
}
