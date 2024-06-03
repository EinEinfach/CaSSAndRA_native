import 'package:flutter/material.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';

import 'package:cassandra_native/components/joystick_drawer.dart';
import 'package:cassandra_native/components/nav_drawer.dart';
import 'package:cassandra_native/widgets/bottom_cmd_bar.dart';
import 'package:cassandra_native/widgets/map/state_map.dart';

class HomePageTablet extends StatelessWidget {
  const HomePageTablet({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      bottomNavigationBar: const BottomCmdBar(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(builder: (context) {
          return IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          );
        }),
        actions: [
          Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(BootstrapIcons.joystick),
                onPressed: () {
                  Scaffold.of(context).openEndDrawer();
                },
              );
            },
          ),
        ],
      ),
      endDrawer: const JoystickDrawer(),
      drawer: const NavDrawer(),
      body: const StateMap(),
    );
  }
}
