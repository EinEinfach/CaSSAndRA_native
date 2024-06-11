import 'package:flutter/material.dart';
import 'package:cassandra_native/components/nav_drawer.dart';

class ServersPageDesktop extends StatelessWidget {
  final Widget mainContent;
  const ServersPageDesktop({super.key, required this.mainContent});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      floatingActionButton: Container(
        height: 50,
        width: 50,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: const Icon(Icons.add),
          onPressed: () {},
        ),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const NavDrawer(),
          Expanded(child: mainContent),
        ],
      ),
    );
  }
}
