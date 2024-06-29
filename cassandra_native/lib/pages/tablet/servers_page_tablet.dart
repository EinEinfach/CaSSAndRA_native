import 'package:flutter/material.dart';

import 'package:cassandra_native/components/info_button.dart';

class ServersPageTablet extends StatelessWidget {
  final Widget mainContent;
  const ServersPageTablet({super.key, required this.mainContent});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: const [
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