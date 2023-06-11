import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mafia_companion/widgets/counter.dart";

Widget _buildWidget({
  required int min,
  required int max,
  required int initialValue,
  ValueChanged<int>? onValueChanged,
}) =>
    Material(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Counter(
          min: min,
          max: max,
          initialValue: initialValue,
          onValueChanged: onValueChanged,
        ),
      ),
    );

void main() {
  group("Counter", () {
    testWidgets("Test UI consistency", (tester) async {
      final counter = _buildWidget(
        min: 0,
        max: 10,
        initialValue: 5,
        onValueChanged: (newValue) {},
      );
      await tester.pumpWidget(counter);

      expect(find.byIcon(Icons.remove), findsOneWidget);
      expect(find.text("5"), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets("Test counter calls onValueChanged", (tester) async {
      final counter = _buildWidget(
        min: 0,
        max: 10,
        initialValue: 5,
      );
      await tester.pumpWidget(counter);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      expect(find.text("6"), findsOneWidget);
      await tester.tap(find.byIcon(Icons.remove));
      await tester.pump();
      expect(find.text("5"), findsOneWidget);
    });

    testWidgets("Test can't go beyond limits", (tester) async {
      final counter = _buildWidget(
        min: 0,
        max: 2,
        initialValue: 0,
      );
      await tester.pumpWidget(counter);

      await tester.tap(find.byIcon(Icons.remove));
      await tester.pump();
      expect(find.text("0"), findsOneWidget);
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      expect(find.text("1"), findsOneWidget);
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      expect(find.text("2"), findsOneWidget);
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      expect(find.text("3"), findsNothing);
      expect(find.text("2"), findsOneWidget);
    });

    testWidgets("Test throw assertion error when out of bounds", (tester) async {
      expect(
        () => _buildWidget(
          min: 0,
          max: 10,
          initialValue: 11,
          onValueChanged: (newValue) {},
        ),
        throwsAssertionError,
      );
    });
  });
}
