import "package:flutter/material.dart";

import "../game/player.dart";
import "../utils/extensions.dart";
import "../utils/ui.dart";
import "../widgets/orientation_dependent.dart";
import "../widgets/player_button.dart";

class SeatRandomizerScreen extends StatefulWidget {
  const SeatRandomizerScreen({super.key});

  @override
  State<SeatRandomizerScreen> createState() => _SeatRandomizerScreenState();
}

class _SeatRandomizerScreenState extends OrientationDependentState<SeatRandomizerScreen> {
  final _seats = <int>{};
  int? _lastSeat;

  Widget _getTextButton(int seatCount) {
    final String text;
    if (_lastSeat == null) {
      text = "Начать";
    } else if (_seats.length == seatCount) {
      text = "Закрыть";
    } else {
      text = "Дальше";
    }
    return TextButton(
      onPressed: () {
        final freeSeats = List.generate(seatCount, (index) => index + 1)
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

  Widget _buildPlayerButton(BuildContext context, int playerNumber) => BasicPlayerButton(
        playerNumber: playerNumber,
        isSelected: playerNumber == _lastSeat,
        isActive: false,
        isAlive: playerNumber == _lastSeat || !_seats.contains(playerNumber),
        onTap: () => showSimpleDialog(
          context: context,
          title: Text("Место #$playerNumber"),
          content: Text("Место ${_seats.contains(playerNumber) ? "занято" : "свободно"}"),
        ),
      );

  Widget _buildButtonsPortrait(BuildContext context) {
    final totalPlayers = rolesList.length;
    final itemsPerRow = totalPlayers ~/ 2;
    final size = (MediaQuery.of(context).size.width / itemsPerRow).floorToDouble();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < totalPlayers; i += itemsPerRow)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var j = i; j < i + itemsPerRow && j < totalPlayers; j++)
                SizedBox(
                  width: size,
                  height: size,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: _buildPlayerButton(context, j + 1),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildButtonsLandscape(BuildContext context) {
    final totalPlayers = rolesList.length;
    final itemsPerRow = totalPlayers ~/ 2;
    final size = (MediaQuery.of(context).size.height / itemsPerRow).floorToDouble() - 18;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < totalPlayers; i += itemsPerRow)
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var j = i; j < i + itemsPerRow && j < totalPlayers; j++)
                SizedBox(
                  width: size + 24,
                  height: size,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: _buildPlayerButton(
                      context,
                      (i.isEven ? i + itemsPerRow + i - j - 1 : j) + 1,
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  @override
  Widget buildPortrait(BuildContext context) {
    final seatCount = rolesList.length;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Случайная рассадка"),
      ),
      body: Column(
        children: [
          _buildButtonsPortrait(context),
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
        ],
      ),
    );
  }

  @override
  Widget buildLandscape(BuildContext context) {
    final seatCount = rolesList.length;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Случайная рассадка"),
      ),
      body: Row(
        children: [
          _buildButtonsLandscape(context),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_lastSeat != null)
                    Text(
                      "Твоё место — #$_lastSeat",
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
          ),
        ],
      ),
    );
  }
}
