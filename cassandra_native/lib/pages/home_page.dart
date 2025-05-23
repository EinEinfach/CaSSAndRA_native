import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';

import 'package:cassandra_native/cassandra_native.dart';
import 'package:cassandra_native/comm/mqtt_manager.dart';

import 'package:cassandra_native/pages/mobile/joystick_page.dart';
import 'package:cassandra_native/pages/tablet/home_page_tablet.dart';
import 'package:cassandra_native/pages/desktop/home_page_desktop.dart';
import 'package:cassandra_native/data/app_data.dart';
import 'package:cassandra_native/models/server.dart';
import 'package:cassandra_native/models/mow_parameters.dart';
import 'package:cassandra_native/components/common/drawers/nav_drawer.dart';
import 'package:cassandra_native/components/common/buttons/nav_button.dart';
import 'package:cassandra_native/components/common/remote_control/remote_control_drawer.dart';
import 'package:cassandra_native/components/home_page/main_content.dart';
import 'package:cassandra_native/components/home_page/select_tasks.dart';
import 'package:cassandra_native/components/home_page/status_window.dart';
import 'package:cassandra_native/components/common/buttons/command_button.dart';
import 'package:cassandra_native/components/logic/ui_logic.dart';
import 'package:cassandra_native/components/common/dialogs/new_mow_parameters.dart';
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

  PlayButtonLogic mapUi = PlayButtonLogic();
  Offset? newRobotPosition;
  late Size screenSize;

  // interactive state window
  bool statusWindwoSizeSmall = true;
  bool statusWindowReducedContent = true;
  bool drawCommandButtons = true;

  @override
  void dispose() {
    MqttManager.instance
        .unregisterCallback(widget.server.id, _onMessageReceived);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    widget.server.currentMap.tasks.resetCooords();
    widget.server.serverInterface.commandSelectTasks([]);
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
          .create(widget.server.serverInterface, _onMessageReceived);
    } else {
      MqttManager.instance
          .registerCallback(widget.server.id, _onMessageReceived);
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
        //widget.server.serverInterface.commandSelectTasks([]);
      } else if (widget.server.currentMap.gotoPoint != null) {
        widget.server.serverInterface
            .commandGoto(widget.server.currentMap.gotoPoint!);
      } else if (widget.server.currentMap.tasks.selected.isNotEmpty) {
        widget.server.serverInterface.commandMow('task');
        //widget.server.serverInterface.commandSelectTasks([]);
      } else {
        widget.server.serverInterface
            .commandSetMowParameters(user.currentMowParameters.toJson());
        widget.server.serverInterface.commandMow('all');
        //widget.server.serverInterface.commandSelectTasks([]);
      }
    } else {
      mapUi.onRobotStatusCheck(widget.server.robot);
    }
  }

  void _handlePlayButtonLongPressed() {
    widget.server.serverInterface.commandMow('resume');
  }

  void _handleHomeButton() {
    // widget.server.serverInterface.commandStop();
    widget.server.serverInterface.commandDock();
  }

  void _onMessageReceived(String clientId, String topic, String message) {
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
          onSelectionChange: _onSelectedTasksChanged,
        ),
      ),
    );
  }

  void _onSelectedTasksChanged(List<String> selectedItems) {
    final List<String> jobStates = ['mow', 'transit', 'resume'];
    if (!jobStates.contains(widget.server.robot.status)) {
      widget.server.serverInterface.commandSelectTasks(selectedItems);
      widget.server.serverInterface.commandResetRoute();
      widget.server.currentMap.resetPreviewCoords();
      widget.server.currentMap.resetMowPathCoords();
    }
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

  void changeStatusWindowSize() {
    setState(() {
      statusWindowReducedContent = true;
      statusWindwoSizeSmall = !statusWindwoSizeSmall;
      if (!statusWindwoSizeSmall) {
        drawCommandButtons = false;
      }
    });
  }

  void onContainerAnimationEnd() {
    drawCommandButtons = statusWindwoSizeSmall ? true : false;
    statusWindowReducedContent = drawCommandButtons;
    setState(() {});
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
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          endDrawer: RemoteControlDrawer(
            server: widget.server,
          ),
          drawer: NavDrawer(
            server: widget.server,
          ),
          body: Builder(builder: (context) {
            return SafeArea(
              child: Stack(
                children: [
                  /************************** Map ***************************************/
                  MainContent(
                    server: widget.server,
                    openMowParametersOverlay: openMowParametersOverlay,
                    onOpenTasksOverlay: openTasksOverlay,
                  ),
                  /************************** Dynamic status window ********************/
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 500),
                                width: statusWindwoSizeSmall ? 190 : 360,
                                height: statusWindwoSizeSmall ? 80 : 160,
                                curve: Curves.easeInOut,
                                onEnd: onContainerAnimationEnd,
                                child: StatusWindow(
                                  backgroundColor:
                                      (widget.server.robot.status != 'error' &&
                                              widget.server.robot.status !=
                                                  'offline')
                                          ? Theme.of(context)
                                              .colorScheme
                                              .surface
                                          : Theme.of(context)
                                              .colorScheme
                                              .errorContainer,
                                  server: widget.server,
                                  smallSize: statusWindowReducedContent,
                                  onPressed: changeStatusWindowSize,
                                ),
                              ),
                              const Expanded(
                                child: SizedBox(),
                              ),
                              drawCommandButtons
                                  ? CommandButton(
                                      icon: Icons.home,
                                      onPressed: () {
                                        _handleHomeButton();
                                      },
                                      onLongPressed: () {},
                                    )
                                  : const SizedBox.shrink(),
                              const SizedBox(
                                width: 10,
                              ),
                              drawCommandButtons
                                  ? CommandButton(
                                      icon: mapUi.playButtonIcon,
                                      onPressed: () {
                                        _handlePlayButton(cmd: true);
                                      },
                                      onLongPressed: () {
                                        _handlePlayButtonLongPressed();
                                      },
                                    )
                                  : const SizedBox.shrink(),
                            ],
                          ),
                          const SizedBox(
                            height: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                  /*****************************Buttons top ****************************************/
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
                          //Scaffold.of(context).openEndDrawer();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => JoystickPage(server: widget.server),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        );

        //+++++++++++++++++++++++++++++++++++++++++++++++tablet page++++++++++++++++++++++++++++++++++++++++++++++++++++
      } else if (constrains.maxWidth < largeWidth) {
        return HomePageTablet(
          server: widget.server,
          onOpenTasksOverlay: openTasksOverlay,
          openMowParametersOverlay: openMowParametersOverlay,
          statusWindow: Container(
            width: 360,
            height: 160,
            child: StatusWindow(
              backgroundColor: (widget.server.robot.status != 'error' &&
                      widget.server.robot.status != 'offline')
                  ? Theme.of(context).colorScheme.surface
                  : Theme.of(context).colorScheme.errorContainer,
              server: widget.server,
              smallSize: false,
              onPressed: () {},
            ),
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
          statusWindow: Container(
            width: 360,
            height: 160,
            child: StatusWindow(
              backgroundColor: (widget.server.robot.status != 'error' &&
                      widget.server.robot.status != 'offline')
                  ? Theme.of(context).colorScheme.surface
                  : Theme.of(context).colorScheme.errorContainer,
              server: widget.server,
              smallSize: false,
              onPressed: () {},
            ),
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
