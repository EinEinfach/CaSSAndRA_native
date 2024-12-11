import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';

import 'package:cassandra_native/components/common/customized_dialog_ok_cancel.dart';
import 'package:cassandra_native/components/joystick/joystick.dart';
import 'package:cassandra_native/components/common/customized_elevated_icon_button.dart';
import 'package:cassandra_native/models/server.dart';

class JoystickDrawer extends StatefulWidget {
  final Server server;
  const JoystickDrawer({
    super.key,
    required this.server,
  });

  @override
  State<JoystickDrawer> createState() => _JoystickDrawerState();
}

class _JoystickDrawerState extends State<JoystickDrawer> {
  void _onJoystickMove(Offset position, double maxSpeed, double radius) {
    String linearSpeed =
        (-1 * maxSpeed * position.dy / radius).toStringAsFixed(2);
    String angularSpeed =
        (-1 * maxSpeed * position.dx / radius).toStringAsFixed(2);
    widget.server.serverInterface
        .commandMove(double.parse(linearSpeed), double.parse(angularSpeed));
  }

  void _onShutdownPressed() {
    showDialog(
      context: context,
      builder: (context) => CustomizedDialogOkCancel(
        title: 'Warning',
        content: 'You are about to shut down the robot.\n\nIf CaSSAndRA is running on the same machine or in UART mode, the server will also be shut down. Do you want to proceed?',
        onCancelPressed: () {
          Navigator.pop(context);
        },
        onOkPressed: () {
          widget.server.serverInterface.commandShutdown();
          Navigator.pop(context);
        },
      ),
    );
  }

  void _onRebootPressed() {
    showDialog(
      context: context,
      builder: (context) => CustomizedDialogOkCancel(
        title: 'Warning',
        content: 'You are about to reboot the robot.\n\nIf CaSSAndRA is running on the same machine, the server will also be restarted. Do you want to proceed?',
        onCancelPressed: () {
          Navigator.pop(context);
        },
        onOkPressed: () {
          widget.server.serverInterface.commandReboot();
          Navigator.pop(context);
        },
      ),
    );
  }

  void _onRebootGpsPressed() {
    showDialog(
      context: context,
      builder: (context) => CustomizedDialogOkCancel(
        title: 'Info',
        content: 'Reboot GPS receiver?',
        onCancelPressed: () {
          Navigator.pop(context);
        },
        onOkPressed: () {
          widget.server.serverInterface.commandRebootGps();
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (v) {},
      child: SafeArea(
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
                  server: widget.server,
                  onJoystickMoved: _onJoystickMove,
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  CustomizedElevatedIconButton(
                    icon: BootstrapIcons.power,
                    isActive: false,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _onShutdownPressed();
                    },
                  ),
                  CustomizedElevatedIconButton(
                    icon: BootstrapIcons.bootstrap_reboot,
                    isActive: false,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _onRebootPressed();
                    },
                  ),
                  CustomizedElevatedIconButton(
                    icon: Icons.satellite_alt,
                    isActive: false,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _onRebootGpsPressed();
                    },
                  ),
                ],
              ),
              const SizedBox(
                height: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// class JoystickDrawer extends StatelessWidget {
//   final Server server;

//   const JoystickDrawer({
//     super.key,
//     required this.server,
//   });

//   void _onJoystickMove(Offset position, double maxSpeed, double radius) {
//     String linearSpeed =
//         (-1 * maxSpeed * position.dy / radius).toStringAsFixed(2);
//     String angularSpeed =
//         (-1 * maxSpeed * position.dx / radius).toStringAsFixed(2);
//     server.serverInterface
//         .commandMove(double.parse(linearSpeed), double.parse(angularSpeed));
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onHorizontalDragEnd: (v) {},
//       child: SafeArea(
//         child: Drawer(
//           backgroundColor: Theme.of(context).colorScheme.surface,
//           child: Column(
//             children: [
//               Align(
//                 alignment: Alignment.topLeft,
//                 child: IconButton(
//                   icon: const Icon(Icons.close),
//                   onPressed: () {
//                     Navigator.of(context).pop();
//                   },
//                 ),
//               ),
//               const Spacer(),
//               Center(
//                 child: Joystick(
//                   server: server,
//                   onJoystickMoved: _onJoystickMove,
//                 ),
//               ),
//               const Spacer(),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceAround,
//                 children: [
//                   MapButton(
//                     icon: BootstrapIcons.power,
//                     isActive: false,
//                     onPressed: () {
//                       HapticFeedback.lightImpact();
//                     },
//                   ),
//                   MapButton(
//                     icon: BootstrapIcons.bootstrap_reboot,
//                     isActive: false,
//                     onPressed: () {
//                       HapticFeedback.lightImpact();
//                     },
//                   ),
//                   MapButton(
//                     icon: Icons.satellite_alt,
//                     isActive: false,
//                     onPressed: () {
//                       HapticFeedback.lightImpact();
//                     },
//                   ),
//                 ],
//               ),
//               const SizedBox(
//                 height: 20,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
