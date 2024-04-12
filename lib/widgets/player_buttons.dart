import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../game/player.dart";
import "../game/states.dart";
import "../utils/extensions.dart";
import "../utils/game_controller.dart";
import "../utils/ui.dart";
import "player_button.dart";

typedef PlayerButtonBuilder = Widget Function(
  BuildContext context,
  int index, {
  required bool expanded,
});

@immutable
final class ExtraWidgetsBuilderParams {
  final Orientation orientation;
  final bool expanded;

  const ExtraWidgetsBuilderParams({
    required this.orientation,
    required this.expanded,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExtraWidgetsBuilderParams &&
          runtimeType == other.runtimeType &&
          orientation == other.orientation &&
          expanded == other.expanded;

  @override
  int get hashCode => Object.hash(orientation, expanded);
}

typedef ExtraWidgetsBuilder = Iterable<Widget> Function(
  BuildContext context,
  ExtraWidgetsBuilderParams params,
);

class BasicPlayerButtons extends StatelessWidget {
  final bool expanded;
  final int itemCount;
  final PlayerButtonBuilder buttonBuilder;
  final ExtraWidgetsBuilder? extraWidgetsBuilder;

  const BasicPlayerButtons({
    super.key,
    required this.expanded,
    required this.itemCount,
    required this.buttonBuilder,
    this.extraWidgetsBuilder,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final orientation = constraints.maxWidth > constraints.maxHeight
              ? Orientation.landscape
              : Orientation.portrait;
          final smallestSide = switch (orientation) {
            Orientation.portrait => constraints.maxWidth,
            Orientation.landscape => constraints.maxHeight,
          };
          final expanded = orientation == Orientation.landscape || this.expanded;
          final itemsPerRow = expanded ? 2 : 5;
          final width = (smallestSide / itemsPerRow).floorToDouble();
          final height = (smallestSide / 5).floorToDouble();
          final buttons = List<Widget>.generate(
            itemCount,
            (i) => SizedBox(
              width: width,
              height: height,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: buttonBuilder(context, i, expanded: expanded),
              ),
            ),
          );
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < itemCount; i += itemsPerRow)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: buttons.getRange(i, i + itemsPerRow).toList(),
                ),
              if (extraWidgetsBuilder != null)
                ...extraWidgetsBuilder!(
                  context,
                  ExtraWidgetsBuilderParams(
                    orientation: orientation,
                    expanded: expanded,
                  ),
                ),
            ],
          );
        },
      );
}

class PlayerButtons extends StatefulWidget {
  final bool showRoles;
  final bool warnOnTap;

  const PlayerButtons({
    super.key,
    required this.showRoles,
    required this.warnOnTap,
  });

  @override
  State<PlayerButtons> createState() => _PlayerButtonsState();
}

class _PlayerButtonsState extends State<PlayerButtons> {
  bool _expanded = false;

  void _onPlayerButtonTap(BuildContext context, int playerNumber) {
    final controller = context.read<GameController>();
    final player = controller.players.getByNumber(playerNumber);
    if (widget.warnOnTap && controller.isGameActive && player.state.isAlive) {
      controller.warnPlayer(playerNumber);
      showSnackBar(
        context,
        SnackBar(
          content: Text("Игрок ${player.number} получил фол"),
          action: SnackBarAction(
            label: "Отменить",
            onPressed: () => controller.warnMinusPlayer(playerNumber),
          ),
        ),
      );
      return;
    }
    if (controller.state case GameStateNightCheck(activePlayerNumber: final pn)) {
      final p = controller.players.getByNumber(pn);
      if (!p.state.isAlive) {
        return; // It's useless to allow dead players check others
      }
      final result = controller.checkPlayer(playerNumber);
      final String msg;
      if (p.role == PlayerRole.don) {
        msg = result ? "ШЕРИФ" : "НЕ шериф";
      } else if (p.role == PlayerRole.sheriff) {
        msg = result ? "МАФИЯ 👎" : "НЕ мафия 👍";
      } else {
        throw AssertionError();
      }
      showSimpleDialog(
        context: context,
        title: const Text("Результат проверки"),
        content: Text("Игрок ${player.number} — $msg"),
      );
    } else if (!player.state.isAlive ||
        !controller.state.stage
            .isAnyOf(const [GameStage.nightKill, GameStage.bestTurn, GameStage.speaking])) {
      return;
    } else {
      controller.togglePlayerSelected(player.number);
    }
  }

  Widget _buildPlayerButton(BuildContext context, int index, {required bool expanded}) {
    final controller = context.watch<GameController>();
    final playerNumber = index + 1;
    final isActive = switch (controller.state) {
      GameStatePrepare() || GameStateNightRest() => false,
      GameStateWithPlayer(currentPlayerNumber: final p) ||
      GameStateSpeaking(currentPlayerNumber: final p) ||
      GameStateWithIterablePlayers(currentPlayerNumber: final p) ||
      GameStateVoting(currentPlayerNumber: final p) ||
      GameStateNightCheck(activePlayerNumber: final p) ||
      GameStateBestTurn(currentPlayerNumber: final p) =>
        p == playerNumber,
      GameStateWithPlayers(playerNumbers: final ps) ||
      GameStateKnockoutVoting(playerNumbers: final ps) =>
        ps.contains(playerNumber),
      GameStateNightKill() =>
        controller.players.getByNumber(playerNumber).role.team == RoleTeam.mafia,
      GameStateFinish(:final winner) =>
        controller.players.getByNumber(playerNumber).role.team == winner,
    };
    final isSelected = switch (controller.state) {
      GameStateSpeaking(accusations: final accusations) => accusations.containsValue(playerNumber),
      GameStateBestTurn(playerNumbers: final playerNumbers) => playerNumbers.contains(playerNumber),
      GameStateNightKill(thisNightKilledPlayerNumber: final thisNightKilledPlayer) =>
        thisNightKilledPlayer == playerNumber,
      _ => false,
    };
    final player = controller.players.getByNumber(playerNumber);
    return PlayerButton(
      playerNumber: player.number,
      isSelected: isSelected,
      isActive: isActive,
      onTap: player.state.isAlive || controller.state.stage == GameStage.nightCheck
          ? () => _onPlayerButtonTap(context, playerNumber)
          : null,
      showRole: widget.showRoles,
      expanded: expanded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    if (!controller.isGameInitialized) {
      return const SizedBox.shrink();
    }
    return BasicPlayerButtons(
      expanded: _expanded,
      itemCount: controller.players.length,
      buttonBuilder: _buildPlayerButton,
      extraWidgetsBuilder: (context, params) sync* {
        if (params.orientation == Orientation.portrait) {
          yield TextButton.icon(
            onPressed: () => setState(() => _expanded = !_expanded),
            icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
            label: Text(_expanded ? "Свернуть" : "Развернуть"),
          );
        }
      },
    );
  }
}
