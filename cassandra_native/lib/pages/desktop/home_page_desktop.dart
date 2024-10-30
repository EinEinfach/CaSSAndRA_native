import 'package:cassandra_native/components/nav_button.dart';
import 'package:flutter/material.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';

import 'package:cassandra_native/components/joystick_drawer.dart';
import 'package:cassandra_native/components/nav_drawer.dart';
import 'package:cassandra_native/components/home_page/map_view.dart';
import 'package:cassandra_native/models/server.dart';

class HomePageDesktop extends StatelessWidget {
  final Server server;
  final void Function() onOpenTasksOverlay;
  final void Function() openMowParametersOverlay;
  final Widget statusWindow;
  final Widget playButton;
  final Widget homeButton;

  const HomePageDesktop({
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
      body: Builder(builder: (context) {
        return Stack(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                NavButton(
                    icon: BootstrapIcons.joystick,
                    onPressed: () {
                      Scaffold.of(context).openEndDrawer();
                    }),
              ],
            ),
            Row(
              //crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NavDrawer(
                  server: server,
                ),
                Expanded(
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
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  statusWindow,
                                  const Expanded(
                                    child: SizedBox(),
                                  ),
                                  homeButton,
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  playButton,
                                ],
                              ),
                              const SizedBox(
                                height: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }
}
