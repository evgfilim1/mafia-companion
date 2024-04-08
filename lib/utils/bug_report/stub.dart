import "dart:convert";

import "package:flutter/material.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:provider/provider.dart";

import "../../game/player.dart";
import "../extensions.dart";
import "../game_controller.dart";
import "../versioned/game_log.dart";

Future<void> reportBug(BuildContext context) async {
  throw UnimplementedError("stub");
}

class BugReportInfo {
  final Map<String, dynamic> packageInfo;
  final GameInfo game;

  const BugReportInfo({
    required this.packageInfo,
    required this.game,
  });

  Map<String, dynamic> toJson() => {
        "packageInfo": packageInfo,
        "game": game.toJson(),
      };

  factory BugReportInfo.fromJson(Map<String, dynamic> json) => BugReportInfo(
        packageInfo: json["packageInfo"] as Map<String, dynamic>,
        game: GameInfo.fromJson(json["game"] as Map<String, dynamic>),
      );
}

class GameInfo {
  final GameLogWithPlayers log;

  const GameInfo({
    required this.log,
  });

  Map<String, dynamic> toJson() => GameLogWithPlayers(
        log: log.log,
        players: log.players.map(
          (e) => Player(
            role: e.role,
            number: e.number,
            nickname: null, // redacted for privacy, not needed for bug reports
          ),
        ),
      ).toJson();

  factory GameInfo.fromJson(Map<String, dynamic> json) => GameInfo(
        // assuming bug reports are checked in the same app version as the game was played
        log: GameLogWithPlayers.fromJson(json, version: GameLogVersion.latest),
      );
}

Future<String> reportBugCommonImpl(BuildContext context) async {
  final controller = context.read<GameController>();
  final packageInfo = context.read<PackageInfo>();

  if (!controller.isGameInitialized) {
    throw StateError("Game is not initialized");
  }

  return jsonEncode(
    BugReportInfo(
      packageInfo: packageInfo.data,
      game: GameInfo(
        log: GameLogWithPlayers(
          log: controller.gameLog.toUnmodifiableList(),
          players: controller.players,
        ),
      ),
    ).toJson(),
  );
}
