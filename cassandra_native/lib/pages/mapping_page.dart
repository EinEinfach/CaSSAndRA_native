import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';

import 'package:cassandra_native/cassandra_native.dart';
import 'package:cassandra_native/comm/mqtt_manager.dart';

import 'package:cassandra_native/models/server.dart';
import 'package:cassandra_native/components/common/remote_control/joystick_v_2.dart';
import 'package:cassandra_native/components/common/buttons/nav_button.dart';
import 'package:cassandra_native/components/common/drawers/nav_drawer.dart';
import 'package:cassandra_native/components/mapping_page/main_content.dart';

class MappingPage extends StatefulWidget {
  final Server server;
  const MappingPage({
    super.key,
    required this.server,
  });

  @override
  State<MappingPage> createState() => _MappingPageState();
}

class _MappingPageState extends State<MappingPage> {
  //app lifecycle
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;

  bool recording = false;
  bool _showJoystick = false;

  late Size screenSize;

  @override
  void dispose() {
    MqttManager.instance
        .unregisterCallback(widget.server.id, _onMessageReceived);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _connectToServer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      screenSize = MediaQuery.of(context).size;
      widget.server.maps.scaleShapes(screenSize);
      widget.server.robot.mapsScalePosition(screenSize, widget.server.maps);
    });
  }

  void _handleAppLifecycleState(
      AppLifecycleState oldState, AppLifecycleState newState) {
    if (newState == AppLifecycleState.resumed &&
        oldState != AppLifecycleState.resumed) {
      _connectToServer();
    }
  }

  Future<void> _connectToServer() async {
    if (MqttManager.instance.isNotConnected(widget.server.id)) {
      await MqttManager.instance
          .create(widget.server.serverInterface, _onMessageReceived);
    } else {
      MqttManager.instance
          .registerCallback(widget.server.id, _onMessageReceived);
    }
  }

  void _onJoystickMove(Offset position, double maxSpeed, double radius) {
    String linearSpeed =
        (-1 * maxSpeed * position.dy / radius).toStringAsFixed(2);
    String angularSpeed =
        (-1 * maxSpeed * position.dx / radius).toStringAsFixed(2);
    widget.server.serverInterface
        .commandMove(double.parse(linearSpeed), double.parse(angularSpeed));
  }

  void _onMessageReceived(String clientId, String topic, String message) {
    widget.server.onMessageReceived(clientId, topic, message);
    if (topic.contains('/robot')) {
      widget.server.robot.mapsScalePosition(screenSize, widget.server.maps);
    }
    if (topic.contains('/mapsCoords')) {
      widget.server.maps.scaleShapes(screenSize);
      widget.server.robot.mapsScalePosition(screenSize, widget.server.maps);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Do some lifecycle stuff before render the widget
    _handleAppLifecycleState(_appLifecycleState,
        Provider.of<CassandraNative>(context).appLifecycleState);
    _appLifecycleState =
        Provider.of<CassandraNative>(context).appLifecycleState;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      drawer: NavDrawer(
        server: widget.server,
      ),
      // endDrawer: JoystickDrawer(
      //   server: widget.server,
      // ),
      body: Builder(builder: (context) {
        return SafeArea(
          child: Stack(
            children: [
              MainContent(
                server: widget.server,
                //onOpenMapsOverlay: openMapsOverlay,
              ),
              _showJoystick
                  ? Align(
                      alignment: Alignment.bottomRight,
                      child: Container(
                        padding: EdgeInsets.fromLTRB(0, 0, 10, 80),
                        child: JoystickV2(
                          server: widget.server,
                          onJoystickMoved: _onJoystickMove,
                        ).animate().fadeIn().scale(),
                      ),
                    )
                  : const SizedBox.shrink(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  NavButton(
                    icon: Icons.menu,
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                  ),
                  NavButton(
                    icon: BootstrapIcons.joystick,
                    onPressed: () {
                      _showJoystick = !_showJoystick;
                      setState(() {});
                      //Scaffold.of(context).openEndDrawer();
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }
}
