import 'package:cassandra_native/components/info_button.dart';
import 'package:flutter/material.dart';

class ServersPageDesktop extends StatelessWidget {
  final Widget mainContent;
  const ServersPageDesktop({super.key, required this.mainContent});

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
      body: Padding(
        padding: const EdgeInsets.only(top: 65),
        child: Center(child: mainContent),
      ),
    );
  }
}
