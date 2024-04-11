import "package:flutter/material.dart";

import "../game/player.dart";
import "../utils/extensions.dart";
import "../utils/ui.dart";
import "../widgets/player_button.dart";
import "../widgets/player_buttons.dart";

class SeatRandomizerScreen extends StatefulWidget {
  const SeatRandomizerScreen({super.key});

  @override
  State<SeatRandomizerScreen> createState() => _SeatRandomizerScreenState();
}

class _SeatRandomizerScreenState extends State<SeatRandomizerScreen> {
  final _seats = <int>{};
  int? _lastSeat;

  Widget _getTextButton(int totalSeatCount) {
    final String text;
    if (_lastSeat == null) {
      text = "Начать";
    } else if (_seats.length == totalSeatCount) {
      text = "Закрыть";
    } else {
      text = "Дальше";
    }
    return TextButton(
      onPressed: () {
        final freeSeats = List.generate(totalSeatCount, (index) => index + 1)
            .where((seat) => !_seats.contains(seat))
            .toList();
        if (freeSeats.isEmpty) {
          Navigator.pop(context);
          return;
        }
        setState(() {
          final value = freeSeats.randomElement;
          _seats.add(value);
          _lastSeat = value;
        });
      },
      child: Text(text, style: const TextStyle(fontSize: 40)),
    );
  }

  Widget _buildPlayerButton(BuildContext context, int index, {required bool expanded}) {
    final seatNumber = index + 1;
    return BasicPlayerButton(
        playerNumber: seatNumber,
        isSelected: seatNumber == _lastSeat,
        isActive: false,
        isAlive: seatNumber == _lastSeat || !_seats.contains(seatNumber),
        expanded: expanded,
        onTap: () => showSimpleDialog(
          context: context,
          title: Text("Место #$seatNumber"),
          content: Text("Место ${_seats.contains(seatNumber) ? "занято" : "свободно"}"),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final seatCount = rolesList.length;
    final children = <Widget>[
      BasicPlayerButtons(
        expanded: false,
        itemCount: rolesList.length,
        buttonBuilder: _buildPlayerButton,
      ),
      Expanded(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _lastSeat?.toString() ?? "",
                style: const TextStyle(fontSize: 48),
                textAlign: TextAlign.center,
              ),
              Text(
                _seats.length == seatCount
                    ? "Все места заняты"
                    : "Ещё свободно мест: ${seatCount - _seats.length}",
                style: const TextStyle(fontSize: 20, color: Colors.green),
                textAlign: TextAlign.center,
              ),
              _getTextButton(seatCount),
            ],
          ),
        ),
      ),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text("Случайная рассадка"),
      ),
      body: OrientationBuilder(
        builder: (context, orientation) => orientation == Orientation.portrait
            ? Column(children: children)
            : Row(children: children),
      ),
    );
  }
}
