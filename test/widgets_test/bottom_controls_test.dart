import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mafia_companion/widgets/bottom_controls.dart";

Widget _createWidget({
  VoidCallback? onTapBack,
  String backLabel = "Назад",
  VoidCallback? onTapNext,
  String nextLabel = "Далее",
}) =>
    Material(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: BottomControlBar(
          onTapBack: onTapBack,
          backLabel: backLabel,
          onTapNext: onTapNext,
          nextLabel: nextLabel,
        ),
      ),
    );

void main() {
  group("BottomControlBar", () {
    testWidgets(
      "Test callbacks",
      (tester) async {
        final backCallback = expectAsync0<void>(
          () {},
          count: 1,
          id: "onTapBack",
        );
        final nextCallback = expectAsync0<void>(
          () {},
          count: 1,
          id: "onTapNext",
        );
        final bottomControlBar = _createWidget(
          onTapBack: backCallback,
          onTapNext: nextCallback,
        );
        await tester.pumpWidget(bottomControlBar);

        await tester.tap(find.text("Назад"));
        await tester.tap(find.text("Далее"));
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets("Test labels", (tester) async {
      final bottomControlBar = _createWidget(
        backLabel: "<<<",
        nextLabel: ">>>",
      );
      await tester.pumpWidget(bottomControlBar);

      expect(find.text("<<<"), findsOneWidget);
      expect(find.text(">>>"), findsOneWidget);
      expect(find.text("Назад"), findsNothing);
      expect(find.text("Далее"), findsNothing);
    });

    testWidgets("Test null callbacks", (tester) async {
      final bottomControlBar = _createWidget();
      await tester.pumpWidget(bottomControlBar);

      // These should not throw
      await tester.tap(find.text("Назад"));
      await tester.tap(find.text("Далее"));
    });
  });
}
