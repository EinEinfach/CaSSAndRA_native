import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';

import 'package:cassandra_native/models/server.dart';
import 'package:cassandra_native/components/logic/map_logic.dart';
import 'package:cassandra_native/components/logic/lasso_logic.dart';
import 'package:cassandra_native/components/logic/shapes_logic.dart';
import 'package:cassandra_native/components/logic/animation_logic.dart';
import 'package:cassandra_native/components/mapping_page/map_painter.dart';
import 'package:cassandra_native/components/mapping_page/maps_overview.dart';
import 'package:cassandra_native/components/mapping_page/point_information.dart';
//import 'package:cassandra_native/components/mapping_page/select_map.dart';
import 'package:cassandra_native/components/common/buttons/customized_elevated_icon_button.dart';
import 'package:cassandra_native/components/home_page/status_bar.dart';
import 'package:cassandra_native/components/common/dialogs/customized_dialog_ok.dart';
import 'package:cassandra_native/components/common/buttons/command_button.dart';
import 'package:cassandra_native/components/common/dialogs/customized_dialog_ok_cancel.dart';
import 'package:cassandra_native/components/common/dialogs/customized_dialog_input.dart';
import 'package:cassandra_native/utils/custom_shape_calcs.dart';

class MapView extends StatefulWidget {
  final Server server;

