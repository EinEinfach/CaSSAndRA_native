import 'package:flutter/material.dart';

import 'package:cassandra_native/models/server.dart';
import 'package:cassandra_native/pages/home_page.dart';

class ServerItemV2 extends StatelessWidget {
  final Server server;
  final Color serverItemColor;
  final void Function()? onRemoveServer;
  final void Function()? openEditServer;

  const ServerItemV2({
    super.key,
    required this.server,
    required this.serverItemColor,
    required this.onRemoveServer,
    required this.openEditServer,
  });

  @override
  Widget build(BuildContext context) {
    void _navigateToHomePage(Server server) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(server: server),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: serverItemColor,
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(5),
      padding: const EdgeInsets.all(30),
      );
  }
}