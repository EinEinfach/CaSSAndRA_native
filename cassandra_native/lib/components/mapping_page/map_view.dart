import 'package:cassandra_native/components/common/customized_dialog_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';

import 'package:cassandra_native/models/server.dart';
import 'package:cassandra_native/components/logic/map_logic.dart';
import 'package:cassandra_native/components/logic/animation_logic.dart';
import 'package:cassandra_native/components/logic/ui_logic.dart';
import 'package:cassandra_native/components/mapping_page/map_painter.dart';
import 'package:cassandra_native/components/home_page/map_button.dart';
import 'package:cassandra_native/components/home_page/status_bar.dart';
import 'package:cassandra_native/components/common/command_button.dart';
import 'package:cassandra_native/components/common/customized_dialog_ok_cancel.dart';
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
  ShapeLogic shapeLogic = ShapeLogic();
  ShapesHistory shapesHistory = ShapesHistory();
  RecorderLogic recorderLogic = RecorderLogic();

  //ui
  PlayButtonLogic playButtonLogic = PlayButtonLogic();
  MapRobotLogic mapRobotLogic = MapRobotLogic();
  ui.Image? roverImage;
  Offset screenSizeDelta = Offset.zero;
  late Size screenSize;
  Size? oldScreenSize;

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
    widget.server.maps.scaledGhostPerimeter = [];
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    shapesHistory.onNewProgress(shapeLogic);
    mapAnimation = MapAnimationLogic(robot: widget.server.robot);
    _loadImage(categoryImages[widget.server.category]!.elementAt(1));
    lasso.reset();
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

      _controller.duration = animationDuration;

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

  void _handleCancelButton() {
    mapRobotLogic.focusOnMowerActive = false;
    if(lasso.selection.isNotEmpty){
      lasso.reset();
    } else if (shapeLogic.selectedShape != null) {
      if (shapeLogic.selectedShape == 'dockPath') {
        shapeLogic.selectedShape = null;
        shapeLogic.dockPath = [];
        shapeLogic.selectedPointIndex = null;
      } else if (shapeLogic.selectedShape == 'searchWire') {
        shapeLogic.selectedShape = null;
        shapeLogic.searchWire = [];
        shapeLogic.selectedPointIndex = null;
      } else if (shapeLogic.selectedShape == 'exclusion' &&
          shapeLogic.selectedExclusionIndex != null) {
        shapeLogic.selectedShape = null;
        shapeLogic.exclusions.removeAt(shapeLogic.selectedExclusionIndex!);
        shapeLogic.selectedExclusionIndex = null;
        shapeLogic.selectedPointIndex = null;
      } 
    } else {
      //shapeLogic.reset();
    }
  }

  void _onSelectMapPressed() {
    if (shapeLogic.active) {
      showDialog(
        context: context,
        builder: (context) => CustomizedDialogOkCancel(
            title: 'Warning',
            content:
                'You are still in edit mode. All changes will be lost. Press ok to proceed or cancel to return to edit mode.',
            onCancelPressed: () {
              Navigator.pop(context);
            },
            onOkPressed: () {
              lasso.reset();
              shapeLogic.reset();
              shapesHistory.reset();
              shapesHistory.onNewProgress(shapeLogic);
              Navigator.pop(context);
              widget.onOpenMapsOverlay();
            }),
      );
    } else {
      widget.onOpenMapsOverlay();
    }
  }

  void _onActivateEditMode() {
    shapeLogic.onTap();
    if (!shapeLogic.active) {
      shapeLogic.setMap(widget.server.maps);
      shapeLogic.active = true;
    }
  }

  void _onActivateLasso() {
    if (!lasso.active) {
      mapRobotLogic.focusOnMowerActive = false;
      lasso.reset();
      lasso.active = true;
      _onActivateEditMode();
    }
  }

  Future<void> _handleSaveMap() async {
    //var test = shapeLogic.mapCoordsToGeoJson('test');
    final mapName = await showDialog(
      context: context,
      builder: (context) => CustomizedDialogInput(
        title: 'Save changes',
        content:
            'You are about to exit edit mode. Do you want to save the changes?',
        suggestionText: widget.server.maps.selected,
      ),
    );
    if (mapName != null) {
      final mapData = shapeLogic.mapCoordsToGeoJson(mapName);
      widget.server.serverInterface.commandSaveMap(mapData);
      lasso.reset();
      shapeLogic.reset();
      setState(() {});
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
        shapeLogic.scaleShapes(screenSize, widget.server.maps);
        widget.server.robot.mapsScalePosition(screenSize, widget.server.maps);
        _onNewCoordinatesReceived(widget.server.robot.mapsScaledPosition,
            widget.server.robot.angle, false);
        // lasso.onScreenSizeChanged(widget.server.currentMap);
      }
    }

    // Robot position for animation
    if (mapAnimation.oldAngle != mapAnimation.newAngle ||
        mapAnimation.oldPosition != mapAnimation.newMapsPosition) {
      _onNewCoordinatesReceived(mapAnimation.newMapsPosition,
          mapAnimation.newAngle, mapAnimation.active);
      mapAnimation.oldAngle = mapAnimation.newAngle;
      mapAnimation.oldPosition = mapAnimation.newMapsPosition;
    }

    // Robot position for recording
    if (recorderLogic.recording) {
      recorderLogic.onRecordingNewCoordianates(_currentPosition);
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
                        .clamp(0.0001, double.infinity);

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
              onTap: () {
                shapeLogic.onTap();
                lasso.onTap();
                setState(() {});
              },
              onDoubleTap: () {
                lasso.onDoubleTap();
                shapeLogic.onDoubleTap();
                shapeLogic.onLongPressedEnd(widget.server.maps);
                shapesHistory.onNewProgress(shapeLogic);
                setState(() {});
              },
              onScaleEnd: (_) {
                if (lasso.active) {
                  setState(() {
                    lasso.onScaleEnd(zoomPan);
                    // widget.server.currentMap
                    //     .lassoSelectionToJsonData(lasso.selection);
                  });
                }
              },
              onLongPressStart: (details) {
                if (lasso.selection.isNotEmpty) {
                  lasso.onLongPressedStart(details, zoomPan);
                } else if (shapeLogic.active && !lasso.active) {
                  shapeLogic.onLongPressedStart(details, zoomPan);
                }
                setState(() {});
              },
              onLongPressMoveUpdate: (details) {
                if (lasso.selection.isNotEmpty) {
                  lasso.onLongPressedMoveUpdate(details, zoomPan);
                  // widget.server.currentMap
                  //     .lassoSelectionToJsonData(lasso.selection);
                } else if (shapeLogic.active) {
                  shapeLogic.onLongPressedMoveUpdate(details, zoomPan);
                }
                setState(() {});
              },
              onLongPressEnd: (_) {
                shapeLogic.onLongPressedEnd(widget.server.maps);
                lasso.onLongPressedEnd();
                shapesHistory.onNewProgress(shapeLogic);
                setState(() {});
              },
              onTapDown: (details) {},
/******************************************************************************************Main Content********************************************************************************************/
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
                        shapes: shapeLogic,
                        lasso: lasso,
                        recoderLogic: recorderLogic,
                        currentPostion: _currentPosition,
                        currentAngle: _currentAngle,
                        colors: Theme.of(context).colorScheme),
                  ),
                ),
              ),
            ),
            widget.server.maps.selected == '' &&
                    !shapeLogic.active &&
                    !recorderLogic.recording
                ? Align(
                    alignment: Alignment(0, -0.1),
                    child: Container(
                        padding: EdgeInsets.all(20),
                        child: Text(
                                textAlign: TextAlign.center,
                                'No coordinates loaded. Add individual points to the new map or start recording using the record button. You can also load an existing map to edit it.')
                            .animate()
                            .shake()),
                  )
                : SizedBox.shrink(),
