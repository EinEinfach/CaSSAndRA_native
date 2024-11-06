import 'package:flutter/material.dart';

import 'package:cassandra_native/components/servers_page/info_button.dart';
import 'package:cassandra_native/components/servers_page/list_button.dart';
import 'package:cassandra_native/components/common/joystick_drawer.dart';
import 'package:cassandra_native/models/server.dart';
import 'package:cassandra_native/data/app_data.dart';

class ServersPageTablet extends StatelessWidget {
  final Widget mainContent;
  final IconData listViewIcon;
  final Server? selectedServer;
  final void Function() onListViewChange;
  final void Function() onInfoButtonPressed;

  const ServersPageTablet({
    super.key,
    required this.mainContent,
    required this.listViewIcon,
    required this.selectedServer,
    required this.onListViewChange,
    required this.onInfoButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scafoldKey,
      backgroundColor: Theme.of(context).colorScheme.surface,
      endDrawer: selectedServer != null ? JoystickDrawer(server: selectedServer!) : null,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          ListButton(
              listViewIcon: listViewIcon, onListViewChange: onListViewChange),
          InfoButton(
            onInfoButtonPressed: onInfoButtonPressed,
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: mainContent,
        ),
      ),
    );
  }
}
