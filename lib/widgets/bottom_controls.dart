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
  final VoidCallback? onTapBack;
  final VoidCallback? onTapNext;

  const GameBottomControlBar({
    super.key,
    this.onTapBack,
    this.onTapNext,
  });

  void _onTapBack(GameController controller) {
    controller.setPreviousState();
    onTapBack?.call();
  }

  Future<void> _saveStats(
    BuildContext context,
    GameController controller,
    PlayerRepo playersContainer,
    GameStateFinish nextState,
  ) async {
    final bestTurn = controller.gameLog.whereType<StateChangeGameLogItem>().getBestTurn();
    final guessedMafiaCount = bestTurn?.playerNumbers
        .where((e) => controller.players.getByNumber(e).role.team == RoleTeam.mafia)
        .length;
    final otherTeamWin =
        controller.gameLog.whereType<PlayerKickedGameLogItem>().where((e) => e.isOtherTeamWin);
    final dbPlayers = await playersContainer
        .getManyByNicknames(controller.players.map((e) => e.nickname).toList());
    final foundMafia = <int>{};
    var foundSheriff = false;
    for (final item in controller.gameLog.whereType<PlayerCheckedGameLogItem>()) {
      if (item.checkedByRole == PlayerRole.sheriff &&
          controller.players.getByNumber(item.playerNumber).role.team == RoleTeam.mafia) {
        foundMafia.add(item.playerNumber);
      }
      if (item.checkedByRole == PlayerRole.don &&
          controller.players.getByNumber(item.playerNumber).role == PlayerRole.sheriff) {
        foundSheriff = true;
      }
    }

    final newPlayers = <String, PlayerWithStats>{};
    for (final (dbPlayer, player) in dbPlayers.zip(controller.players)) {
      if (dbPlayer == null) {
        continue;
      }
      final (key, pws) = dbPlayer;
      final newStats = pws.stats.copyWithUpdated(
        playedAs: player.role,
        won: nextState.winner == player.role.team,
        warnCount: player.state.warns,
        wasKicked: player.state.isKicked,
        hasOtherTeamWon: otherTeamWin.isNotEmpty && otherTeamWin.last.playerNumber == player.number,
        guessedMafiaCount:
            bestTurn?.currentPlayerNumber == player.number ? (guessedMafiaCount ?? 0) : 0,
        foundMafiaCount: player.role == PlayerRole.sheriff ? foundMafia.length : 0,
        foundSheriff: player.role == PlayerRole.don && foundSheriff,
        wasKilledFirstNight: bestTurn?.currentPlayerNumber == player.number,
      );
      newPlayers[key] = pws.copyWith(stats: newStats);
    }
    await playersContainer.putAllWithStats(newPlayers);
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
      final playersContainer = context.read<PlayerRepo>();
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
    onTapNext?.call();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    final previousState = controller.previousState;
    final nextStateAssumption = controller.nextStateAssumption;
    return BottomControlBar(
      backLabel: previousState?.prettyName ?? "(недоступно)",
      onTapBack: previousState != null ? () => _onTapBack(controller) : null,
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
