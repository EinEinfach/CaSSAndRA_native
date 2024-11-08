import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'dart:async';

import 'package:cassandra_native/models/server.dart';
import 'package:cassandra_native/components/logic/map_logic.dart';
import 'package:cassandra_native/components/logic/animation_logic.dart';
import 'package:cassandra_native/components/logic/ui_logic.dart';
import 'package:cassandra_native/components/mapping_page/map_painter.dart';
import 'package:cassandra_native/components/home_page/map_button.dart';
import 'package:cassandra_native/components/home_page/status_bar.dart';
import 'package:cassandra_native/utils/custom_shape_calcs.dart';

class MapView extends StatefulWidget {
  final Server server;
  // final void Function() openMowParametersOverlay;
  final void Function() onOpenMapsOverlay;

  const MapView({
    super.key,
    required this.server,
    // required this.openMowParametersOverlay,
    required this.onOpenMapsOverlay,
  });

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> with SingleTickerProviderStateMixin {
  //zoom and pan
  ZoomPanLogic zoomPan = ZoomPanLogic();

  //selcection
  LassoLogic lasso = LassoLogic();

  //go to
  MapPointLogic gotoPoint = MapPointLogic();

  //ui
  PlayButtonLogic playButtonLogic = PlayButtonLogic();
  MapRobotLogic mapRobotLogic = MapRobotLogic();
  ui.Image? roverImage;
  Offset screenSizeDelta = Offset.zero;
  late Size screenSize;
  Size? oldScreenSize;
  bool _isBusy = false;
  Timer? _isBusyTimer;

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
    _currentPosition = widget.server.robot.mapsScaledPosition;
    mapAnimation.oldPosition = widget.server.robot.mapsScaledPosition;
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

    if (mapAnimation.active) {
      _controller.stop();

      _controller.duration =
          animationDuration;

      _animatedPosition = Tween<Offset>(
        begin: _currentPosition, 
        end: newPosition,
      ).animate(_controller);

      _animatedAngle = Tween<double>(
        begin: _currentAngle,
        end: newAngle, 
      ).animate(_controller); 

      _controller.forward(from: 0.0);
    } else {
      _currentPosition = newPosition;
      _currentAngle = newAngle;
    }
  }

  Future<void> _loadImage(String asset) async {
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

  void _handleCancelButton() {
    if (widget.server.currentMap.scaledObstacles.isNotEmpty) {
      widget.server.serverInterface.commandResetObstacles();
      widget.server.currentMap.resetObstaclesCoords();
    } else {
      _resetLassoSelection();
      _resetGotoPoint();
      mapRobotLogic.focusOnMowerActive = false;
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
        widget.server.maps.scaleShapes(screenSize);
        widget.server.robot.mapsScalePosition(screenSize, widget.server.maps);
        _onNewCoordinatesReceived(widget.server.robot.mapsScaledPosition,
            widget.server.robot.angle, false);
        gotoPoint.onScreenSizeChanged(widget.server.currentMap);
        lasso.onScreenSizeChanged(widget.server.currentMap);
      }
    }

    if (mapAnimation.oldAngle != mapAnimation.newAngle ||
        mapAnimation.oldPosition != mapAnimation.newMapsPosition) {
      _onNewCoordinatesReceived(
          mapAnimation.newMapsPosition, mapAnimation.newAngle, mapAnimation.active);
      mapAnimation.oldAngle = mapAnimation.newAngle;
      mapAnimation.oldPosition = mapAnimation.newMapsPosition;
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
                  if (lasso.active) {
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
                } else if (gotoPoint.coords != null) {
                  gotoPoint.onLongPressedStart(details, zoomPan);
                }
                setState(() {});
              },
              onLongPressMoveUpdate: (details) {
                if (lasso.selection.isNotEmpty) {
                  lasso.onLongPressedMoveUpdate(details, zoomPan);
                  widget.server.currentMap
                      .lassoSelectionToJsonData(lasso.selection);
                } else if (gotoPoint.coords != null) {
                  gotoPoint.onLongPressedMoveUpdate(details, zoomPan);
                  widget.server.currentMap
                      .gotoPointToJsonData(gotoPoint.coords!);
                }
                setState(() {});
              },
              onLongPressEnd: (_) {
                if (lasso.selection.isNotEmpty) {
                  lasso.onLongPressedEnd();
                } else if (gotoPoint.coords != null) {
                  gotoPoint.onLongPressedEnd(widget.server.currentMap);
                }
                setState(() {});
              },
              onTapDown: (details) {
                if (gotoPoint.active) {
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
                  MapButton(
                    icon: Icons.settings,
                    isActive: false,
                    onPressed: () {},
                  ),
                  MapButton(
                    icon: Icons.gesture_outlined,
                    isActive: lasso.active,
                    onPressed: () {
                      mapRobotLogic.focusOnMowerActive = false;
                      _resetGotoPoint();
                      _resetLassoSelection();
                      lasso.active = !lasso.active;
                      lasso.selection = [];
                      lasso.selectionPoints = [];
                      setState(() {});
                    },
                  ),
                  MapButton(
                    icon: Icons.add_location,
                    isActive: gotoPoint.active,
                    onPressed: () {
                      mapRobotLogic.focusOnMowerActive = false;
                      _resetGotoPoint();
                      _resetLassoSelection();
                      gotoPoint.active = !gotoPoint.active;
                      gotoPoint.coords = null;
                      setState(() {});
                    },
                  ),
                  MapButton(
                    icon: Icons.list,
                    isActive: false,
                    onPressed: () {
                      mapRobotLogic.focusOnMowerActive = false;
                      _resetGotoPoint();
                      _resetLassoSelection();
                      widget.onOpenMapsOverlay();
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
                          const SizedBox(
                            width: 50,
                          ),
                          MapButton(
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
                          MapButton(
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
                    MapButton(
                      icon: Icons.cancel,
                      isActive: false,
                      onPressed: () {
                        _handleCancelButton();
                        setState(() {});
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