/*************************************************************************************Command Buttons***********************************************************************************************/
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
                        CommandButton(
                          icon: BootstrapIcons.plus,
                          onPressed: () {
                            shapeLogic.addShape(
                                lasso.selection, lasso.selectedShape);
                            lasso.reset();
                            shapeLogic.onLongPressedEnd(widget.server.maps);
                            shapesHistory.onNewProgress(shapeLogic);
                          },
                          onLongPressed: () {},
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        CommandButton(
                          icon: BootstrapIcons.dash,
                          onPressed: () {
                            shapeLogic.removeShape(
                                lasso.selection, lasso.selectedShape);
                            lasso.reset();
                            shapeLogic.onLongPressedEnd(widget.server.maps);
                            shapesHistory.onNewProgress(shapeLogic);
                          },
                          onLongPressed: () {},
                        ),
                        const Expanded(
                          child: SizedBox(),
                        ),
                        CommandButton(
                          icon: recorderLogic.recordButtonIcon,
                          onPressed: () {
                            if (recorderLogic.recording) {
                              lasso.selection =
                                  List.of(recorderLogic.coordinates);
                              recorderLogic.coordinates = [];
                              lasso.onScaleEnd(zoomPan);
                            } else {
                              lasso.selection.add(_currentPosition);
                              lasso.onScaleEnd(zoomPan);
                            }
                            recorderLogic.onPress();
                            setState(() {});
                          },
                          onLongPressed: () {
                            recorderLogic.onLongPress();
                            recorderLogic.recording = true;
                            lasso.reset();
                            _onActivateEditMode();
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                  ],
                ),
              ),
            ),
