import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'dart:async';

import 'package:cassandra_native/models/server.dart';
import 'package:cassandra_native/components/logic/map_logic.dart';
import 'package:cassandra_native/components/logic/lasso_logic.dart';
import 'package:cassandra_native/components/logic/animation_logic.dart';
import 'package:cassandra_native/components/logic/ui_logic.dart';
import 'package:cassandra_native/components/home_page/map_painter.dart';
import 'package:cassandra_native/components/common/customized_elevated_icon_button.dart';
import 'package:cassandra_native/components/home_page/status_bar.dart';
import 'package:cassandra_native/utils/custom_shape_calcs.dart';

class MapView extends StatefulWidget {
  final Server server;
  final void Function() openMowParametersOverlay;
  final void Function() onOpenTasksOverlay;

  const MapView({
    super.key,
    required this.server,
    required this.openMowParametersOverlay,
    required this.onOpenTasksOverlay,
  });

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> with SingleTickerProviderStateMixin {
  //zoom and pan
  ZoomPanLogic zoomPan = ZoomPanLogic();
  MapRobotLogic mapRobotLogic = MapRobotLogic();

  //selcection
  LassoLogic lasso = LassoLogic();

  //go to
  MapPointLogic gotoPoint = MapPointLogic();

  //ui
  PlayButtonLogic mapUi = PlayButtonLogic();
  ui.Image? roverImage;
  Offset screenSizeDelta = Offset.zero;
  late Size screenSize;
  Size? oldScreenSize;
  bool _isBusy = false;
  Timer? _isBusyTimer;
  bool _moved = false;

  //animation
  late MapAnimationLogic mapAnimation;
  late AnimationController _controller;
  late Animation<Offset> _animatedPosition;
  late Animation<double> _animatedAngle;
  late DateTime _lastUpdateTime;
  late Offset _currentPosition;
  late double _currentAngle;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    mapAnimation = MapAnimationLogic(robot: widget.server.robot);
    _loadImage(categoryImages[widget.server.category]!.elementAt(1));
    _resetGotoPoint();
    _resetLassoSelection();
    _resetTasksSelection();
    _currentPosition = widget.server.robot.scaledPosition;
    mapAnimation.oldPosition = widget.server.robot.scaledPosition;
    _currentAngle = widget.server.robot.angle;
    mapAnimation.oldAngle = widget.server.robot.angle;
    _controller = AnimationController(vsync: this)
      ..addListener(() {
        setState(() {
          _currentPosition = _animatedPosition.value;
          _currentAngle = _animatedAngle.value;
        });
      });
    _lastUpdateTime = DateTime.now();
  }

