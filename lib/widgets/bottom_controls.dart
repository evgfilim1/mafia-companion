import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../game/log.dart";
import "../game/player.dart";
import "../game/states.dart";
import "../utils/db/models.dart";
import "../utils/db/repo.dart";
import "../utils/extensions.dart";
import "../utils/game_controller.dart";
import "../utils/state_change_utils.dart";
import "../utils/ui.dart";
import "confirmation_dialog.dart";

class GameBottomControlBar extends StatelessWidget {
  const GameBottomControlBar({super.key});

  Future<void> _saveStats(
    BuildContext context,
    GameController controller,
    PlayerList playersContainer,
    GameStateFinish nextState,
  ) async {
    final bestTurn = controller.gameLog
        .whereType<StateChangeGameLogItem>()
        .getBestTurn();
    final guessedMafiaCount = bestTurn?.playerNumbers
        .where((e) => nextState.players[e - 1].role.team == RoleTeam.mafia)
        .length;
    final otherTeamWin =
        controller.gameLog.whereType<PlayerKickedGameLogItem>().where((e) => e.isOtherTeamWin);
    final dbPlayers = await playersContainer
        .getManyByNicknames(nextState.players.map((e) => e.nickname).toList());
    final foundMafia = <int>{};
    var foundSheriff = false;
    for (final item in controller.gameLog.whereType<PlayerCheckedGameLogItem>()) {
      if (item.checkedByRole == PlayerRole.sheriff &&
          nextState.players[item.playerNumber - 1].role.team == RoleTeam.mafia) {
        foundMafia.add(item.playerNumber);
      }
      if (item.checkedByRole == PlayerRole.don &&
          nextState.players[item.playerNumber - 1].role == PlayerRole.sheriff) {
        foundSheriff = true;
      }
    }

    final newStats = <PlayerStats>[];
    for (final (dbPlayer, player) in dbPlayers.zip(nextState.players)) {
      if (dbPlayer == null) {
        continue;
      }
      newStats.add(
        dbPlayer.$2.stats.copyWithUpdated(
          playedAs: player.role,
          won: nextState.winner == player.role.team,
          warnCount: player.warns,
          wasKicked: player.isKicked,
          hasOtherTeamWon:
              otherTeamWin.isNotEmpty && otherTeamWin.last.playerNumber == player.number,
          guessedMafiaCount:
              bestTurn?.currentPlayerNumber == player.number ? (guessedMafiaCount ?? 0) : 0,
          foundMafiaCount: player.role == PlayerRole.sheriff ? foundMafia.length : 0,
          foundSheriff: player.role == PlayerRole.don && foundSheriff,
          wasKilledFirstNight: bestTurn?.currentPlayerNumber == player.number,
        ),
      );
    }
    await playersContainer.editAll(
      Map.fromEntries(
        dbPlayers.nonNulls
            .zip(newStats)
            .map((e) => MapEntry(e.$1.$1, e.$1.$2.copyWith(stats: e.$2))),
      ),
    );
    if (!context.mounted) {
      return;
    }
    showSnackBar(context, const SnackBar(content: Text("Результаты игры сохранены")));
  }

  Future<void> _onTapNext(BuildContext context, GameController controller) async {
    final nextStateAssumption = controller.nextStateAssumption;
    if (nextStateAssumption == null) {
      return;
    }
    controller.setNextState();
    if (nextStateAssumption is GameStateFinish) {
      final playersContainer = context.read<PlayerList>();
      final saveStats = await showDialog<bool>(
        context: context,
        builder: (context) => const ConfirmationDialog(
          title: Text("Сохранить результаты игры?"),
          content: Text(
            "Результат этой игры будет учтён у каждого зарегистрированного игрока в статистике.",
          ),
        ),
      );
      if (!(saveStats ?? false) || !context.mounted) {
        return;
      }
      await _saveStats(context, controller, playersContainer, nextStateAssumption);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    final previousState = controller.previousState;
    final nextStateAssumption = controller.nextStateAssumption;
    return BottomControlBar(
      backLabel: previousState?.prettyName ?? "(недоступно)",
      onTapBack: previousState != null ? controller.setPreviousState : null,
      onTapNext: nextStateAssumption != null ? () => _onTapNext(context, controller) : null,
      nextLabel: nextStateAssumption?.prettyName ?? "(недоступно)",
    );
  }
}

class BottomControlBar extends StatelessWidget {
  final VoidCallback? onTapBack;
  final String backLabel;
  final VoidCallback? onTapNext;
  final String nextLabel;

  const BottomControlBar({
    super.key,
    this.onTapBack,
    this.backLabel = "Назад",
    this.onTapNext,
    this.nextLabel = "Далее",
  });

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: _GameControlButton(
                onTap: onTapBack,
                icon: Icons.arrow_back,
                label: backLabel,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: _GameControlButton(
                onTap: onTapNext,
                icon: Icons.arrow_forward,
                label: nextLabel,
              ),
            ),
          ),
        ],
      );
}

class _GameControlButton extends StatelessWidget {
  final VoidCallback? onTap;
  final IconData icon;
  final String label;

  const _GameControlButton({
    this.onTap,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final color = onTap == null ? Theme.of(context).disabledColor : null;
    return ElevatedButton(
      onPressed: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Icon(icon, color: color),
            Text(
              label,
              style: TextStyle(color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
