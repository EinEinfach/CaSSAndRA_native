import 'package:cassandra_native/pages/home_page.dart';
import 'package:flutter/material.dart';

import 'package:cassandra_native/models/server.dart';

class ServerItem extends StatelessWidget {
  final Server server;
  final void Function()? onRemoveServer;
  final void Function()? openEditServer;

  const ServerItem({
    super.key,
    required this.server,
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
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(25),
      width: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: GestureDetector(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    width: double.infinity,
                    padding: const EdgeInsets.all(25),
                    child: categoryImages[server.category],
                  ),
                  onTap: () => _navigateToHomePage(server),
                ),
              ),
              const SizedBox(
                height: 25,
              ),
              Center(
                child: Column(
                  children: [
                    Text(
                      server.serverNamePrefix,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      server.id,
                      style: const TextStyle(fontSize: 8),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 25,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("server: "),
                  Text(
                    server.status,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("robot: "),
                  Text(
                    server.robot.status,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: openEditServer,
                child: Icon(Icons.edit,
                    color: Theme.of(context).colorScheme.inversePrimary),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: onRemoveServer,
                child: Icon(Icons.delete_forever,
                    color: Theme.of(context).colorScheme.inversePrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
