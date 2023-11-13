import "dart:async";
import "dart:math";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../game/player.dart";
import "../utils/extensions.dart";
import "../utils/game_controller.dart";
import "../utils/ui.dart";

int? _generateSeed((int initialSeed, List<Set<PlayerRole>> requiredRoles) data) {
  final (initialSeed, requiredRoles) = data;
  var newSeed = initialSeed;
  var isOk = true;
  for (; newSeed < initialSeed + 500000; newSeed++) {
    final newRoles =
        generatePlayers(random: Random(newSeed)).map((p) => p.role).toUnmodifiableList();
    isOk = true;
    for (var i = 0; i < 10; i++) {
      if (!requiredRoles[i].contains(newRoles[i])) {
        isOk = false;
        break;
      }
    }
    if (isOk) {
      break;
    }
  }
  return isOk ? newSeed : null;
}

class _ValidationErrorInfo {
  final String message;
  final int? index;
  final PlayerRole? role;

  const _ValidationErrorInfo({
    required this.message,
    required this.index,
    required this.role,
  });
}

class ChooseRolesScreen extends StatefulWidget {
  const ChooseRolesScreen({super.key});

  @override
  State<ChooseRolesScreen> createState() => _ChooseRolesScreenState();
}

class _ChooseRolesScreenState extends State<ChooseRolesScreen> {
  final _roles = List<Set<PlayerRole>>.generate(
    10,
    (_) => {},
    growable: false,
  );
  var _isInProgress = false;
  final _errors = <_ValidationErrorInfo>[];

  @override
  void initState() {
    super.initState();
    final controller = context.read<GameController>();
    final roles = controller.players.map((p) => p.role).toUnmodifiableList();
    for (var i = 0; i < 10; i++) {
      _roles[i].add(roles[i]);
    }
  }

  void _changeValue(int index, PlayerRole role, bool value) {
    setState(() {
      if (value) {
        _roles[index].add(role);
      } else {
        _roles[index].remove(role);
      }
      _errors
        ..clear()
        ..addAll(_rolesValidator());
    });
  }

  List<_ValidationErrorInfo> _rolesValidator() {
    final errors = <_ValidationErrorInfo>[];

    // check if no roles are selected for player
    for (var i = 0; i < 10; i++) {
      if (_roles[i].isEmpty) {
        errors.add(
          _ValidationErrorInfo(
            message: "Игрок ${i + 1} не может быть без роли",
            index: i,
            role: null,
          ),
        );
      }
    }

    const requiredRoles = <PlayerRole, int>{
      PlayerRole.mafia: 2,
      PlayerRole.don: 1,
      PlayerRole.sheriff: 1,
      PlayerRole.citizen: 6,
    };
    // check if role is not chosen at least given amount of times
    final counter = <PlayerRole, int>{
      for (final role in PlayerRole.values) role: 0,
    };
    for (var i = 0; i < 10; i++) {
      for (final role in _roles[i]) {
        counter.update(role, (value) => value + 1);
      }
    }
    for (final role in PlayerRole.values) {
      if (counter[role]! < requiredRoles[role]!) {
        errors.add(
          _ValidationErrorInfo(
            message: 'Роль "${role.prettyName}" должна быть выбрана как минимум'
                " ${requiredRoles[role]} раз",
            index: null,
            role: role,
          ),
        );
      }
    }

    // check if single role is not chosen more than given amount of times
    counter.updateAll((key, value) => 0);
    for (var i = 0; i < 10; i++) {
      if (_roles[i].length != 1) {
        continue;
      }
      counter.update(_roles[i].single, (value) => value + 1);
    }
    for (final role in PlayerRole.values) {
      if (counter[role]! > requiredRoles[role]!) {
        errors.add(
          _ValidationErrorInfo(
            message: 'Роль "${role.prettyName}" не может быть выбрана больше'
                " ${requiredRoles[role]} раз",
            index: null,
            role: role,
          ),
        );
      }
    }

    return errors;
  }

  Future<void> _onFabPressed(BuildContext context) async {
    final errors = _rolesValidator();
    setState(() {
      _errors
        ..clear()
        ..addAll(errors);
    });
    if (errors.isNotEmpty) {
      return;
    }
    final controller = context.read<GameController>();
    final initialSeed = controller.playerRandomSeed;
    setState(() {
      _isInProgress = true;
    });
    final newSeed = await compute(_generateSeed, (initialSeed, _roles));
    setState(() {
      _isInProgress = false;
    });
    if (newSeed == null) {
      if (context.mounted) {
        showSnackBar(
          context,
          const SnackBar(content: Text("Невозможно применить выбранные роли")),
        );
      }
      return;
    }
    controller.restart(seed: newSeed);
    if (!context.mounted) {
      throw StateError("context is not mounted");
    }
    showSnackBar(context, const SnackBar(content: Text("Роли применены")));
    unawaited(Navigator.pushReplacementNamed(context, "/roles"));
  }

  void _reset(bool checked) {
    setState(() {
      for (var i = 0; i < 10; i++) {
        if (checked) {
          _roles[i] = Set.of(PlayerRole.values);
        } else {
          _roles[i].clear();
        }
      }
      _errors
        ..clear()
        ..addAll(_rolesValidator());
    });
  }

  @override
  Widget build(BuildContext context) {
    final errorsByRole = <PlayerRole, List<_ValidationErrorInfo>>{
      for (final role in PlayerRole.values) role: _errors.where((e) => e.role == role).toList(),
    };
    final errorsByIndex = <int, List<_ValidationErrorInfo>>{
      for (var i = 0; i < 10; i++) i: _errors.where((e) => e.index == i).toList(),
    };
    return Scaffold(
      appBar: AppBar(
        title: const Text("Выбор ролей"),
        actions: [
          IconButton(
            tooltip: "Сбросить",
            onPressed: () => _reset(true),
            icon: const Icon(Icons.restart_alt),
          ),
        ],
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(
                children: [
                  const SizedBox.shrink(),
                  for (final role in PlayerRole.values)
                    Text(
                      role.prettyName,
                      textAlign: TextAlign.center,
                      style: errorsByRole[role]!.isNotEmpty
                          ? const TextStyle(color: Colors.red)
                          : null,
                    ),
                ],
              ),
              for (var i = 0; i < 10; i++)
                TableRow(
                  children: [
                    Text(
                      "Игрок ${i + 1}",
                      textAlign: TextAlign.center,
                      style:
                          errorsByIndex[i]!.isNotEmpty ? const TextStyle(color: Colors.red) : null,
                    ),
                    for (final role in PlayerRole.values)
                      Checkbox(
                        value: _roles[i].contains(role),
                        onChanged: (value) => _changeValue(i, role, value!),
                        isError: _errors
                            .any((e) => e.role.isAnyOf([role, null]) && e.index.isAnyOf([i, null])),
                      ),
                  ],
                ),
            ],
          ),
          Flexible(
            child: ListView(
              children: _errors
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        e.message,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: "Применить",
        onPressed: () => _onFabPressed(context),
        child: _isInProgress
            ? const SizedBox.square(dimension: 24, child: CircularProgressIndicator())
            : const Icon(Icons.check),
      ),
    );
  }
}
