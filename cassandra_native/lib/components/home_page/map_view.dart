import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:provider/provider.dart';
import 'dart:async';

import 'package:cassandra_native/cassandra_native.dart';
import 'package:cassandra_native/models/server.dart';
import 'package:cassandra_native/models/mow_parameters.dart';
import 'package:cassandra_native/comm/mqtt_manager.dart';
import 'package:cassandra_native/components/home_page/map_painter.dart';
import 'package:cassandra_native/components/home_page/map_button.dart';
import 'package:cassandra_native/components/home_page/play_button.dart';
import 'package:cassandra_native/components/home_page/status_bar.dart';
import 'package:cassandra_native/components/new_mow_parameters.dart';
import 'package:cassandra_native/utils/custom_shape_calcs.dart';
import 'package:cassandra_native/utils/mow_parameters_storage.dart';

// globals
import 'package:cassandra_native/data/user_data.dart' as user;

class MapView extends StatefulWidget {
  final Server server;
  const MapView({super.key, required this.server});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  //app lifecycle
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;

  //zoom and pan
  Offset _offset = Offset.zero;
  double _scale = 1.0;
  double _previousScale = 1.0;
  Offset _focalPoint = Offset.zero;
  Offset _initialFocalPoint = Offset.zero;

  //selcection
  bool lassoSelectionActive = false;
  List<Offset> lassoSelection = [];
  List<Offset> lassoSelectionPoints = [];
  int? lassoSelectedPointIndex;
  bool lassoSelected = false;
  Offset? lastLassoPosition;

  //go to
  Offset? gotoPoint;

  //ui
  ui.Image? roverImage;
  bool focusOnMowerActive = false;
  bool jobActive = false;
  IconData playButtonIcon = Icons.play_arrow;
  Offset screenSizeDelta = Offset.zero;
  Size? oldScreenSize;
  bool _isBusy = false;
  Timer? _isBusyTimer;

