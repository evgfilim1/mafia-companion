import "package:flutter/material.dart";

abstract class OrientationDependentWidget extends StatelessWidget {
  const OrientationDependentWidget({super.key});

  Widget buildPortrait(BuildContext context);

  Widget buildLandscape(BuildContext context);

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      return buildPortrait(context);
    }
    return buildLandscape(context);
  }
}
