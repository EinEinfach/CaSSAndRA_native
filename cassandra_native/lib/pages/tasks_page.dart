import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';

import 'package:cassandra_native/cassandra_native.dart';
import 'package:cassandra_native/comm/mqtt_manager.dart';

import 'package:cassandra_native/models/server.dart';
import 'package:cassandra_native/components/common/buttons/nav_button.dart';
import 'package:cassandra_native/components/common/drawers/nav_drawer.dart';

class TasksPage extends StatefulWidget {
  final Server server;
  const TasksPage({
    super.key,
    required this.server,
  });

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  //app lifecycle
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    _connectToServer();
  }

  @override
  void dispose() {
    MqttManager.instance
        .unregisterCallback(widget.server.id, _onMessageReceived);
    super.dispose();
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

  void _onMessageReceived(String clientId, String topic, String message) {
    widget.server.onMessageReceived(clientId, topic, message);
  }

  @override
  Widget build(BuildContext context) {
    // Do some lifecycle stuff before render widget
    _handleAppLifecycleState(_appLifecycleState,
        Provider.of<CassandraNative>(context).appLifecycleState);
    _appLifecycleState =
        Provider.of<CassandraNative>(context).appLifecycleState;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      drawer: NavDrawer(
        server: widget.server,
      ),
      body: Builder(
        builder: (context) {
          return SafeArea(
            child: Stack(children: [
              Row(
                children: [
                  NavButton(
                    icon: Icons.menu,
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                  ),
                ],
              ),
            ]),
          );
        },
      ),
    );
  }
}
