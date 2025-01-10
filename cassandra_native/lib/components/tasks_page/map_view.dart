import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import 'package:cassandra_native/models/server.dart';
import 'package:cassandra_native/components/common/buttons/customized_elevated_icon_button.dart';
import 'package:cassandra_native/components/logic/lasso_logic.dart';
import 'package:cassandra_native/components/logic/map_logic.dart';
import 'package:cassandra_native/components/tasks_page/map_painter.dart';
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

class _MapViewState extends State<MapView> {
  //zoom and pan
  ZoomPanLogic zoomPan = ZoomPanLogic();
  MapRobotLogic mapRobotLogic = MapRobotLogic();

  //selcection
  LassoLogic lasso = LassoLogic();

  //ui
  Offset screenSizeDelta = Offset.zero;
  late Size screenSize;
  Size? oldScreenSize;
  bool _moved = false;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _resetLassoSelection();
    _resetTasksSelection();
  }

  void _resetLassoSelection() {
    lasso.reset();
    widget.server.currentMap.selectedArea = [];
  }

  void _resetTasksSelection() {
    widget.server.serverInterface.commandSelectTasks([]);
    widget.server.currentMap.tasks.selected = [];
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

  void _onActivateLasso() {
    _resetLassoSelection();
    if (!lasso.active) {
      lasso.active = true;
      //_onActivateEditMode();
    } else {
      lasso.active = false;
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
      setState(() {});
    }
  }

  void _onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    _moved = true;
    if (lasso.selection.isNotEmpty) {
      lasso.move(details, zoomPan);
      widget.server.currentMap.lassoSelectionToJsonData(lasso.selection);
    }
    setState(() {});
  }

  void _onLongPressEnd() {
    // if (_moved) {
    //   lasso.unselectAll();
    // }
    setState(() {});
  }

  void _onTap() {
    lasso.unselectAll();
    setState(() {});
  }

  void _onDoubleTap() {
    if (lasso.selectedPointIndex != null) {
      lasso.removePoint();
    } else if (lasso.selected || lasso.selection.isNotEmpty) {
      _resetLassoSelection();
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
        widget.server.currentMap.scaleShapes(screenSize);
        widget.server.currentMap.scaleTaskPreview();
        lasso.scale(widget.server.currentMap);
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
      child: LayoutBuilder(
        builder: (context, constraints) {
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
/************************************Main Content**********************************************************/
                child: SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: CustomPaint(
                      painter: MapPainter(
                        offset: zoomPan.offset,
                        scale: zoomPan.scale,
                        currentServer: widget.server,
                        lasso: lasso,
                        colors: Theme.of(context).colorScheme,
                      ),
                    ),
                  ),
                ),
              ),
/************************************Map Buttons right side**********************************************************/
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
                      icon: Icons.edit,
                      isActive: false,
                      onPressed: () {
                        setState(() {});
                      },
                    ),
                    CustomizedElevatedIconButton(
                      icon: Icons.gesture_outlined,
                      isActive: lasso.active,
                      onPressed: () {
                        _onActivateLasso();
                        setState(() {});
                      },
                    ),
                    CustomizedElevatedIconButton(
                      icon: Icons.list,
                      isActive: false,
                      onPressed: () {
                        widget.onOpenTasksOverlay();
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
