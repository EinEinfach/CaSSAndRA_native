import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';

import 'package:cassandra_native/pages/servers_page.dart';
import 'package:cassandra_native/models/server.dart';
import 'package:cassandra_native/components/servers_page/rtsp_stream.dart';
import 'package:cassandra_native/components/common/remote_control/joystick_v_2.dart';

class StreamPage extends StatefulWidget {
  final Server server;

  const StreamPage({
    super.key,
    required this.server,
  });

  @override
  State<StreamPage> createState() => _StreamPageState();
}

class _StreamPageState extends State<StreamPage> {
  bool _showJoystick = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    // SystemChrome.setPreferredOrientations([
    //   DeviceOrientation.portraitUp,
    //   DeviceOrientation.portraitDown,
    // ]);
    super.dispose();
  }

  void _navigateTo(Widget page) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => page,
      ),
    );
  }

  void _onJoystickMove(Offset position, double maxSpeed, double radius) {
    String linearSpeed =
        (-1 * maxSpeed * position.dy / radius).toStringAsFixed(2);
    String angularSpeed =
        (-1 * maxSpeed * position.dx / radius).toStringAsFixed(2);
    widget.server.serverInterface
        .commandMove(double.parse(linearSpeed), double.parse(angularSpeed));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: MediaQuery.of(context).orientation == Orientation.portrait
                ? RtspStream(
                    rtspUrl: widget.server.rtspUrl!,
                  )
                : RtspStream(
                    rtspUrl: widget.server.rtspUrl!,
                    aspectRatio: MediaQuery.of(context).size.width /
                        MediaQuery.of(context).size.height,
                  ),
          ),
          SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    _navigateTo(
                      ServersPage(),
                    );
                  },
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    _showJoystick = !_showJoystick;
                    setState(() {});
                  },
                  icon: Icon(
                    BootstrapIcons.joystick,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          _showJoystick
              ? SafeArea(
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: JoystickV2(
                      server: widget.server,
                      onJoystickMoved: _onJoystickMove,
                    ).animate().fadeIn().scale(),
                  ),
                )
              : const SizedBox.shrink(),
        ],
      ),
    );
  }
}
