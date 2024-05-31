import 'package:flutter/material.dart';

import 'package:cassandra_native/components/drawer_tile.dart';
import 'package:cassandra_native/data/ui_state.dart';

class NavDrawer extends StatelessWidget {
  const NavDrawer({super.key});

  @override
  Widget build(BuildContext context) {
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
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/');
                      },
                    ),
                    DrawerTile(
                      title: "Settings",
                      leading: const Icon(Icons.settings),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/settings');
                      },
                    ),
                  ],
                ),
              ),
              DrawerTile(
                  title: "Exit",
                  leading: const Icon(Icons.logout),
                  onTap: () {}),
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
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/');
                      },
                    ),
                    DrawerTile(
                      title: "Settings",
                      leading: const Icon(Icons.settings),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/settings');
                      },
                    ),
                  ],
                ),
              ),
              DrawerTile(
                title: "Exit",
                leading: const Icon(Icons.logout),
                onTap: () {},
              ),
            ],
          ),
        );
      }
    });
  }
}
