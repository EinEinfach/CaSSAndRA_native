import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:provider/provider.dart';
import 'dart:async';

import 'package:cassandra_native/cassandra_native.dart';
import 'package:cassandra_native/models/server.dart';
import 'package:cassandra_native/comm/mqtt_manager.dart';
import 'package:cassandra_native/components/home_page/logic/widget_logic.dart';
import 'package:cassandra_native/components/home_page/map_painter.dart';
import 'package:cassandra_native/components/home_page/map_button.dart';
import 'package:cassandra_native/components/home_page/play_button.dart';
import 'package:cassandra_native/components/home_page/status_bar.dart';
import 'package:cassandra_native/utils/custom_shape_calcs.dart';

// globals
import 'package:cassandra_native/data/user_data.dart' as user;

class MapView extends StatefulWidget {
  final Server server;
  final void Function() openMowParametersOverlay;

  const MapView({
    super.key,
    required this.server,
    required this.openMowParametersOverlay,
  });

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> with SingleTickerProviderStateMixin {
  //app lifecycle
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;

  //zoom and pan
  ZoomPan zoomPan = ZoomPan();

  //selcection
  Lasso lasso = Lasso();

  //go to
  MapPoint gotoPoint = MapPoint();

  //ui
  MapUi mapUi = MapUi();
  ui.Image? roverImage;
  Offset screenSizeDelta = Offset.zero;
  late Size screenSize;
  Size? oldScreenSize;
  bool _isBusy = false;
  Timer? _isBusyTimer;

  //animation
  bool animationIsActive = false;
  List<String> statesForAnimation = ['mow', 'transit', 'docking', 'move'];
  late AnimationController _controller;
  late Animation<Offset> _animatedPosition;
  late Animation<double> _animatedAngle;
  late DateTime _lastUpdateTime;
  late Offset _currentPosition;
  late double _currentAngle;
  late Offset _newPosition;
  late double _newAngle;

  @override
  void dispose() {
    MqttManager.instance
        .unregisterCallback(widget.server.id, onMessageReceived);
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    widget.server.preparedCmd = 'home';
    _loadImage(categoryImages[widget.server.category]!.elementAt(1));
    _connectToServer();
    _handlePlayButton();
    _currentPosition = widget.server.robot.scaledPosition;
    _currentAngle = widget.server.robot.angle;
    _controller = AnimationController(vsync: this)
      ..addListener(() {
        setState(() {
          _currentPosition = _animatedPosition.value;
          _currentAngle = _animatedAngle.value;
        });
      });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      screenSize = MediaQuery.of(context).size;
      animationIsActive = false;
      widget.server.currentMap.scaleShapes(screenSize);
      widget.server.robot.scalePosition(screenSize, widget.server.currentMap);
      widget.server.currentMap.scalePreview();
      widget.server.currentMap.scaleMowPath();
      widget.server.currentMap.scaleObstacles();
      widget.server.currentMap.scaleTaskPreview();
      _onNewCoordinatesReceived(
          widget.server.robot.scaledPosition, widget.server.robot.angle);
    });
    _lastUpdateTime = DateTime.now();
  }

  void _onNewCoordinatesReceived(Offset newOffset, double newAngle) {
    DateTime now = DateTime.now();
    Duration animationDuration = now.difference(_lastUpdateTime);
    _lastUpdateTime = now;
    newAngle = normalizeAngle(_currentAngle, newAngle);
    // Setze die aktuelle Position als neuen Startpunkt, falls die Animation noch läuft
    if (_controller.isAnimating) {
      _currentPosition = _animatedPosition.value;
      _currentAngle = _animatedAngle.value;
    }

    // Setze die neue Position als Zielposition
    _newPosition = newOffset;
    _newAngle = newAngle;

    if (animationIsActive) {
      // Stoppe die laufende Animation
      _controller.stop();

      // Aktualisiere die Animation
      _controller.duration =
          animationDuration; // Animationsdauer entspricht der Zeit zwischen Updates

      _animatedPosition = Tween<Offset>(
        begin: _currentPosition, // Start von der aktuellen Position
        end: _newPosition, // Ende bei der neuen Position
      ).animate(_controller); // Lineare Animation

      _animatedAngle = Tween<double>(
        begin: _currentAngle, // Start von der aktuellen Position
        end: _newAngle, // Ende bei der neuen Position
      ).animate(_controller); // Lineare Animation

      // Starte die Animation
      _controller.forward(from: 0.0);
    } else {
      _currentPosition = _newPosition;
      _currentAngle = _newAngle;
    }
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

  Future<void> _loadImage(String asset) async {
    // load rover image
    final data = await rootBundle.load(asset);
    final list = Uint8List.view(data.buffer);
    final codec = await ui.instantiateImageCodec(list);
    final frame = await codec.getNextFrame();
    roverImage = frame.image;
    setState(() {
      roverImage;
    });
  }

  void onMessageReceived(String clientId, String topic, String message) {
    widget.server.onMessageReceived(clientId, topic, message);
    if (topic.contains('/robot')) {
      if (statesForAnimation.contains(widget.server.robot.status)) {
        animationIsActive = true;
      } else {
        animationIsActive = false;
      }
      widget.server.robot.scalePosition(screenSize, widget.server.currentMap);
      _onNewCoordinatesReceived(
          widget.server.robot.scaledPosition, widget.server.robot.angle);
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
    setState(() {
      if (widget.server.status == 'busy') {
        _startBusyTimer();
      } else {
        _cancelBusyTimer();
        _isBusy = false;
      }
      _handlePlayButton();
    });
  }

  void _resetLassoSelection() {
    lasso.reset();
    widget.server.currentMap.selectedArea = [];
  }

  void _resetGotoPoint() {
    gotoPoint.reset();
    widget.server.currentMap.gotoPoint = null;
  }

  void _handleCancelButton() {
    if (widget.server.currentMap.scaledObstacles.isNotEmpty) {
      widget.server.serverInterface.commandResetObstacles();
      widget.server.currentMap.resetObstaclesCoords();
    } else {
      _resetLassoSelection();
      _resetGotoPoint();
      mapUi.focusOnMowerActive = false;
    }
  }

  void _handlePlayButton({bool cmd = false}) {
    if (cmd) {
      if (mapUi.jobActive) {
        widget.server.serverInterface.commandStop();
      } else if (widget.server.preparedCmd == 'calc' &&
          widget.server.currentMap.selectedArea.isNotEmpty) {
        widget.server.serverInterface
            .commandSetSelection(widget.server.currentMap.selectedArea);
        widget.server.serverInterface
            .commandSetMowParameters(user.currentMowParameters.toJson());
        widget.server.serverInterface.commandMow('selection');
      } else if (widget.server.preparedCmd == 'calc') {
        widget.server.serverInterface
            .commandSetMowParameters(user.currentMowParameters.toJson());
        widget.server.serverInterface.commandMow('all');
      } else if (widget.server.preparedCmd == 'home') {
        widget.server.serverInterface.commandDock();
      } else if (widget.server.preparedCmd == 'go to' &&
          widget.server.currentMap.gotoPoint != null) {
        widget.server.serverInterface
            .commandGoto(widget.server.currentMap.gotoPoint!);
      } else if (widget.server.preparedCmd == 'tasks' && widget.server.currentMap.tasks.selected.isNotEmpty) {
        widget.server.serverInterface.commandMow('task');
      }
    } else {
      mapUi.onRobotStatusCheck(widget.server.robot);
    }
  }

  void _handlePlayButtonLongPressed() {
    widget.server.serverInterface.commandMow('resume');
  }

  // void setMowParameters(MowParameters mowParameters) {
  //   user.currentMowParameters = mowParameters;
  //   MowParametersStorage.saveMowParameters(mowParameters);
  // }

  // void openMowParametersOverlay() {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       shape: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.circular(12),
  //       ),
  //       backgroundColor: Theme.of(context).colorScheme.secondary,
  //       title: const Text(
  //         'Mow parameters',
  //         style: TextStyle(fontSize: 14),
  //       ),
  //       content: NewMowParameters(
  //         onSetMowParameters: setMowParameters,
  //         mowParameters: user.currentMowParameters,
  //       ),
  //     ),
  //   );
  // }

  void _startBusyTimer() {
    if (!_isBusy) {
      _isBusyTimer = Timer(const Duration(seconds: 2), () {
        _isBusy = true;
      });
    }
  }

  void _cancelBusyTimer() {
    if (_isBusyTimer != null) {
      _isBusyTimer!.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Do some lifecycle stuff before render the widget
    _handleAppLifecycleState(_appLifecycleState,
        Provider.of<CassandraNative>(context).appLifecycleState);
    _appLifecycleState =
        Provider.of<CassandraNative>(context).appLifecycleState;

    screenSize = MediaQuery.of(context).size;

    // Screen size is changed (could happened on desktop) then add additional offset on lasso and go to
    if (oldScreenSize == null) {
      oldScreenSize = screenSize;
    } else {
      screenSizeDelta = Offset(screenSize.width - oldScreenSize!.width,
          screenSize.height - oldScreenSize!.height);
      oldScreenSize = screenSize;
      if (screenSizeDelta != Offset.zero) {
        animationIsActive = false;
        widget.server.currentMap.scaleShapes(screenSize);
        widget.server.currentMap.scalePreview();
        widget.server.currentMap.scaleMowPath();
        widget.server.currentMap.scaleObstacles();
        widget.server.currentMap.scaleTaskPreview();
        widget.server.robot.scalePosition(screenSize, widget.server.currentMap);
        _onNewCoordinatesReceived(
            widget.server.robot.scaledPosition, widget.server.robot.angle);
        gotoPoint.onScreenSizeChanged(widget.server.currentMap);
        lasso.onScreenSizeChanged(widget.server.currentMap);
      }
    }

    // Listener is needed for zooming with mouse wheel on desktop apps
    return Listener(
      onPointerSignal: (pointerSignal) {
        if (pointerSignal is PointerScrollEvent) {
          setState(() {
            double scrollZoom = (pointerSignal.scrollDelta.dy > 0) ? 0.9 : 1.1;
            zoomPan.scale *= scrollZoom;
          });
        }
      },
      child: LayoutBuilder(builder: (context, constraints) {
        // zoom focus on mower
        if (mapUi.focusOnMowerActive) {
          zoomPan.focusOnPoint(_currentPosition, screenSize);
        }

        return Stack(
          children: [
            GestureDetector(
              onScaleStart: (details) {
                //selection or zoom and
                if (lasso.active) {
                  lasso.selection = [];
                  lasso.selectionPoints = [];
                } else {
                  zoomPan.previousScale = zoomPan.scale;
                  zoomPan.focalPoint = details.focalPoint;
                  zoomPan.initialFocalPoint = details.focalPoint;
                }
              },
              onScaleUpdate: (details) {
                setState(() {
                  //selection or zoom and pan

                  //selection
                  if (lasso.active && widget.server.preparedCmd == 'calc') {
                    RenderBox box = context.findRenderObject() as RenderBox;
                    Offset widgetGlobalPosition =
                        box.localToGlobal(Offset.zero);
                    Offset selection = (details.focalPoint -
                            widgetGlobalPosition -
                            zoomPan.offset) /
                        zoomPan.scale;
                    lasso.selection.add(selection);

                    //zoom and pan
                  } else {
                    //limit sensivity of zoom
                    double newScale = (zoomPan.previousScale * details.scale)
                        .clamp(0.5, double.infinity);

                    //calc new offset to center zoom between focal point
                    Offset focalPointDelta =
                        zoomPan.initialFocalPoint - zoomPan.offset;
                    zoomPan.offset = zoomPan.offset -
                        (focalPointDelta * (newScale / zoomPan.scale - 1));
                    zoomPan.scale = zoomPan.previousScale * details.scale;

                    //if map is just moved, callc new offset
                    if (details.scale == 1.0) {
                      zoomPan.offset += details.focalPoint - zoomPan.focalPoint;
                      zoomPan.focalPoint = details.focalPoint;
                    }

                    //set new scale
                    zoomPan.scale = newScale;
                  }
                });
              },
              onScaleEnd: (_) {
                if (lasso.active) {
                  setState(() {
                    lasso.active = false;
                    lasso.selection =
                        simplifyPath(lasso.selection, 2.0 / zoomPan.scale);
                    lasso.selectionPoints = lasso.selection;
                    widget.server.currentMap
                        .lassoSelectionToJsonData(lasso.selection);
                  });
                }
              },
              onLongPressStart: (details) {
                if (lasso.selection.isNotEmpty) {
                  lasso.onLongPressedStart(details, zoomPan);
                  setState(() {});
                }
              },
              onLongPressMoveUpdate: (details) {
                lasso.onLongPressedMoveUpdate(details, zoomPan);
                widget.server.currentMap
                    .lassoSelectionToJsonData(lasso.selection);
                setState(() {});
              },
              onLongPressEnd: (_) {
                lasso.onLongPressedEnd();
                setState(() {});
              },
              onTapDown: (details) {
                if (widget.server.preparedCmd == 'go to') {
                  gotoPoint.setCoords(
                      details, zoomPan, widget.server.currentMap);
                  widget.server.currentMap
                      .gotoPointToJsonData(gotoPoint.coords!);
                  setState(() {});
                }
              },
              child: SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: CustomPaint(
                    painter: MapPainter(
                        offset: zoomPan.offset,
                        scale: zoomPan.scale,
                        roverImage: roverImage,
                        currentServer: widget.server,
                        lassoSelection: lasso.selection,
                        lassoSelectionPoints: lasso.selectionPoints,
                        lassoPointSelected:
                            (lasso.selectedPointIndex == null) ? false : true,
                        lassoSelected: lasso.selected,
                        gotoPoint: gotoPoint.coords,
                        currentPostion: _currentPosition,
                        currentAngle: _currentAngle,
                        colors: Theme.of(context).colorScheme),
                  ),
                ),
              ),
            ),
            PlayButton(
              icon: mapUi.playButtonIcon,
              onPressed: () {
                _handlePlayButton(cmd: true);
              },
              onLongPressed: () {
                _handlePlayButtonLongPressed();
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    MapButton(
                      icon: Icons.cancel,
                      isActive: false,
                      onPressed: () {
                        _handleCancelButton();
                        setState(() {});
                      },
                    ),
                    MapButton(
                      icon: Icons.settings,
                      isActive: false,
                      onPressed: widget.openMowParametersOverlay,
                    ),
                  ],
                ),
                const SizedBox(
                  width: 3,
                ),
              ],
            ),
            Column(
              children: [
                StatusBar(robot: widget.server.robot),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    MapButton(
                      icon: Icons.zoom_in_map,
                      isActive: false,
                      onPressed: () {
                        mapUi.focusOnMowerActive = false;
                        lasso.active = false;
                        zoomPan.offset = Offset.zero;
                        zoomPan.scale = 1.0;
                        setState(() {});
                      },
                    ),
                    MapButton(
                      icon: Icons.center_focus_weak_outlined,
                      isActive: mapUi.focusOnMowerActive,
                      onPressed: () {
                        mapUi.focusOnMowerActive = !mapUi.focusOnMowerActive;
                        lasso.active = false;
                        zoomPan.focusOnPoint(_currentPosition, screenSize);
                        setState(() {});
                      },
                    ),
                    MapButton(
                      icon: Icons.gesture_outlined,
                      isActive: lasso.active,
                      onPressed: () {
                        if (widget.server.preparedCmd == 'calc') {
                          mapUi.focusOnMowerActive = false;
                          lasso.active = !lasso.active;
                          lasso.selection = [];
                          lasso.selectionPoints = [];
                          gotoPoint.coords = null;
                          setState(() {});
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            if (_isBusy)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}