  void _onNewCoordinatesReceived(
      Offset newPosition, double newAngle, bool animate) {
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
    // _newPosition = newOffset;
    // _newAngle = newAngle;

    if (mapAnimation.active) {
      // Stoppe die laufende Animation
      _controller.stop();

      // Aktualisiere die Animation
      _controller.duration =
          animationDuration; // Animationsdauer entspricht der Zeit zwischen Updates

      _animatedPosition = Tween<Offset>(
        begin: _currentPosition, // Start von der aktuellen Position
        end: newPosition, // Ende bei der neuen Position
      ).animate(_controller); // Lineare Animation

      _animatedAngle = Tween<double>(
        begin: _currentAngle, // Start von der aktuellen Position
        end: newAngle, // Ende bei der neuen Position
      ).animate(_controller); // Lineare Animation

      // Starte die Animation
      _controller.forward(from: 0.0);
    } else {
      _currentPosition = newPosition;
      _currentAngle = newAngle;
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

  void _resetLassoSelection() {
    lasso.reset();
    widget.server.currentMap.selectedArea = [];
  }

  void _resetGotoPoint() {
    gotoPoint.reset();
    widget.server.currentMap.gotoPoint = null;
  }

  void _resetTasksSelection() {
    widget.server.serverInterface.commandSelectTasks([]);
  }

  void _resetObstacles() {
    widget.server.serverInterface.commandResetObstacles();
    widget.server.currentMap.resetObstaclesCoords();
  }

  void _onScaleStart(ScaleStartDetails details) {
    //selection or zoom and
    if (lasso.active) {
      lasso.selection = [];
      lasso.selectionPoints = [];
    } else {
      zoomPan.previousScale = zoomPan.scale;
      zoomPan.focalPoint = details.focalPoint;
      zoomPan.initialFocalPoint = details.focalPoint;
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    //selection or zoom and pan
    //selection
    if (lasso.active) {
      RenderBox box = context.findRenderObject() as RenderBox;
      Offset widgetGlobalPosition = box.localToGlobal(Offset.zero);
      Offset selection =
          (details.focalPoint - widgetGlobalPosition - zoomPan.offset) /
              zoomPan.scale;
      lasso.selection.add(selection);
      //zoom and pan
    } else {
      //limit sensivity of zoom
      double newScale = (zoomPan.previousScale * details.scale)
          .clamp(0.0001, double.infinity);
      //calc new offset to center zoom between focal point
      Offset focalPointDelta = zoomPan.initialFocalPoint - zoomPan.offset;
      zoomPan.offset =
          zoomPan.offset - (focalPointDelta * (newScale / zoomPan.scale - 1));
      zoomPan.scale = zoomPan.previousScale * details.scale;
      //if map is just moved, callc new offset
      if (details.scale == 1.0) {
        zoomPan.offset += details.focalPoint - zoomPan.focalPoint;
        zoomPan.focalPoint = details.focalPoint;
      }
      //set new scale
      zoomPan.scale = newScale;
    }
    setState(() {});
  }

  void _onScaleEnd() {
    if (lasso.active) {
      lasso.active = false;
      lasso.selection = simplifyPath(lasso.selection, 2.0 / zoomPan.scale);
      lasso.selectionPoints = lasso.selection;
      widget.server.currentMap.lassoSelectionToJsonData(lasso.selection);
    }
    setState(() {});
  }

  void _onLongPressStart(LongPressStartDetails details) {
    _moved = false;
    if (lasso.selection.isNotEmpty) {
      lasso.selectPoint(details, zoomPan);
    } else if (gotoPoint.coords != null) {
      gotoPoint.select(details, zoomPan);
    }
    setState(() {});
  }

  void _onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    _moved = true;
    if (lasso.selection.isNotEmpty) {
      lasso.move(details, zoomPan);
      widget.server.currentMap.lassoSelectionToJsonData(lasso.selection);
    } else if (gotoPoint.coords != null) {
      gotoPoint.move(details, zoomPan);
      widget.server.currentMap.gotoPointToJsonData(gotoPoint.coords!);
    }
    setState(() {});
  }

  void _onLongPressEnd() {
    if (_moved) {
      lasso.unselectAll();
    }
    if (gotoPoint.coords != null) {
      gotoPoint.finalize(widget.server.currentMap);
    }
    setState(() {});
  }

  void _onTap() {
    lasso.unselectAll();
    setState(() {});
  }

  void _onDoubleTap() {
    _resetObstacles();
    lasso.selected ? _resetLassoSelection() : lasso.removePoint();
    if (widget.server.robot.status != 'transit') {
      _resetGotoPoint();
    }
    _resetTasksSelection();
    setState(() {});
  }

  void _onTapDown(TapDownDetails details) {
    if (gotoPoint.active) {
      gotoPoint.setCoords(details, zoomPan, widget.server.currentMap);
      widget.server.currentMap.gotoPointToJsonData(gotoPoint.coords!);
      setState(() {});
    }
  }

  void _startBusyTimer() {
    if (!_isBusy) {
      _isBusyTimer = Timer(const Duration(seconds: 4), () {
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
    screenSize = MediaQuery.of(context).size;

    // Screen size is changed (could happened on desktop) then add additional offset on lasso and go to
    if (oldScreenSize == null) {
      oldScreenSize = screenSize;
    } else {
      screenSizeDelta = Offset(screenSize.width - oldScreenSize!.width,
          screenSize.height - oldScreenSize!.height);
      oldScreenSize = screenSize;
      if (screenSizeDelta != Offset.zero) {
        widget.server.currentMap.scaleShapes(screenSize);
        widget.server.currentMap.scalePreview();
        widget.server.currentMap.scaleMowPath();
        widget.server.currentMap.scaleObstacles();
        widget.server.currentMap.scaleTaskPreview();
        widget.server.robot.scalePosition(screenSize, widget.server.currentMap);
        _onNewCoordinatesReceived(widget.server.robot.scaledPosition,
            widget.server.robot.angle, false);
        gotoPoint.onScreenSizeChanged(widget.server.currentMap);
        lasso.scale(widget.server.currentMap);
      }
    }

    if (mapAnimation.oldAngle != mapAnimation.newAngle ||
        mapAnimation.oldPosition != mapAnimation.newPosition) {
      _onNewCoordinatesReceived(
          mapAnimation.newPosition, mapAnimation.newAngle, mapAnimation.active);
      mapAnimation.oldAngle = mapAnimation.newAngle;
      mapAnimation.oldPosition = mapAnimation.newPosition;
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
        if (mapRobotLogic.focusOnMowerActive) {
          zoomPan.focusOnPoint(_currentPosition, screenSize);
        }

        return Stack(
          children: [
            GestureDetector(
              onScaleStart: (details) => _onScaleStart(details),
              onScaleUpdate: (details) => _onScaleUpdate(details),
              onScaleEnd: (_) => _onScaleEnd(),
              onLongPressStart: (details) => _onLongPressStart(details),
              onLongPressMoveUpdate: (details) =>
                  _onLongPressMoveUpdate(details),
              onLongPressEnd: (_) => _onLongPressEnd(),
              onTap: _onTap,
              onDoubleTap: _onDoubleTap,
              onTapDown: (details) => _onTapDown(details),
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
                        lasso: lasso,
                        gotoPoint: gotoPoint,
                        currentPostion: _currentPosition,
                        currentAngle: _currentAngle,
                        colors: Theme.of(context).colorScheme),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomizedElevatedIconButton(
                    icon: Icons.settings,
                    isActive: false,
                    onPressed: widget.openMowParametersOverlay,
                  ),
                  CustomizedElevatedIconButton(
                    icon: Icons.gesture_outlined,
                    isActive: lasso.active,
                    onPressed: () {
                      lasso.active = !lasso.active;
                      if (lasso.active) {
                        mapRobotLogic.focusOnMowerActive = false;
                        _resetGotoPoint();
                        _resetLassoSelection();
                        lasso.active = true;
                        _resetTasksSelection();
                        lasso.selection = [];
                        lasso.selectionPoints = [];
                      }
                      setState(() {});
                    },
                  ),
                  CustomizedElevatedIconButton(
                    icon: Icons.add_location,
                    isActive: gotoPoint.active,
                    onPressed: () {
                      mapRobotLogic.focusOnMowerActive = false;
                      _resetGotoPoint();
                      _resetLassoSelection();
                      _resetTasksSelection();
                      gotoPoint.active = !gotoPoint.active;
                      gotoPoint.coords = null;
                      setState(() {});
                    },
                  ),
                  CustomizedElevatedIconButton(
                    icon: Icons.list,
                    isActive: false,
                    onPressed: () {
                      mapRobotLogic.focusOnMowerActive = false;
                      _resetGotoPoint();
                      _resetLassoSelection();
                      widget.onOpenTasksOverlay();
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(
              width: 3,
            ),
            Column(
              children: [
                StatusBar(robot: widget.server.robot),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomizedElevatedIconButton(
                            icon: Icons.zoom_in_map,
                            isActive: false,
                            onPressed: () {
                              mapRobotLogic.focusOnMowerActive = false;
                              lasso.active = false;
                              zoomPan.offset = Offset.zero;
                              zoomPan.scale = 1.0;
                              setState(() {});
                            },
                          ),
                          CustomizedElevatedIconButton(
                            icon: Icons.center_focus_weak_outlined,
                            isActive: mapRobotLogic.focusOnMowerActive,
                            onPressed: () {
                              mapRobotLogic.focusOnMowerActive =
                                  !mapRobotLogic.focusOnMowerActive;
                              lasso.active = false;
                              gotoPoint.active = false;
                              zoomPan.focusOnPoint(
                                  _currentPosition, screenSize);
                              setState(() {});
                            },
                          ),
                        ],
                      ),
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
