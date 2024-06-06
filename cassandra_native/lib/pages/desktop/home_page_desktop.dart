import 'package:flutter/material.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';

import 'package:cassandra_native/components/joystick_drawer.dart';
import 'package:cassandra_native/components/nav_drawer.dart';
import 'package:cassandra_native/widgets/bottom_cmd_bar.dart';
import 'package:cassandra_native/components/landscape/map_view.dart';

class HomePageDesktop extends StatelessWidget {
  const HomePageDesktop({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(          
      backgroundColor: Theme.of(context).colorScheme.surface,
      bottomNavigationBar: const BottomCmdBar(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
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
      endDrawer: const JoystickDrawer(),
      body: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NavDrawer(),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(10),
              child: MapView(),
            ), 
          ),
        ],
      ),
    );
  }
}