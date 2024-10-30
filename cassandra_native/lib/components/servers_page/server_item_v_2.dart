import 'package:flutter/material.dart';

import 'package:cassandra_native/models/server.dart';
import 'package:cassandra_native/pages/home_page.dart';
import 'package:cassandra_native/pages/stream_page.dart';

class ServerItemV2 extends StatelessWidget {
  final Server server;
  final Color serverItemColor;
  final void Function()? openEditServer;
  final void Function(Server) selectServer;

  const ServerItemV2({
    super.key,
    required this.server,
    required this.serverItemColor,
    required this.openEditServer,
    required this.selectServer,
  });

  @override
  Widget build(BuildContext context) {
    void _navigateTo(Widget page) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => page,
        ),
      );
    }

    return GestureDetector(
      onTap: () => _navigateTo(
        HomePage(server: server),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: serverItemColor,
          borderRadius: BorderRadius.circular(12),
        ),
        height: 80,
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.fromLTRB(8, 5, 5, 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: SizedBox.shrink(),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(server.alias),
                Text(
                  server.id,
                  style: const TextStyle(fontSize: 6),
                ),
              ],
            ),
            Expanded(
              child: SizedBox.shrink(),
            ),
            GestureDetector(
              onTap: openEditServer,
              child: Container(
                padding: const EdgeInsets.all(3),
                width: 70,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.computer,
                            color: Theme.of(context).colorScheme.inversePrimary,
                            size: 40,
                          ),
                          Text(
                            server.status,
                            style: const TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${server.software}: ${server.version}',
                      style: const TextStyle(fontSize: 6),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(
              width: 8,
            ),
            GestureDetector(
              onTap: () {
                selectServer(server);
                //Scaffold.of(context).openEndDrawer();
              },
              onLongPress: () {
                if (server.rtspUrl != null) {
                  _navigateTo(
                    StreamPage(server: server),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.all(3),
                width: 70,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 40,
                            child: Image.asset(
                              'lib/images/mower_icon.png',
                              color:
                                  Theme.of(context).colorScheme.inversePrimary,
                            ),
                          ),
                          Text(
                            server.robot.status,
                            style: const TextStyle(fontSize: 10),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${server.robot.firmware}: ${server.robot.version}',
                      style: const TextStyle(fontSize: 6),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
