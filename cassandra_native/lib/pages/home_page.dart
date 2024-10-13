import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:cassandra_native/cassandra_native.dart';
import 'package:cassandra_native/comm/mqtt_manager.dart';

import 'package:cassandra_native/pages/mobile/home_page_mobile.dart';
import 'package:cassandra_native/pages/tablet/home_page_tablet.dart';
import 'package:cassandra_native/pages/desktop/home_page_desktop.dart';
import 'package:cassandra_native/data/app_data.dart';
import 'package:cassandra_native/models/server.dart';
import 'package:cassandra_native/models/mow_parameters.dart';
import 'package:cassandra_native/components/home_page/select_tasks.dart';
import 'package:cassandra_native/components/home_page/status_window.dart';
import 'package:cassandra_native/components/home_page/command_button.dart';
import 'package:cassandra_native/components/home_page/logic/home_page_logic.dart';
import 'package:cassandra_native/components/new_mow_parameters.dart';
import 'package:cassandra_native/utils/mow_parameters_storage.dart';

// globals
import 'package:cassandra_native/data/user_data.dart' as user;

class HomePage extends StatefulWidget {
  final Server server;
  const HomePage({super.key, required this.server});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //app lifecycle
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;

  MapUiLogic mapUi = MapUiLogic();
  Offset? newRobotPosition;
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
    newRobotPosition = widget.server.robot.scaledPosition;
    _handlePlayButton();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      screenSize = MediaQuery.of(context).size;
      widget.server.currentMap.scaleShapes(screenSize);
      widget.server.robot.scalePosition(screenSize, widget.server.currentMap);
      widget.server.currentMap.scalePreview();
      widget.server.currentMap.scaleMowPath();
      widget.server.currentMap.scaleObstacles();
      widget.server.currentMap.scaleTaskPreview();
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

  void _handlePlayButton({bool cmd = false}) {
    if (cmd) {
      if (mapUi.jobActive) {
        widget.server.serverInterface.commandStop();
      } else if (widget.server.currentMap.selectedArea.isNotEmpty) {
        widget.server.serverInterface
            .commandSetSelection(widget.server.currentMap.selectedArea);
        widget.server.serverInterface
            .commandSetMowParameters(user.currentMowParameters.toJson());
        widget.server.serverInterface.commandMow('selection');
      } else if (widget.server.currentMap.gotoPoint != null) {
        widget.server.serverInterface
            .commandGoto(widget.server.currentMap.gotoPoint!);
      } else if (widget.server.currentMap.tasks.selected.isNotEmpty) {
        widget.server.serverInterface.commandMow('task');
      } else {
        widget.server.serverInterface
            .commandSetMowParameters(user.currentMowParameters.toJson());
        widget.server.serverInterface.commandMow('all');
      }
    } else {
      mapUi.onRobotStatusCheck(widget.server.robot);
    }
  }

  void _handlePlayButtonLongPressed() {
    widget.server.serverInterface.commandMow('resume');
  }

  void _handleHomeButton() {
    widget.server.serverInterface.commandStop();
    widget.server.serverInterface.commandDock();
  }

  void onMessageReceived(String clientId, String topic, String message) {
    widget.server.onMessageReceived(clientId, topic, message);
    if (topic.contains('/robot')) {
      widget.server.robot.scalePosition(screenSize, widget.server.currentMap);
      _handlePlayButton();
    }
    if (topic.contains('/coords')) {
      if (message.contains('current map')) {
        widget.server.currentMap.scaleShapes(screenSize);
        widget.server.robot.scalePosition(screenSize, widget.server.currentMap);
      } else {
        widget.server.currentMap.scalePreview();
        widget.server.currentMap.scaleMowPath();
        widget.server.currentMap.scaleObstacles();
        widget.server.currentMap.scaleTaskPreview();
      }
    }
    setState(() {});
  }

  void openTasksOverlay() {
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
        content: SelectTasks(
          server: widget.server,
        ),
      ),
    );
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
    // Do some lifecycle stuff before render the widget
    _handleAppLifecycleState(_appLifecycleState,
        Provider.of<CassandraNative>(context).appLifecycleState);
    _appLifecycleState =
        Provider.of<CassandraNative>(context).appLifecycleState;
    return LayoutBuilder(builder: (context, constrains) {
      //+++++++++++++++++++++++++++++++++++++++++++++++mobile page++++++++++++++++++++++++++++++++++++++++++++++++++++
      if (constrains.maxWidth < smallWidth) {
        return HomePageMobile(
          server: widget.server,
          onOpenTasksOverlay: openTasksOverlay,
          openMowParametersOverlay: openMowParametersOverlay,
          statusWindow: StatusWindow(
            backgroundColor: (widget.server.robot.status != 'error' &&
                    widget.server.robot.status != 'offline')
                ? Theme.of(context).colorScheme.surface
                : Theme.of(context).colorScheme.errorContainer,
            server: widget.server,
            smallSize: true,
          ),
          playButton: CommandButton(
            icon: mapUi.playButtonIcon,
            onPressed: () {
              _handlePlayButton(cmd: true);
            },
            onLongPressed: () {
              _handlePlayButtonLongPressed();
            },
          ),
          homeButton: CommandButton(
            icon: Icons.home,
            onPressed: () {
              _handleHomeButton();
            },
            onLongPressed: () {},
          ),
        );
        //+++++++++++++++++++++++++++++++++++++++++++++++tablet page++++++++++++++++++++++++++++++++++++++++++++++++++++
      } else if (constrains.maxWidth < largeWidth) {
        return HomePageTablet(
          server: widget.server,
          onOpenTasksOverlay: openTasksOverlay,
          openMowParametersOverlay: openMowParametersOverlay,
          statusWindow: StatusWindow(
            backgroundColor: (widget.server.robot.status != 'error' &&
                    widget.server.robot.status != 'offline')
                ? Theme.of(context).colorScheme.surface
                : Theme.of(context).colorScheme.errorContainer,
            server: widget.server,
            smallSize: false,
          ),
          playButton: CommandButton(
            icon: mapUi.playButtonIcon,
            onPressed: () {
              _handlePlayButton(cmd: true);
            },
            onLongPressed: () {
              _handlePlayButtonLongPressed();
            },
          ),
          homeButton: CommandButton(
            icon: Icons.home,
            onPressed: () {
              _handleHomeButton();
            },
            onLongPressed: () {},
          ),
        );
        //+++++++++++++++++++++++++++++++++++++++++++++++desktop page++++++++++++++++++++++++++++++++++++++++++++++++++++
      } else {
        return HomePageDesktop(
          server: widget.server,
          onOpenTasksOverlay: openTasksOverlay,
          openMowParametersOverlay: openMowParametersOverlay,
          statusWindow: StatusWindow(
            backgroundColor: (widget.server.robot.status != 'error' &&
                    widget.server.robot.status != 'offline')
                ? Theme.of(context).colorScheme.surface
                : Theme.of(context).colorScheme.errorContainer,
            server: widget.server,
            smallSize: false,
          ),
          playButton: CommandButton(
            icon: mapUi.playButtonIcon,
            onPressed: () {
              _handlePlayButton(cmd: true);
            },
            onLongPressed: () {
              _handlePlayButtonLongPressed();
            },
          ),
          homeButton: CommandButton(
            icon: Icons.home,
            onPressed: () {
              _handleHomeButton();
            },
            onLongPressed: () {},
          ),
        );
      }
    });
  }
}
