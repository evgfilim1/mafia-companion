import "package:flutter/material.dart";

class NotificationDot extends StatelessWidget {
  final double size;
  final Color? color;
  final Widget? child;

  const NotificationDot({
    super.key,
    required this.size,
    this.color,
    this.child,
  });

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(shape: BoxShape.circle, color: color ?? Colors.red),
        child: SizedBox(width: size, height: size, child: child),
      );
}
