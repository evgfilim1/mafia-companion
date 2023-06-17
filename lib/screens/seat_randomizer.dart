import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../game_controller.dart";
import "../utils/extensions.dart";
import "../utils/ui.dart";

class SeatRandomizerScreen extends StatefulWidget {
  const SeatRandomizerScreen({super.key});

  @override
  State<SeatRandomizerScreen> createState() => _SeatRandomizerScreenState();
}

class _SeatRandomizerScreenState extends State<SeatRandomizerScreen> {
  final _seats = <int>[];

  Widget _getTextButton(int seatCount) {
    final lastSeat = _seats.lastOrNull;
    final String text;
    if (lastSeat == null) {
      text = "Начать";
    } else if (_seats.length == seatCount) {
      text = "К раздаче ролей";
    } else {
      text = "Следующее";
    }
    return TextButton(
      onPressed: () {
        final freeSeats = List.generate(seatCount, (index) => index + 1)
            .where((seat) => !_seats.contains(seat))
            .toList();
        if (freeSeats.length == 1) {
          showSnackBar(context, const SnackBar(content: Text("Все места заняты")));
        }
        if (freeSeats.isEmpty) {
          Navigator.pushReplacementNamed(context, "/roles");
          return;
        }
        setState(() => _seats.add(freeSeats.randomElement));
      },
      child: Text(text, style: const TextStyle(fontSize: 20)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lastSeat = _seats.lastOrNull;
    final seatCount = context.watch<GameController>().totalPlayersCount;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Случайная рассадка"),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (lastSeat != null)
              Text(
                "Твоё место — #$lastSeat",
                style: const TextStyle(fontSize: 48),
                textAlign: TextAlign.center,
              ),
            Text(
              "Количество свободных мест: ${seatCount - _seats.length}/$seatCount",
              style: const TextStyle(fontSize: 20),
            ),
            _getTextButton(seatCount),
          ],
        ),
      ),
    );
  }
}
