import 'package:cassandra_native/components/nav_drawer.dart';
import 'package:flutter/material.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';

import 'package:cassandra_native/widgets/joystick.dart';
import 'package:cassandra_native/widgets/bottom_cmd_bar.dart';
import 'package:cassandra_native/widgets/map/state_map.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
      endDrawer: GestureDetector(
        onHorizontalDragEnd: (v) {},
        child: Drawer(
          backgroundColor:
              Theme.of(context).colorScheme.primary.withOpacity(0.5),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
              const Spacer(),
              Center(
                child: Joystick(
                  onJoystickMoved: (Offset position) {},
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
      drawer: const NavDrawer(),
      body: const StateMap(),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.zoom_in_map),
        onPressed: () {},
      ),
    );
  }
}
