import 'package:cassandra_native/components/tasks_page/tasks_overview.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:cassandra_native/cassandra_native.dart';
import 'package:cassandra_native/comm/mqtt_manager.dart';

import 'package:cassandra_native/models/server.dart';
import 'package:cassandra_native/models/mow_parameters.dart';
import 'package:cassandra_native/components/tasks_page/map_view.dart';
import 'package:cassandra_native/components/common/buttons/nav_button.dart';
import 'package:cassandra_native/components/common/drawers/nav_drawer.dart';
// import 'package:cassandra_native/components/common/select_tasks.dart';
import 'package:cassandra_native/components/common/dialogs/new_mow_parameters.dart';
import 'package:cassandra_native/utils/mow_parameters_storage.dart';

// globals
import 'package:cassandra_native/data/user_data.dart' as user;

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

  late Size screenSize;

  @override
  void initState() {
    super.initState();
    widget.server.currentMap.tasks.resetCooords();
    widget.server.serverInterface.commandSelectTasks([]);
    _connectToServer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      screenSize = MediaQuery.of(context).size;
    });
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
    if (topic.contains('/coords')) {
      if (message.contains('current map')) {
        widget.server.currentMap.scaleShapes(screenSize);
      }
    }
    setState(() {});
  }

  void openTasksOverlay() {
    if (widget.server.currentMap.tasks.available.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          title: const Text(
            'Tasks',
            style: TextStyle(fontSize: 14),
          ),
          content: TasksOverview(
            server: widget.server,
          ),
          // content: SelectTasks(
          //   server: widget.server,
          //   onSelectionChange: _onSelectedTasksChanged,
          // ),
        ),
      );
    }
  }

  void _onSelectedTasksChanged(List<String> selectedItems) {
    widget.server.serverInterface.commandSelectTasks(selectedItems);
    setState(() {});
  }

  void setMowParameters(MowParameters mowParameters) {
    user.currentMowParameters = mowParameters;
    MowParametersStorage.saveMowParameters(mowParameters);
  }

  void openMowParametersOverlay() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        title: const Text(
          'Mow parameters',
          style: TextStyle(fontSize: 14),
        ),
        content: NewMowParameters(
          onSetMowParameters: setMowParameters,
          mowParameters: user.currentMowParameters,
        ),
      ),
    );
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
              MapView(
                server: widget.server,
                openMowParametersOverlay: openMowParametersOverlay,
                onOpenTasksOverlay: openTasksOverlay,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
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
