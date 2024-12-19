import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';

import 'package:cassandra_native/components/common/dialogs/customized_dialog_ok_cancel.dart';
import 'package:cassandra_native/components/common/remote_control/joystick.dart';
import 'package:cassandra_native/components/common/progress_slider.dart';
import 'package:cassandra_native/components/common/buttons/customized_elevated_icon_button.dart';
import 'package:cassandra_native/models/server.dart';

class RemoteControlContent extends StatefulWidget {
  final Server server;
  final bool closeButton;
  const RemoteControlContent({
    super.key,
    required this.server,
    required this.closeButton,
  });

  @override
  State<RemoteControlContent> createState() => _RemoteControlContentState();
}

class _RemoteControlContentState extends State<RemoteControlContent> {
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
        title: 'Info',
        content:
            'You are about to shut down the robot.\n\nIf CaSSAndRA is running on the same machine or in UART mode, the server will also be shut down. Do you want to proceed?',
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
        title: 'Info',
        content:
            'You are about to reboot the robot.\n\nIf CaSSAndRA is running on the same machine, the server will also be restarted. Do you want to proceed?',
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

  void _onToggleMowMotorPressed() {
    if (widget.server.robot.mowMotorActive) {
      widget.server.serverInterface.commandToggleMowMotor();
    } else {
      showDialog(
        context: context,
        builder: (context) => CustomizedDialogOkCancel(
          title: 'Warning',
          content: 'Activate mow motor?',
          onCancelPressed: () {
            Navigator.pop(context);
          },
          onOkPressed: () {
            widget.server.serverInterface.commandToggleMowMotor();
            Navigator.pop(context);
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          widget.closeButton
              ? Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    color: Theme.of(context).colorScheme.primary,
                  ),
                )
              : SizedBox.shrink(),
          Expanded(
            child: SizedBox.shrink(),
          ),
          Center(
            child: Joystick(
              server: widget.server,
              onJoystickMoved: _onJoystickMove,
            ),
          ),
          SizedBox(
            height: 30,
          ),
          ProgressSlider(
            server: widget.server,
          ),
          SizedBox(
            height: 20,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              SizedBox(
                width: 50,
              ),
              CustomizedElevatedIconButton(
                icon: BootstrapIcons.fan,
                isActive: widget.server.robot.mowMotorActive,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _onToggleMowMotorPressed();
                },
              ),
              CustomizedElevatedIconButton(
                icon: BootstrapIcons.skip_end,
                isActive: false,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  widget.server.serverInterface.commandSkipNextPoint();
                },
              ),
            ],
          ),
          SizedBox(
            height: 10,
          ),
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
    );
  }
}
