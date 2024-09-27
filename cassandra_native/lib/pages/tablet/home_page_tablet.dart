import 'package:flutter/material.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';

import 'package:cassandra_native/components/joystick_drawer.dart';
import 'package:cassandra_native/components/nav_drawer.dart';
import 'package:cassandra_native/components/home_page/bottom_cmd_bar.dart';
import 'package:cassandra_native/components/home_page/map_view.dart';
import 'package:cassandra_native/models/server.dart';
import 'package:cassandra_native/components/nav_button.dart';

class HomePageTablet extends StatelessWidget {
  final Server server;

  const HomePageTablet({super.key, required this.server});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      bottomNavigationBar: BottomCmdBar(server: server),
      endDrawer: JoystickDrawer(server: server),
      drawer: NavDrawer(
        server: server,
      ),
      body: Builder(
        builder: (context) {
          return SafeArea(
          child: Stack(
            children: [ 
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(0),
                  child: MapView(server: server),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  NavButton(
                    icon: Icons.menu,
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                  ),
                  NavButton(
                    icon: BootstrapIcons.joystick,
                    onPressed: () {
                      Scaffold.of(context).openEndDrawer();
                    },
                  ),
                ],
              ),
            ],
          ),
        );
        }
      ),
    );
  }
}
