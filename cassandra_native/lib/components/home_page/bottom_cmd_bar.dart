import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

import 'package:cassandra_native/models/server.dart';

class BottomCmdBar extends StatelessWidget {
  final Server server;
  final void Function() onOpenTasksOverlay;

  const BottomCmdBar({
    super.key,
    required this.server,
    required this.onOpenTasksOverlay,
  });

  void setCmdBarState(String state) {
    server.preparedCmd = state;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: GNav(
        mainAxisAlignment: MainAxisAlignment.center,
        iconSize: 18,
        color: Colors.grey[400],
        activeColor: Colors.grey[700],
        tabActiveBorder: Border.all(color: Colors.white),
        tabBackgroundColor: Colors.grey.shade100,
        tabBorderRadius: 16,
        tabs: [
          GButton(
            icon: Icons.home_rounded,
            //backgroundColor: Theme.of(context).colorScheme.onSecondary,
            text: 'home',
            onPressed: () {
              setCmdBarState('home');
            },
            iconColor: Theme.of(context).colorScheme.primary,
          ),
          GButton(
            icon: Icons.map_outlined,
            text: 'calc',
            onPressed: () {
              setCmdBarState('calc');
            },
            iconColor: Theme.of(context).colorScheme.primary,
          ),
          GButton(
            icon: Icons.place_outlined,
            text: 'go to',
            onPressed: () {
              setCmdBarState('go to');
            },
            iconColor: Theme.of(context).colorScheme.primary,
          ),
          GButton(
            icon: Icons.list,
            text: 'tasks',
            onPressed: () {
              setCmdBarState('tasks');
              onOpenTasksOverlay();
            },
            iconColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }
}
