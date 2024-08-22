import 'package:flutter/material.dart';

import 'package:cassandra_native/components/servers_page/info_button.dart';
import 'package:cassandra_native/components/servers_page/list_button.dart';

class ServersPageTablet extends StatelessWidget {
  final Widget mainContent;
  final IconData listViewIcon;
  final void Function() onListViewChange;
  const ServersPageTablet(
      {super.key,
      required this.mainContent,
      required this.listViewIcon,
      required this.onListViewChange});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          ListButton(listViewIcon: listViewIcon, onListViewChange: onListViewChange),
          const InfoButton(),
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
