import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mafia_companion/widgets/player_timer.dart";

Widget _createWidget({
  Duration duration = const Duration(seconds: 1),
  ValueChanged<Duration>? onTimerTick,
}) =>
    Material(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: PlayerTimer(
          duration: duration,
          onTimerTick: onTimerTick,
        ),
      ),
    );

void main() {
  group("PlayerTimer", () {
    testWidgets("Test timer changes text and icons", (tester) async {
      final playerTimer = _createWidget();
      await tester.pumpWidget(playerTimer);

      expect(find.text("00:01"), findsOneWidget);
      expect(find.text("00:00"), findsNothing);
      expect(find.byIcon(Icons.pause), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsNothing);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text("00:01"), findsNothing);
      expect(find.text("00:00"), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsNothing);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets(
      "Test internal timer use callbacks",
      (tester) async {
        final callback = expectAsync1<void, Duration>(
          (timeLeft) {
            expect(timeLeft, lessThanOrEqualTo(const Duration(seconds: 1)));
          },
          count: 2,
          id: "onTimerTick",
        );
        final playerTimer = _createWidget(onTimerTick: callback);
        await tester.pumpWidget(playerTimer);
        await tester.pump(const Duration(seconds: 1));
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets("Test restart button", (tester) async {
      final playerTimer = _createWidget();
      await tester.pumpWidget(playerTimer);

      expect(find.text("00:01"), findsOneWidget);
      expect(find.text("00:00"), findsNothing);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text("00:01"), findsNothing);
      expect(find.text("00:00"), findsOneWidget);

      await tester.tap(find.byIcon(Icons.restart_alt));
      await tester.pump();
      expect(find.text("00:01"), findsOneWidget);
      expect(find.text("00:00"), findsNothing);

      await tester.pump(const Duration(seconds: 1)); // Rewind pending timer
    });

    testWidgets("Test play/pause button", (tester) async {
      final playerTimer = _createWidget();
      await tester.pumpWidget(playerTimer);

      expect(find.text("00:01"), findsOneWidget);
      expect(find.text("00:00"), findsNothing);
      expect(find.byIcon(Icons.pause), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsNothing);

      await tester.tap(find.byIcon(Icons.pause));
      await tester.pump();
      expect(find.text("00:01"), findsOneWidget);
      expect(find.text("00:00"), findsNothing);
      expect(find.byIcon(Icons.pause), findsNothing);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text("00:01"), findsOneWidget);
      expect(find.text("00:00"), findsNothing);
      expect(find.byIcon(Icons.pause), findsNothing);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();
      expect(find.text("00:01"), findsOneWidget);
      expect(find.text("00:00"), findsNothing);
      expect(find.byIcon(Icons.pause), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsNothing);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text("00:01"), findsNothing);
      expect(find.text("00:00"), findsOneWidget);
    });

    testWidgets("Test color changes", (tester) async {
      final playerTimer = _createWidget(duration: const Duration(seconds: 15));
      await tester.pumpWidget(playerTimer);

      expect(tester.widget<Text>(find.text("00:15")).style!.color, null);
      await tester.pump(const Duration(seconds: 5));
      expect(tester.widget<Text>(find.text("00:10")).style!.color, isSameColorAs(Colors.yellow));
      await tester.pump(const Duration(seconds: 5));
      expect(tester.widget<Text>(find.text("00:05")).style!.color, isSameColorAs(Colors.red));
      await tester.pump(const Duration(seconds: 5));
      expect(tester.widget<Text>(find.text("00:00")).style!.color, isSameColorAs(Colors.red));
    });
  });
}
