import 'package:flutter/material.dart';

import 'package:cassandra_native/models/server.dart';
import 'package:cassandra_native/pages/home_page.dart';
import 'package:cassandra_native/pages/servers_page.dart';
import 'package:cassandra_native/pages/settings_page.dart';
import 'package:cassandra_native/pages/mapping_page.dart';
import 'package:cassandra_native/components/common/drawer_tile.dart';
import 'package:cassandra_native/data/app_data.dart';

class NavDrawer extends StatelessWidget {
  final Server server;
  const NavDrawer({super.key, required this.server});

  @override
  Widget build(BuildContext context) {
    void navigateTo(Widget page) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => page,
        ),
      );
    }

    return LayoutBuilder(builder: (context, constrains) {
      if (constrains.maxWidth < largeWidth) {
        // nav drawer with close button
        return SafeArea(
          child: Drawer(
            backgroundColor: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                      DrawerHeader(
                        child: Stack(
                          children: [
                            Container(
                              padding: EdgeInsets.fromLTRB(20, 30, 0, 10),
                              child: Image.asset(
                                  categoryImages[server.category]!
                                      .elementAt(0)),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      server.alias,
                                      style:
                                          Theme.of(context).textTheme.bodyLarge,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${server.robot.firmware}: ${server.robot.version}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                        Text(
                                          '${server.software}: ${server.version}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                        Text(
                                          'CaSSAndRA native: $appVersion',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      DrawerTile(
                        title: "Overview",
                        leading: Icon(
                          Icons.home,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          navigateTo(
                            HomePage(server: server),
                          );
                        },
                      ),
                      DrawerTile(
                        title: "Taskplanner",
                        leading: Icon(
                          Icons.timelapse,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        onTap: () {},
                      ),
                      DrawerTile(
                        title: "Mapping",
                        leading: Icon(
                          Icons.map_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          navigateTo(
                            MappingPage(
                              server: server,
                            ),
                          );
                        },
                      ),
                      DrawerTile(
                        title: "Settings",
                        leading: Icon(
                          Icons.settings,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          navigateTo(
                            SettingsPage(
                              server: server,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                DrawerTile(
                  title: "Exit",
                  leading: Icon(
                    Icons.logout,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    navigateTo(
                      const ServersPage(),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      } else {
        // drawer without close button
        return SafeArea(
          child: Drawer(
            backgroundColor:
                Theme.of(context).colorScheme.surface.withOpacity(0),
            child: Column(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      DrawerHeader(
                        child: Image.asset('lib/images/in_app_icon.png'),
                      ),
                      DrawerTile(
                        title: "Overview",
                        leading: const Icon(Icons.home),
                        onTap: () {
                          navigateTo(
                            HomePage(server: server),
                          );
                        },
                      ),
                      DrawerTile(
                        title: "Taskplanner",
                        leading: const Icon(Icons.timelapse),
                        onTap: () {},
                      ),
                      DrawerTile(
                        title: "Mapping",
                        leading: const Icon(Icons.map_outlined),
                        onTap: () {
                          navigateTo(
                            MappingPage(
                              server: server,
                            ),
                          );
                        },
                      ),
                      DrawerTile(
                        title: "Settings",
                        leading: const Icon(Icons.settings),
                        onTap: () {
                          navigateTo(
                            SettingsPage(
                              server: server,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                DrawerTile(
                  title: "Exit",
                  leading: const Icon(Icons.logout),
                  onTap: () {
                    navigateTo(
                      const ServersPage(),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      }
    });
  }
}
