import 'package:cassandra_native/pages/servers_page.dart';
import 'package:cassandra_native/pages/settings_page.dart';
import 'package:flutter/material.dart';

import 'package:cassandra_native/components/drawer_tile.dart';
import 'package:cassandra_native/data/ui_state.dart';

class NavDrawer extends StatelessWidget {
  const NavDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    
    void navigateTo(Widget page) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => page,
        ),
      );
    }

    return LayoutBuilder(builder: (context, constrains) {
      if (constrains.maxWidth < largeWidth) {
        // nav drawer with close button
        return Drawer(
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
                      child: Image.asset('lib/images/artic_hare.png'),
                    ),
                    DrawerTile(
                      title: "Overview",
                      leading: const Icon(Icons.home),
                      onTap: () {
                        // Navigator.pop(context);
                        // Navigator.pushNamed(context, '/home');
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
                      onTap: () {},
                    ),
                    DrawerTile(
                      title: "Settings",
                      leading: const Icon(Icons.settings),
                      onTap: () {
                        Navigator.pop(context);
                        navigateTo(
                          const SettingsPage(),
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
                  Navigator.pop(context);
                  navigateTo(
                    const ServersPage(),
                  );
                },
              ),
            ],
          ),
        );
      } else {
        // drawer without close button
        return Drawer(
          backgroundColor: Theme.of(context).colorScheme.surface,
          child: Column(
            children: [
              Expanded(
                child: Column(
                  children: [
                    DrawerHeader(
                      child: Image.asset('lib/images/artic_hare.png'),
                    ),
                    DrawerTile(
                      title: "Overview",
                      leading: const Icon(Icons.home),
                      onTap: () {
                        //Navigator.pop(context);
                        //Navigator.pushNamed(context, '/home');
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
                      onTap: () {},
                    ),
                    DrawerTile(
                      title: "Settings",
                      leading: const Icon(Icons.settings),
                      onTap: () {
                        navigateTo(
                          const SettingsPage(),
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
        );
      }
    });
  }
}
