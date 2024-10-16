import 'package:flutter/material.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';

import 'package:cassandra_native/components/joystick_drawer.dart';
import 'package:cassandra_native/components/nav_drawer.dart';
import 'package:cassandra_native/components/home_page/map_view.dart';
import 'package:cassandra_native/models/server.dart';
import 'package:cassandra_native/components/nav_button.dart';

class HomePageMobile extends StatelessWidget {
  final Server server;
  final void Function() onOpenTasksOverlay;
  final void Function() openMowParametersOverlay;
  final Widget statusWindow;
  final Widget playButton;
  final Widget homeButton;

  const HomePageMobile({
    super.key,
    required this.server,
    required this.onOpenTasksOverlay,
    required this.openMowParametersOverlay,
    required this.statusWindow,
    required this.playButton,
    required this.homeButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      endDrawer: JoystickDrawer(server: server),
      drawer: NavDrawer(
        server: server,
      ),
      body: Builder(builder: (context) {
        return SafeArea(
          child: Stack(
            children: [
              MapView(
                server: server,
                openMowParametersOverlay: openMowParametersOverlay,
                onOpenTasksOverlay: onOpenTasksOverlay,
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      statusWindow,
                      const Expanded(
                        child: SizedBox(
                          width: 10,
                        ),
                      ),
                      homeButton,
                      const SizedBox(
                        width: 10,
                      ),
                      playButton,
                    ],
                  ),
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
      }),
    );
  }
}
