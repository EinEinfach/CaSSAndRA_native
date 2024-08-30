import 'package:flutter/material.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';

import 'package:cassandra_native/components/joystick_drawer.dart';
import 'package:cassandra_native/components/nav_drawer.dart';
import 'package:cassandra_native/components/home_page/bottom_cmd_bar.dart';
import 'package:cassandra_native/components/home_page/map_view.dart';
import 'package:cassandra_native/models/server.dart';

class HomePageTablet extends StatelessWidget {
  final Server server;

  const HomePageTablet({super.key, required this.server});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      bottomNavigationBar: BottomCmdBar(server: server),
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
      endDrawer: JoystickDrawer(server: server),
      drawer: const NavDrawer(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(0),
          child: MapView(server: server),
        ),
      ),
    );
  }
}
