import 'package:flutter/material.dart';
import 'package:cassandra_native/components/joystick.dart';

class JoystickDrawer extends StatelessWidget {
  const JoystickDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onHorizontalDragEnd: (v) {},
        child: Drawer(
          backgroundColor:
              Theme.of(context).colorScheme.surface.withOpacity(0.5),
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
                  onJoystickMoved: (Offset position) {},
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      );
  }
}