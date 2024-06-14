import 'package:flutter/material.dart';
import 'package:cassandra_native/components/nav_drawer.dart';

class ServersPageDesktop extends StatelessWidget {
  final Widget mainContent;
  const ServersPageDesktop({super.key, required this.mainContent});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Padding(
        padding: const EdgeInsets.only(top: 65),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const NavDrawer(),
            Expanded(
              child: Center(child: mainContent),
            ),
          ],
        ),
      ),
    );
  }
}