  @override
  void dispose() {
    MqttManager.instance
        .unregisterCallback(widget.server.id, onMessageReceived);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadImage('lib/images/rover0grad.png');
    _connectToServer();
    setState(() {
      _handlePlayButton();
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

  void _focusOnMower() {
    Size screenSize = MediaQuery.of(context).size;
    _offset = Offset(
        screenSize.width / 2 - widget.server.robot.scaledPosition.dx * _scale,
        screenSize.height / 2 - widget.server.robot.scaledPosition.dy * _scale);
    //setState(() {});
  }

  void _lookForSelectedPointIndex(LongPressStartDetails details, double scale) {
    double minDistance = 20 / scale;
    double currentDistance = double.infinity;
    final Offset scaledAndMovedPosition =
        (details.localPosition - _offset) / _scale;
    for (int i = 0; i < lassoSelection.length; i++) {
      if ((lassoSelection[i] - scaledAndMovedPosition).distance < minDistance &&
          (lassoSelection[i] - scaledAndMovedPosition).distance <
              currentDistance) {
        currentDistance = (lassoSelection[i] - scaledAndMovedPosition).distance;
        lassoSelectedPointIndex = i;
      }
    }
    if (isPointInsidePolygon(scaledAndMovedPosition, lassoSelection) &&
        lassoSelectedPointIndex == null) {
      lassoSelected = true;
      lastLassoPosition = scaledAndMovedPosition;
    }
  }

  void _moveSelectedPoint(LongPressMoveUpdateDetails details) {
    final Offset scaledAndMovedPosition =
        (details.localPosition - _offset) / _scale;
    lassoSelection[lassoSelectedPointIndex!] = scaledAndMovedPosition;
    lassoSelectionPoints[lassoSelectedPointIndex!] = scaledAndMovedPosition;
  }

  void _moveLasso(LongPressMoveUpdateDetails details) {
    final Offset scaledAndMovedPosition =
        (details.localPosition - _offset) / _scale;
    final Offset delta = scaledAndMovedPosition - lastLassoPosition!;
    lassoSelection = lassoSelection.map((point) => point + delta).toList();
    lassoSelectionPoints =
        lassoSelectionPoints.map((point) => point + delta).toList();
    lastLassoPosition = scaledAndMovedPosition;
  }

  void _setGoToPoint(TapDownDetails details) {
    final Offset scaledAndMovedPosition =
        (details.localPosition - _offset) / _scale;
    if (isPointInsidePolygon(
        scaledAndMovedPosition, widget.server.currentMap.scaledPerimeter)) {
      for (List<Offset> exclusion
          in widget.server.currentMap.scaledExclusions) {
        if (isPointInsidePolygon(scaledAndMovedPosition, exclusion)) {
          return;
        }
      }
      gotoPoint = scaledAndMovedPosition;
    }
  }

  void _resetLassoSelection() {
    lassoSelectionActive = false;
    lassoSelection = [];
    lassoSelectionPoints = [];
    lassoSelectedPointIndex = null;
    lassoSelected = false;
    lastLassoPosition = null;
    widget.server.currentMap.selectedArea = [];
  }

  void _resetGotoPoint() {
    gotoPoint = null;
    widget.server.currentMap.gotoPoint = null;
  }

  void _handleCancelButton() {
    if (widget.server.currentMap.scaledObstacles.isNotEmpty) {
      widget.server.serverInterface.commandResetObstacles();
      widget.server.currentMap.resetObstaclesCoords();
    } else {
      _resetLassoSelection();
      _resetGotoPoint();
      focusOnMowerActive = false;
    }
  }

  void _handlePlayButton({bool cmd = false}) {
    if (cmd) {
      if (jobActive) {
        widget.server.serverInterface.commandStop();
      } else if (widget.server.preparedCmd == 'calc' &&
          lassoSelection.isNotEmpty) {
        widget.server.currentMap.lassoSelectionToJsonData(
            lassoSelection, widget.server.currentMap.mapScale);
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
      } else if (widget.server.preparedCmd == 'go to' && gotoPoint != null) {
        widget.server.currentMap
            .gotoPointToJsonData(gotoPoint!, widget.server.currentMap.mapScale);
        widget.server.serverInterface
            .commandGoto(widget.server.currentMap.gotoPoint!);
      }
    } else if (widget.server.robot.status == 'idle' ||
        widget.server.robot.status == 'charging' ||
        widget.server.robot.status == 'docked' ||
        widget.server.robot.status == 'stop' ||
        widget.server.robot.status == 'move' ||
        widget.server.robot.status == 'offline') {
      jobActive = false;
      playButtonIcon = Icons.play_arrow;
    } else {
      jobActive = true;
      playButtonIcon = Icons.pause;
    }
  }

  void _handlePlayButtonLongPressed() {
    widget.server.serverInterface.commandMow('resume');
  }

  void setMowParameters(MowParameters mowParameters) {
    user.currentMowParameters = mowParameters;
    MowParametersStorage.saveMowParameters(mowParameters);
    //widget.server.serverInterface.commandSetMowParameters(mowParameters.toJson());
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
    _handleAppLifecycleState(_appLifecycleState,
        Provider.of<CassandraNative>(context).appLifecycleState);
    _appLifecycleState =
        Provider.of<CassandraNative>(context).appLifecycleState;

    // Screen size is changed (could happened on desktop) then add additional offset on lasso and go to
    Size screenSize = MediaQuery.of(context).size;
    if (oldScreenSize == null) {
      oldScreenSize = screenSize;
    } else {
      screenSizeDelta = Offset(screenSize.width - oldScreenSize!.width,
          screenSize.height - oldScreenSize!.height);
      if (screenSizeDelta != Offset.zero) {
        _resetLassoSelection();
        //_resetGotoPoint();
      }
    }
    return Listener(
      onPointerSignal: (pointerSignal) {
        if (pointerSignal is PointerScrollEvent) {
          setState(() {
            double scrollZoom = (pointerSignal.scrollDelta.dy > 0) ? 0.9 : 1.1;
            _scale *= scrollZoom;
          });
        }
      },
      child: LayoutBuilder(builder: (context, constraints) {
        // calc new min an max coords
        final shiftedMaxX = widget.server.currentMap.shiftedMaxX;
        final shiftedMaxY = widget.server.currentMap.shiftedMaxY;

        // calc scale factor 1:1 depends on container size
        if (shiftedMaxX / shiftedMaxY >
            constraints.maxWidth / constraints.maxHeight) {
          widget.server.currentMap.mapScale =
              constraints.maxWidth / shiftedMaxX;
        } else {
          widget.server.currentMap.mapScale =
              constraints.maxHeight / shiftedMaxY;
        }

        // calc coords to canvas coords on 1:1 scale
        double mapScale = widget.server.currentMap.mapScale;
        widget.server.currentMap
            .scaleShapes(constraints.maxWidth, constraints.maxHeight);
        widget.server.currentMap.scalePreview();
        widget.server.currentMap.scaleMowPath();
        widget.server.currentMap.scaleObstacles();
        widget.server.robot.scalePosition(mapScale, constraints.maxWidth,
            constraints.maxHeight, widget.server.currentMap);

        // zoom focus on mower
        if (focusOnMowerActive) {
          _focusOnMower();
        }

        return Stack(
          children: [
            GestureDetector(
              onScaleStart: (details) {
                //selection or zoom and
                if (lassoSelectionActive) {
                  lassoSelection = [];
                  lassoSelectionPoints = [];
                } else {
                  _previousScale = _scale;
                  _focalPoint = details.focalPoint;
                  _initialFocalPoint = details.focalPoint;
                }
              },
              onScaleUpdate: (details) {
                setState(() {
                  //selection or zoom and pan

                  //selection
                  if (lassoSelectionActive &&
                      widget.server.preparedCmd == 'calc') {
                    RenderBox box = context.findRenderObject() as RenderBox;
                    Offset widgetGlobalPosition =
                        box.localToGlobal(Offset.zero);
                    Offset selection =
                        (details.focalPoint - widgetGlobalPosition - _offset) /
                            _scale;
                    lassoSelection.add(selection);

                    //zoom and pan
                  } else {
                    //limit sensivity of zoom
                    double newScale = (_previousScale * details.scale)
                        .clamp(0.5, double.infinity);

                    //calc new offset to center zoom between focal point
                    Offset focalPointDelta = _initialFocalPoint - _offset;
                    _offset =
                        _offset - (focalPointDelta * (newScale / _scale - 1));
                    _scale = _previousScale * details.scale;

                    //if map is just moved, callc new offset
                    if (details.scale == 1.0) {
                      _offset += details.focalPoint - _focalPoint;
                      _focalPoint = details.focalPoint;
                    }

                    //set new scale
                    _scale = newScale;
                  }
                });
              },
              onScaleEnd: (_) {
                if (lassoSelectionActive) {
                  setState(() {
                    lassoSelectionActive = false;
                    lassoSelection = simplifyPath(lassoSelection, 2.0 / _scale);
                    lassoSelectionPoints = lassoSelection;
                  });
                }
              },
              onLongPressStart: (details) {
                if (lassoSelection.isNotEmpty) {
                  _lookForSelectedPointIndex(details, _scale);
                  setState(() {});
                }
              },
              onLongPressMoveUpdate: (details) {
                if (lassoSelectedPointIndex != null) {
                  _moveSelectedPoint(details);
                  setState(() {});
                } else if (lassoSelected) {
                  _moveLasso(details);
                  setState(() {});
                }
              },
              onLongPressEnd: (_) {
                lassoSelectedPointIndex = null;
                lassoSelected = false;
                setState(() {});
              },
              onTapDown: (details) {
                if (widget.server.preparedCmd == 'go to') {
                  _setGoToPoint(details);
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
                        offset: _offset,
                        scale: _scale,
                        roverImage: roverImage,
                        currentServer: widget.server,
                        lassoSelection: lassoSelection,
                        lassoSelectionPoints: lassoSelectionPoints,
                        lassoPointSelected:
                            (lassoSelectedPointIndex == null) ? false : true,
                        lassoSelected: lassoSelected,
                        gotoPoint: gotoPoint,
                        colors: Theme.of(context).colorScheme),
                  ),
                ),
              ),
            ),
            PlayButton(
              icon: playButtonIcon,
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
                      onPressed: openMowParametersOverlay,
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
                        focusOnMowerActive = false;
                        lassoSelectionActive = false;
                        _offset = Offset.zero;
                        _scale = 1.0;
                        setState(() {});
                      },
                    ),
                    MapButton(
                      icon: Icons.center_focus_weak_outlined,
                      isActive: focusOnMowerActive,
                      onPressed: () {
                        focusOnMowerActive = !focusOnMowerActive;
                        lassoSelectionActive = false;
                        _focusOnMower();
                        setState(() {});
                      },
                    ),
                    MapButton(
                      icon: Icons.gesture_outlined,
                      isActive: lassoSelectionActive,
                      onPressed: () {
                        if (widget.server.preparedCmd == 'calc') {
                          focusOnMowerActive = false;
                          lassoSelectionActive = !lassoSelectionActive;
                          lassoSelection = [];
                          lassoSelectionPoints = [];
                          gotoPoint = null;
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
