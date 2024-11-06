import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';

import 'package:cassandra_native/cassandra_native.dart';
import 'package:cassandra_native/comm/mqtt_manager.dart';

import 'package:cassandra_native/models/server.dart';
import 'package:cassandra_native/components/common/joystick_drawer.dart';
import 'package:cassandra_native/components/common/nav_button.dart';
import 'package:cassandra_native/components/common/nav_drawer.dart';
import 'package:cassandra_native/components/mapping_page/map_view.dart';
import 'package:cassandra_native/components/mapping_page/select_map.dart';

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

  late Size screenSize;

  @override
  void dispose() {
    MqttManager.instance
        .unregisterCallback(widget.server.id, onMessageReceived);
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
          .create(widget.server.serverInterface, onMessageReceived);
    } else {
      MqttManager.instance
          .registerCallback(widget.server.id, onMessageReceived);
    }
  }

  void onMessageReceived(String clientId, String topic, String message) {
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

  void openMapsOverlay() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        title: const Text(
          'Available maps',
          style: TextStyle(fontSize: 14),
        ),
        content: SelectMap(
          server: widget.server,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Do some lifecycle stuff before render the widget
    _handleAppLifecycleState(_appLifecycleState,
        Provider.of<CassandraNative>(context).appLifecycleState);
    _appLifecycleState =
        Provider.of<CassandraNative>(context).appLifecycleState;
    return Scaffold(
      drawer: NavDrawer(
        server: widget.server,
      ),
      endDrawer: JoystickDrawer(
        server: widget.server,
      ),
      body: Builder(builder: (context) {
        return SafeArea(
          child: Stack(
            children: [
              MapView(
                server: widget.server,
                onOpenMapsOverlay: openMapsOverlay,
              ),
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
                      Scaffold.of(context).openEndDrawer();
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