  const MapView({
    super.key,
    required this.server,
  });

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> with SingleTickerProviderStateMixin {
  late String selectedMap;

  //zoom and pan
  ZoomPanLogic zoomPan = ZoomPanLogic();

  //selcection
  LassoLogic lasso = LassoLogic();
  Shapes shapes = Shapes();
  ShapesHistory shapesHistory = ShapesHistory();
  RecorderLogic recorderLogic = RecorderLogic();
  bool _addPointActive = false;

  //ui
  MapRobotLogic mapRobotLogic = MapRobotLogic();
  ui.Image? roverImage;
  Offset screenSizeDelta = Offset.zero;
  late Size screenSize;
  Size? oldScreenSize;
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
    widget.server.maps.scaledGhostPerimeter = [];
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    widget.server.maps.resetSelection();
    selectedMap = widget.server.maps.selected;
    shapesHistory.addNewProgress(shapes);
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

  void _openErrorDialog(String content) {
    showDialog(
      context: context,
      builder: (context) => CustomizedDialogOk(
        title: 'Error',
        content: content,
        onOkPressed: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  void _openMapsOverlay() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        scrollable: true,
        title: const Text(
          'Available maps',
          style: TextStyle(fontSize: 14),
        ),
        content: MapsOverview(
          server: widget.server,
        ),
      ),
    );
  }

  void _onSelectMapPressed() {
    if (shapes.active) {
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
              shapes.reset();
              shapesHistory.reset();
              shapesHistory.addNewProgress(shapes);
              Navigator.pop(context);
              _openMapsOverlay();
            }),
      );
    } else {
      _openMapsOverlay();
    }
  }

  void onConfirmMapSelect() {
    Size screenSize = MediaQuery.of(context).size;
    if (widget.server.maps.selected == '') {
      widget.server.maps.resetSelection();
    }
    widget.server.maps.scaleShapes(screenSize);
    shapes.scale(screenSize, widget.server.maps);
    widget.server.robot.mapsScalePosition(screenSize, widget.server.maps);
    _onNewCoordinatesReceived(widget.server.robot.mapsScaledPosition,
        widget.server.robot.angle, false);
    _addPointActive = false;
    shapes.unselectAll();
    // lasso.onScreenSizeChanged(widget.server.currentMap);
  }

  void _onActivateEditMode() {
    shapes.unselectAll();
    if (!shapes.active) {
      shapes.fromMap(widget.server.maps);
      shapes.active = true;
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
    final mapName = await showDialog(
      context: context,
      builder: (context) => CustomizedDialogInput(
        title: 'Save changes',
        content:
            'You are about to exit edit mode. Do you want to save the changes?',
        suggestionText: widget.server.maps.selected,
      ),
    );
    if (mapName == null) {
      return;
    } else if (!widget.server.maps.available.contains(mapName)) {
      final mapData = shapes.toGeoJson(mapName);
      widget.server.serverInterface.commandSaveMap(mapData);
      lasso.reset();
      shapes.reset();
      setState(() {});
    } else {
      _openErrorDialog('Map could not be stored. The given name is already exist');
    }
  }

  void _removePoint() {
    lasso.removePoint();
    if(shapes.removePoint() == -1) {
      _openErrorDialog('The point could not be deleted. The new shape has self intersections.');
    }
    shapes.finalizeMap();
    shapes.toCartesian(widget.server.maps);
    shapesHistory.addNewProgress(shapes);
    setState(() {});
  }

  void _removeShape() {
    lasso.reset();
    shapes.removeShape();
    shapes.finalizeMap();
    shapes.toCartesian(widget.server.maps);
    shapesHistory.addNewProgress(shapes);
    setState(() {});
  }

  void _onAddPointActivate() {
    _addPointActive = !_addPointActive;
    setState(() {});
  }

  void _onAddPoint(TapDownDetails details) {
    if (_addPointActive) {
      _addPointActive = false;
      shapes.addPoint(details, zoomPan);
      shapes.toCartesian(widget.server.maps);
      shapesHistory.addNewProgress(shapes);
      setState(() {});
    }
  }

  void _onAddShape() {
    if (lasso.selectedShape == 'polygon') {
      if (shapes.addPerimeter(lasso.selection) == -1) {
        _openErrorDialog('The new shape could not be added. Resolve self intersections and try it again.');
        return;
      }
    } else if (lasso.selectedShape == 'dockPath') {
      shapes.addDockPath(lasso.selection);
    } else if (lasso.selectedShape == 'searchWire') {
      shapes.addSearchWire(lasso.selection);
    }
    // shapes.addShape(lasso.selection, lasso.selectedShape);
    lasso.reset();
    shapes.finalizeMap();
    shapes.toCartesian(widget.server.maps);
    shapesHistory.addNewProgress(shapes);
    setState(() {});
  }

  void _onAddExclusion() {
    if (lasso.selectedShape == 'polygon') {
      if(shapes.addExclusion(lasso.selection) == -1) {
        _openErrorDialog('The new shape could not be added. Resolve self intersections and try it again.');
        return;
      }
    }
    //shapes.removeShape(lasso.selection, lasso.selectedShape);
    lasso.reset();
    shapes.finalizeMap();
    shapes.toCartesian(widget.server.maps);
    shapesHistory.addNewProgress(shapes);
    setState(() {});
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

  void _onTap() {
    shapes.unselectAll();
    lasso.unselectAll();
    setState(() {});
  }

  void _onDoubleTap() {
    if (lasso.selectedPointIndex != null || shapes.selectedPointIndex != null) {
      _removePoint();
    } else if (lasso.selected) {
      lasso.reset();
    } else if (shapes.selected) {
      _removeShape();
    }
    setState(() {});
  }

  void _onScaleEnd() {
    if (lasso.active) {
      lasso.finalize(zoomPan);
    }
    setState(() {});
  }

  void _onLongPressStart(LongPressStartDetails details) {
    _moved = false;
    if (lasso.selection.isNotEmpty) {
      lasso.selectPoint(details, zoomPan);
    } else if (shapes.active && !lasso.active) {
      shapes.selectPoint(details, zoomPan);
    }
    setState(() {});
  }

  void _onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    _moved = true;
    if (lasso.selection.isNotEmpty) {
      lasso.move(details, zoomPan);
    } else if (shapes.active) {
      shapes.move(details, zoomPan);
    }
    setState(() {});
  }

  void _onLongPressEnd() {
    if (_moved) {
      //lasso.unselectAll();
      //shapes.unselectAll();
      shapes.finalizeMap();
      shapes.toCartesian(widget.server.maps);
      shapesHistory.addNewProgress(shapes);
    }
    setState(() {});
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
        onConfirmMapSelect();
      }
    }
    // New map selected, new scale necassary
    if (selectedMap != widget.server.maps.selected) {
      selectedMap = widget.server.maps.selected;
      onConfirmMapSelect();
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
              onScaleStart: (details) => _onScaleStart(details),
              onScaleUpdate: (details) => _onScaleUpdate(details),
              onTap: _onTap,
              onDoubleTap: _onDoubleTap,
              onScaleEnd: (_) => _onScaleEnd(),
              onLongPressStart: (details) => _onLongPressStart(details),
              onLongPressMoveUpdate: (details) =>
                  _onLongPressMoveUpdate(details),
              onLongPressEnd: (_) => _onLongPressEnd(),
              onTapDown: (details) => _onAddPoint(details),
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
                        shapes: shapes,
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
                    !shapes.active &&
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
/***********************************************************************************Point Informations**********************************************************************************************/
            if (shapes.selectedPointIndex != null ||
                lasso.selectedPointIndex != null)
              Positioned(
                left: lasso.selectedPointIndex != null
                    ? lasso.selectedPointCoords!.dx * zoomPan.scale +
                        zoomPan.offset.dx -
                        75
                    : shapes.selectedPointCoords!.dx * zoomPan.scale +
                        zoomPan.offset.dx -
                        75,
                top: lasso.selectedPointIndex != null
                    ? lasso.selectedPointCoords!.dy * zoomPan.scale +
                        zoomPan.offset.dy -
                        160
                    : shapes.selectedPointCoords!.dy * zoomPan.scale +
                        zoomPan.offset.dy -
                        160,
                child: PointInformation(
                  shapes: shapes,
                  lasso: lasso,
                  maps: widget.server.maps,
                  insertPointActive: _addPointActive,
                  onRemovePoint: _removePoint,
                  onAddPointActivate: _onAddPointActivate,
                  onRemoveShape: _removeShape,
                ),
              ),
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
                          onPressed: _onAddShape,
                          onLongPressed: () {},
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        CommandButton(
                          icon: BootstrapIcons.dash,
                          onPressed: _onAddExclusion,
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
                              lasso.finalize(zoomPan);
                            } else {
                              lasso.selection.add(_currentPosition);
                              lasso.finalize(zoomPan);
                            }
                            _onActivateEditMode();
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
                  CustomizedElevatedIconButton(
                    icon: Icons.edit,
                    isActive: shapes.active,
                    onPressed: () {
                      if (!shapes.active) {
                        _onActivateEditMode();
                        shapesHistory.addNewProgress(shapes);
                      } else {
                        _handleSaveMap();
                      }
                      setState(() {});
                    },
                  ),
                  CustomizedElevatedIconButton(
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
                  CustomizedElevatedIconButton(
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
                  CustomizedElevatedIconButton(
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
                  CustomizedElevatedIconButton(
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
                          CustomizedElevatedIconButton(
                              icon: Icons.undo,
                              isActive: false,
                              onPressed: () {
                                shapes = shapesHistory.prevProgress().copy();
                                shapes.scale(screenSize, widget.server.maps);
                                widget.server.robot.mapsScalePosition(
                                    screenSize, widget.server.maps);
                                shapes.unselectAll();
                                setState(() {});
                              }),
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
                              zoomPan.focusOnPoint(
                                  _currentPosition, screenSize);
                              setState(() {});
                            },
                          ),
                          CustomizedElevatedIconButton(
                            icon: Icons.redo,
                            isActive: false,
                            onPressed: () {
                              shapes = shapesHistory.nextProgress().copy();
                              shapes.scale(screenSize, widget.server.maps);
                              widget.server.robot.mapsScalePosition(
                                  screenSize, widget.server.maps);
                              shapes.unselectAll();
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
          ],
        );
      }),
    );
  }
}
