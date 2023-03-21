import 'package:flutter/material.dart';

import '../game/player.dart';
import '../utils.dart';

class RolesScreen extends StatefulWidget {
  final List<PlayerRole> roles;

  const RolesScreen({
    super.key,
    required this.roles,
  });

  @override
  State<RolesScreen> createState() => _RolesScreenState();
}

class _RolesScreenState extends State<RolesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Раздача ролей"),
      ),
      body: PageView.builder(
        itemCount: widget.roles.length,
        itemBuilder: (context, index) {
          final role = widget.roles[index];
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Игрок #${index + 1}", style: const TextStyle(fontSize: 48)),
                Text("Твоя роль — ${role.prettyName}", style: const TextStyle(fontSize: 20)),
              ],
            ),
          );
        },
      ),
    );
  }
}
