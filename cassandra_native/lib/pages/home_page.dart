import 'package:flutter/material.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';

import 'package:cassandra_native/widgets/switches/dark_mode_switch.dart';
import 'package:cassandra_native/widgets/joystick.dart';
import 'package:cassandra_native/widgets/bottom_cmd_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
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
      endDrawer: Drawer(
        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.5),
        child: Column(
          children: [
            const Spacer(),
            Center(
              child: Joystick(
                onJoystickMoved: (Offset position) {
                  print('Joystick position: $position');
                },
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
      drawer: Drawer(
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Column(
          children: [
            DrawerHeader(
              child: Image.asset('lib/images/artic_hare.png'),
            ),
            const Padding(
              padding:
                  EdgeInsets.only(bottom: 5.0, top: 5.0, left: 10.0, right: 0),
              child: ListTile(
                leading: Text(
                  'dark mode',
                  style: TextStyle(fontSize: 15),
                ),
                title: DarkModeSwitch(),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 25.0),
              child: ListTile(
                leading: Icon(
                  Icons.home,
                ),
                title: Text(
                  'Home',
                ),
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushNamed(context, '/settings');
          },
          child: const Text('settings'),
        ),
      ),
    );
  }
}
