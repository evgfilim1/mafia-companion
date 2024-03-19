import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../game/player.dart";
import "../utils/db/adapters.dart";
import "../utils/errors.dart";
import "../utils/extensions.dart";
import "../utils/find_seed.dart";
import "../utils/game_controller.dart";
import "../utils/ui.dart";
import "../widgets/confirmation_dialog.dart";

enum _ValidationErrorType {
  tooMany,
  tooFew,
  missing,
}

class ChooseRolesScreen extends StatefulWidget {
  const ChooseRolesScreen({super.key});

  @override
  State<ChooseRolesScreen> createState() => _ChooseRolesScreenState();
}

class _ChooseRolesScreenState extends State<ChooseRolesScreen> {
  final _roles = List<Set<PlayerRole>>.generate(
    10,
    (_) => PlayerRole.values.toSet(),
    growable: false,
  );
  var _isInProgress = false;
  final _errorsByRole = <PlayerRole, _ValidationErrorType>{};
  final _errorsByIndex = <int>{};
  final _chosenNicknames = List<String?>.generate(rolesList.length, (index) => null);

  @override
  void initState() {
    super.initState();
    final controller = context.read<GameController>();
    final roles = controller.players.map((p) => p.role).toUnmodifiableList();
    for (final (i, role) in roles.indexed) {
      _roles[i] = {role};
    }
  }

  void _changeValue(int index, PlayerRole role, bool value) {
    setState(() {
      if (value) {
        _roles[index].add(role);
      } else {
        _roles[index].remove(role);
      }
      _validate();
    });
  }

  /// Validates roles. Must be called from `setState` to update errors.
  void _validate() {
    final byRole = <PlayerRole, _ValidationErrorType>{};
    final byIndex = <int>{};

    // check if no roles are selected for player
    for (var i = 0; i < 10; i++) {
      if (_roles[i].isEmpty) {
        byIndex.add(i);
      }
    }

    // check if role is not chosen at least given amount of times
    final counter = <PlayerRole, int>{
      for (final role in PlayerRole.values) role: 0,
    };

    for (final rolesChoice in _roles) {
      if (rolesChoice.length == 1) {
        counter.update(rolesChoice.single, (value) => value + 1);
      }
    }
    for (final entry in counter.entries) {
      final requiredCount = roles[entry.key]!;
      if (entry.value > requiredCount) {
        byRole[entry.key] = _ValidationErrorType.tooMany;
      }
    }
    for (final rolesChoice in _roles) {
      if (rolesChoice.length <= 1) {
        continue;
      }
      for (final role in rolesChoice) {
        counter.update(role, (value) => value + 1);
      }
    }
    for (final entry in counter.entries) {
      final minimumCount = roles[entry.key]!;
      if (entry.value < minimumCount) {
        byRole[entry.key] =
            entry.value > 0 ? _ValidationErrorType.tooFew : _ValidationErrorType.missing;
      }
    }

    _errorsByRole
      ..clear()
      ..addAll(byRole);
    _errorsByIndex
      ..clear()
      ..addAll(byIndex);
  }

  Future<void> _onFabPressed(BuildContext context) async {
    setState(_validate);
    if (_errorsByIndex.isNotEmpty || _errorsByRole.isNotEmpty) {
      showSnackBar(context, const SnackBar(content: Text("Для продолжения исправьте ошибки")));
      return;
    }
    final controller = context.read<GameController>();
    final initialSeed = controller.rolesSeed ?? getNewSeed();
    setState(() => _isInProgress = true);
    final newSeed = await compute(findSeedIsolateWrapper, (initialSeed, _roles));
    setState(() => _isInProgress = false);
    if (!context.mounted) {
      throw ContextNotMountedError();
    }
    if (newSeed == null) {
      showSnackBar(
        context,
        const SnackBar(content: Text("Невозможно применить выбранные роли")),
      );
      return;
    }
    controller
      ..rolesSeed = newSeed
      ..nicknames = _chosenNicknames;
    final showRoles = await showDialog<bool>(
      context: context,
      builder: (context) => const ConfirmationDialog(
        title: Text("Показать роли?"),
        content: Text("После применения ролей можно провести их раздачу игрокам"),
      ),
    );
    if (!context.mounted) {
      throw ContextNotMountedError();
    }
    if (showRoles ?? false) {
      await Navigator.pushNamed(context, "/roles");
      if (!context.mounted) {
        throw ContextNotMountedError();
      }
    }
    Navigator.pop(context);
  }

  void _toggleAll() {
    final anyChecked = _roles.any((rs) => rs.isNotEmpty);
    setState(() {
      for (var i = 0; i < 10; i++) {
        if (anyChecked) {
          _roles[i].clear();
        } else {
          _roles[i] = PlayerRole.values.toSet();
        }
      }
      _validate();
    });
  }

  String? _getErrorText(PlayerRole role) => switch (_errorsByRole[role]) {
        _ValidationErrorType.tooMany => "Выбрана более ${roles[role]!} раз(-а)",
        _ValidationErrorType.tooFew => "Выбрана менее ${roles[role]!} раз(-а)",
        _ValidationErrorType.missing => "Роль не выбрана",
        null => null,
      };

  @override
  Widget build(BuildContext context) {
    final players = context.watch<PlayerList>();
    final nicknameEntries = [
      const DropdownMenuEntry(
        value: null,
        label: "",
        labelWidget: Text("(*без никнейма*)"),
      ),
      for (final nickname in players.data.map((p) => p.nickname))
        DropdownMenuEntry(
          value: nickname,
          label: nickname,
          enabled: !_chosenNicknames.contains(nickname),
        ),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text("Выбор ролей"),
        actions: [
          IconButton(
            tooltip: "Сбросить",
            onPressed: _toggleAll,
            icon: const Icon(Icons.restart_alt),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          columnWidths: const {
            0: FlexColumnWidth(7),
            1: FlexColumnWidth(2),
            2: FlexColumnWidth(2),
            3: FlexColumnWidth(2),
            4: FlexColumnWidth(2),
          },
          children: [
            TableRow(
              children: [
                const Center(child: Text("Никнейм")),
                ...PlayerRole.values.map(
                  (role) {
                    final errorText = _getErrorText(role);
                    return Tooltip(
                    message: errorText ?? "",
                    child: Center(
                      child: Text(
                        role.prettyName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: errorText != null ? Colors.red : null,
                        ),
                      ),
                    ),
                  );
                  },
                ),
              ],
            ),
            for (var i = 0; i < 10; i++)
              TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: DropdownMenu(
                      expandedInsets: EdgeInsets.zero,
                      enableFilter: true,
                      enableSearch: true,
                      label: Text("Игрок ${i + 1}"),
                      menuHeight: 256,
                      inputDecorationTheme: const InputDecorationTheme(
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      errorText: _errorsByIndex.contains(i) ? "Роль не выбрана" : null,
                      requestFocusOnTap: true,
                      initialSelection: _chosenNicknames[i],
                      dropdownMenuEntries: nicknameEntries,
                      onSelected: (value) => setState(() => _chosenNicknames[i] = value),
                    ),
                  ),
                  for (final role in PlayerRole.values)
                    Checkbox(
                      value: _roles[i].contains(role),
                      onChanged: (value) => _changeValue(i, role, value!),
                      isError: _errorsByRole.containsKey(role) || _errorsByIndex.contains(i),
                    ),
                ],
              ),
          ],
        ),
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
