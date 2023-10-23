import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mafia_companion/game/player.dart";
import "package:mafia_companion/widgets/player_button.dart";

Widget _buildWidget({
  required int number,
  required PlayerRole role,
  required bool isAlive,
  required bool isSelected,
  bool isActive = false,
  required int warnCount,
  VoidCallback? onTap,
  List<Widget> longPressActions = const [],
  bool showRole = false,
}) =>
    MaterialApp(
      home: Center(
        child: PlayerButton(
          player: Player(
            number: number,
            role: role,
            isAlive: isAlive,
          ),
          isSelected: isSelected,
          isActive: isActive,
          warnCount: warnCount,
          onTap: onTap,
          longPressActions: longPressActions,
          showRole: showRole,
        ),
      ),
    );

void main() {
  group("PlayerButton", () {
    testWidgets("Test UI consistency", (tester) async {
      final button = _buildWidget(
        number: 1,
        role: PlayerRole.citizen,
        isAlive: true,
        isSelected: false,
        warnCount: 2,
      );
      await tester.pumpWidget(button);

      expect(find.text("1"), findsOneWidget);
      expect(find.text("!!"), findsOneWidget);
    });

    testWidgets(
      "Test onTap callback called",
      (tester) async {
        final button = _buildWidget(
          number: 1,
          role: PlayerRole.citizen,
          isAlive: true,
          isSelected: false,
          warnCount: 0,
          onTap: expectAsync0(() {}, count: 1),
        );
        await tester.pumpWidget(button);

        await tester.tap(find.text("1"));
        await tester.pump();
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets("Test long press menu", (tester) async {
      final button = _buildWidget(
        number: 1,
        role: PlayerRole.citizen,
        isAlive: true,
        isSelected: false,
        warnCount: 0,
      );
      await tester.pumpWidget(button);

      await tester.longPress(find.text("1"));
      await tester.pump();
      expect(find.text("Игрок 1"), findsOneWidget);
      expect(find.textContaining("Состояние: Жив"), findsOneWidget);
      expect(find.textContaining("Роль: Мирный житель"), findsOneWidget);
      expect(find.textContaining("Фолов: 0"), findsOneWidget);
    });
  });
}
