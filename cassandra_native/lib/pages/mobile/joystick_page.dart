import 'package:flutter/material.dart';

import 'package:cassandra_native/models/server.dart';
import 'package:cassandra_native/components/common/remote_control/remote_control_content.dart';

class JoystickPage extends StatelessWidget {
  final Server server;
  const JoystickPage({
    super.key,
    required this.server,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RemoteControlContent(
        server: server,
      ),
    );
  }
}
