import 'package:flutter/material.dart';

import 'package:cassandra_native/components/common/command_button_small.dart';
import 'package:cassandra_native/components/common/remote_control/remote_control_drawer.dart';
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
      endDrawer: selectedServer != null
          ? RemoteControlDrawer(server: selectedServer!)
          : null,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          CommandButtonSmall(
            icon: listViewIcon,
            onPressed: onListViewChange,
            onLongPressed: () {},
          ),
          SizedBox(
            width: 4,
          ),
          CommandButtonSmall(
            icon: Icons.info_outline,
            onPressed: onInfoButtonPressed,
            onLongPressed: () {},
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
