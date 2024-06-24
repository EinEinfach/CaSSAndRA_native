import 'package:flutter/material.dart';

import 'package:cassandra_native/components/joystick/joystick.dart';
import 'package:cassandra_native/models/server.dart';
import 'package:cassandra_native/comm/mqtt_manager.dart';

class JoystickDrawer extends StatelessWidget {
  final Server server;

  const JoystickDrawer({
    super.key,
    required this.server,
  });

  void _onJoystickMove(Offset position, double maxSpeed, double radius) {
    String linearSpeed =
        (-1 * maxSpeed * position.dy / radius).toStringAsFixed(2);
    String angularSpeed =
        (-1 * maxSpeed * position.dx / radius).toStringAsFixed(2);
    MqttManager.instance.publish(
        server.id,
        '${server.serverNamePrefix}/api_cmd',
        '{"robot":{"command": "move", "value": [$linearSpeed, $angularSpeed]}}');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (v) {},
      child: Drawer(
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: Column(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
            const Spacer(),
            Center(
              child: Joystick(
                server: server,
                onJoystickMoved: _onJoystickMove,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
