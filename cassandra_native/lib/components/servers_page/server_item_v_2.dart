import 'package:flutter/material.dart';

import 'package:cassandra_native/models/server.dart';
import 'package:cassandra_native/pages/home_page.dart';

class ServerItemV2 extends StatelessWidget {
  final Server server;
  final Color serverItemColor;
  final void Function()? openEditServer;

  const ServerItemV2({
    super.key,
    required this.server,
    required this.serverItemColor,
    required this.openEditServer,
  });

  @override
  Widget build(BuildContext context) {
    void _navigateToHomePage(Server server) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(server: server),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _navigateToHomePage(server),
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
            const SizedBox(
              width: 8,
            ),
            GestureDetector(
              onTap: openEditServer,
              child: Container(
                width: 100,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(5),
                ),
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
            ),
            const SizedBox(
              width: 8,
            ),
            Container(
              width: 100,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 40,
                    child: Image.asset(
                      'lib/images/mower_icon.png',
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
                  ),
                  Text(
                    server.robot.status,
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
