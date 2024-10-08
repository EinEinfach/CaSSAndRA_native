import 'package:flutter/material.dart';

import 'package:cassandra_native/data/app_data.dart';
import 'package:cassandra_native/components/nav_drawer.dart';
import 'package:cassandra_native/models/server.dart';

class SettingsPage extends StatelessWidget {
  final Server server;
  const SettingsPage({super.key, required this.server});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constrains) {
        //+++++++++++++++++++++++++++++++++++++++++++++++mobile page++++++++++++++++++++++++++++++++++++++++++++++++++++
        if (constrains.maxWidth < smallWidth) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
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
            ),
            drawer: NavDrawer(
              server: server,
            ),
            
          );
          //+++++++++++++++++++++++++++++++++++++++++++++++tablet page++++++++++++++++++++++++++++++++++++++++++++++++++++
        } else if (constrains.maxWidth < largeWidth) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
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
            ),
            drawer: NavDrawer(
              server: server,
            ),
          );
          //+++++++++++++++++++++++++++++++++++++++++++++++desktop page++++++++++++++++++++++++++++++++++++++++++++++++++++
        } else {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
            ),
            body: Row(
              children: [
                NavDrawer(
                  server: server,
                ),
                
              ],
            ),
          );
        }
      },
    );
  }
}
