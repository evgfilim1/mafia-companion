import "dart:convert";

import "package:flutter/material.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:provider/provider.dart";

import "../../game/log.dart";
import "../extensions.dart";
import "../game_controller.dart";
import "../json/from_json.dart";
import "../json/to_json.dart";
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
  final int seed;
  final List<BaseGameLogItem> log;

  const GameInfo({
    required this.seed,
    required this.log,
  });

  Map<String, dynamic> toJson() => {
        "seed": seed,
        "log": log.map((e) => e.toJson()).toList(),
      };

  factory GameInfo.fromJson(Map<String, dynamic> json) => GameInfo(
        seed: json["seed"] as int,
        // assuming bug reports are checked in the same app version as the game was played
        log: (json["log"] as List<dynamic>).parseJsonList(
          (e) => gameLogFromJson(e, version: GameLogVersion.latest),
        ),
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
        seed: controller.rolesSeed!,
        log: controller.gameLog.toUnmodifiableList(),
      ),
    ).toJson(),
  );
}
