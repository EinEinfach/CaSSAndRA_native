import 'package:flutter/material.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';

import 'package:cassandra_native/components/joystick_drawer.dart';
import 'package:cassandra_native/components/nav_drawer.dart';
import 'package:cassandra_native/components/home_page/bottom_cmd_bar.dart';
import 'package:cassandra_native/components/home_page/map_view.dart';
import 'package:cassandra_native/models/server.dart';

class HomePageDesktop extends StatelessWidget {
  final Server server;

  const HomePageDesktop({super.key, required this.server});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      bottomNavigationBar: BottomCmdBar(server: server),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Builder(
            builder: (context) {
              return IconButton(
                icon: Icon(
                  BootstrapIcons.joystick,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: () {
                  Scaffold.of(context).openEndDrawer();
                },
              );
            },
          ),
        ],
      ),
      endDrawer: JoystickDrawer(server: server),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NavDrawer(
            server: server,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: MapView(server: server),
            ),
          ),
        ],
      ),
    );
  }
}
