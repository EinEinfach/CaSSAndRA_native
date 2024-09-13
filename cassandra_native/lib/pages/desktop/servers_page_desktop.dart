import 'package:flutter/material.dart';

import 'package:cassandra_native/components/servers_page/info_button.dart';
import 'package:cassandra_native/components/servers_page/list_button.dart';

class ServersPageDesktop extends StatelessWidget {
  final Widget mainContent;
  final IconData listViewIcon;
  final void Function() onListViewChange;
  final void Function() onInfoButtonPressed;

  const ServersPageDesktop({
    super.key,
    required this.mainContent,
    required this.listViewIcon,
    required this.onListViewChange,
    required this.onInfoButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
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
      body: Padding(
        padding: const EdgeInsets.only(top: 65),
        child: Center(child: mainContent),
      ),
    );
  }
}
