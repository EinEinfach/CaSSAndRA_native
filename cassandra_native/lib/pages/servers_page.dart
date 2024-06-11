import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:cassandra_native/data/ui_state.dart';
import 'package:cassandra_native/pages/mobile/servers_page_mobile.dart';
import 'package:cassandra_native/pages/tablet/servers_page_tablet.dart';
import 'package:cassandra_native/pages/desktop/servers_page_desktop.dart';
import 'package:cassandra_native/components/server_page/server_item.dart';
import 'package:cassandra_native/models/server.dart';

class ServersPage extends StatefulWidget {
  const ServersPage({super.key});

  @override
  State<ServersPage> createState() => _ServersPageDesktopState();
}

class _ServersPageDesktopState extends State<ServersPage> {

  void removeServer(BuildContext context, Server server) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: const Text('Remove this server?'),
        actions: [
          MaterialButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('cancel'),
          ),
          MaterialButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<Servers>().removeServer(server);
            },
            child: const Text('yes'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final registredServers = context.watch<Servers>().servers;
    Widget mainContent = const Center(
      child: Text('No Server found. Start with add button'),
    );
    if (registredServers.isNotEmpty) {
      mainContent = SizedBox(
        height: 500,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: registredServers.length,
          itemBuilder: (context, index) {
            final server = registredServers[index];
            return ServerItem(
              server: server,
              onTap: () => removeServer(context, server),
            );
          },
        ),
      );
    }
    return LayoutBuilder(builder: (context, constrains){
      //+++++++++++++++++++++++++++++++++++++++++++++++mobile page++++++++++++++++++++++++++++++++++++++++++++++++++++
      if (constrains.maxWidth < smallWidth) {
        return ServersPageMobile(mainContent: mainContent);
      //+++++++++++++++++++++++++++++++++++++++++++++++tablet page++++++++++++++++++++++++++++++++++++++++++++++++++++
      } else if (constrains.maxWidth < largeWidth) {
        return ServersPageTablet(mainContent: mainContent);
      //+++++++++++++++++++++++++++++++++++++++++++++++desktop page++++++++++++++++++++++++++++++++++++++++++++++++++++
      } else {
        return ServersPageDesktop(mainContent: mainContent);
      }
    });
  }
}