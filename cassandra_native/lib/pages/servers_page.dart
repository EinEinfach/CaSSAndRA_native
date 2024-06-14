import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'package:cassandra_native/data/ui_state.dart';
import 'package:cassandra_native/pages/mobile/servers_page_mobile.dart';
import 'package:cassandra_native/pages/tablet/servers_page_tablet.dart';
import 'package:cassandra_native/pages/desktop/servers_page_desktop.dart';
import 'package:cassandra_native/components/servers_page/new_server.dart';
import 'package:cassandra_native/components/servers_page/server_item.dart';
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

  void addServer(Server server) {
    setState(() {
      context.read<Servers>().addServer(server);
    });
  }

  void openAddServerOverlay() {
    showModalBottomSheet(
      //isScrollControlled: true,
      context: context,
      builder: (ctx) => NewServer(onAddServer: addServer),
    );
  }

  @override
  Widget build(BuildContext context) {
    final registredServers = context.watch<Servers>().servers;
    Widget mainContent = Center(
      child: const Text('No Server found. Start with add button')
          .animate()
          .shake(),
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
              onRemoveServer: () => removeServer(context, server),
            ).animate().fadeIn().scale();
          },
        ),
      );
    }

    mainContent = Stack(
      children: [
        Container(
          child: mainContent,
        ),
        Container(
          alignment: const Alignment(0.9, 0.9),
          child: Container(
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              onPressed: openAddServerOverlay,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Icon(
                Icons.add,
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
            ),
          ),
        ),
      ],
    );

    return LayoutBuilder(builder: (context, constrains) {
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
