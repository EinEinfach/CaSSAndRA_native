import 'package:flutter/material.dart';

import 'package:cassandra_native/components/servers_page/info_button.dart';
import 'package:cassandra_native/components/servers_page/list_button.dart';

class ServersPageMobile extends StatelessWidget {
  final Widget mainContent;
  const ServersPageMobile({super.key, required this.mainContent});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: const [
          ListButton(),
          InfoButton(),
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
