import 'package:flutter/material.dart';

import 'package:cassandra_native/components/common/remote_control/remote_control_content.dart';
import 'package:cassandra_native/models/server.dart';

class RemoteControlDrawer extends StatelessWidget {
  final Server server;
  const RemoteControlDrawer({
    super.key,
    required this.server,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (v) {},
      child: SafeArea(
        child: Drawer(
          backgroundColor: Theme.of(context).colorScheme.surface,
          child: RemoteControlContent(
            server: server,
          ),
        ),
      ),
    );
  }
}