/*******************************************************************************Map buttons right side*******************************************************************************************/
            Align(
              alignment: Alignment.centerRight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  MapButton(
                    icon: Icons.edit,
                    isActive: shapeLogic.active,
                    onPressed: () {
                      if (!shapeLogic.active) {
                        _onActivateEditMode();
                        shapesHistory.onNewProgress(shapeLogic);
                      } else {
                        _handleSaveMap();
                      }
                      setState(() {});
                    },
                  ),
                  MapButton(
                    icon: Icons.gesture_outlined,
                    isActive: lasso.active,
                    onPressed: () {
                      if (!lasso.active) {
                        _onActivateLasso();
                      } else {
                        lasso.reset();
                      }
                      setState(() {});
                    },
                  ),
                  MapButton(
                    icon: BootstrapIcons.house_add,
                    isActive: lasso.selectedShape == 'dockPath',
                    onPressed: () {
                      lasso.selectedShape = lasso.selectedShape != 'dockPath'
                          ? 'dockPath'
                          : 'polygon';
                      recorderLogic.selectedShape =
                          recorderLogic.selectedShape != 'dockPath'
                              ? 'dockPath'
                              : 'polygon';
                      lasso.reset();
                      _onActivateEditMode();
                      setState(() {});
                    },
                  ),
                  MapButton(
                    icon: BootstrapIcons.compass,
                    isActive: lasso.selectedShape == 'searchWire',
                    onPressed: () {
                      lasso.selectedShape = lasso.selectedShape != 'searchWire'
                          ? 'searchWire'
                          : 'polygon';
                      recorderLogic.selectedShape =
                          recorderLogic.selectedShape != 'searchWire'
                              ? 'searchWire'
                              : 'polygon';
                      lasso.reset();
                      _onActivateEditMode();
                      setState(() {});
                    },
                  ),
                  MapButton(
                    icon: Icons.list,
                    isActive: false,
                    onPressed: () {
                      recorderLogic.recording = false;
                      recorderLogic.onPress();
                      recorderLogic.coordinates = [];
                      _onSelectMapPressed();
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(
              width: 3,
            ),
/*************************************************************************************Map buttons on top*********************************************************************************************/
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
                              icon: Icons.undo,
                              isActive: false,
                              onPressed: () {
                                shapeLogic =
                                    shapesHistory.onUndoPressed().copy();
                                shapeLogic.scaleShapes(
                                    screenSize, widget.server.maps);
                                setState(() {});
                              }),
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
                              zoomPan.focusOnPoint(
                                  _currentPosition, screenSize);
                              setState(() {});
                            },
                          ),
                          MapButton(
                              icon: Icons.redo,
                              isActive: false,
                              onPressed: () {
                                shapeLogic =
                                    shapesHistory.onRedoPressed().copy();
                                shapeLogic.scaleShapes(
                                    screenSize, widget.server.maps);
                                setState(() {});
                              }),
                        ],
                      ),
                    ),
                    MapButton(
                      icon: BootstrapIcons.trash,
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
          ],
        );
      }),
    );
  }
}
