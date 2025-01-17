import 'package:cassandra_native/components/tasks_page/task_information.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';

import 'package:cassandra_native/models/server.dart';
import 'package:cassandra_native/components/logic/tasks_logic.dart';
import 'package:cassandra_native/components/common/buttons/customized_elevated_icon_button.dart';
import 'package:cassandra_native/components/common/buttons/command_button.dart';
import 'package:cassandra_native/components/common/dialogs/customized_dialog_ok_cancel.dart';
import 'package:cassandra_native/components/common/dialogs/customized_dialog_input.dart';
import 'package:cassandra_native/components/common/dialogs/customized_dialog_ok.dart';
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
  Task currentTask = Task();
  TaskHistory taskHistory = TaskHistory();

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
    // _resetTasksSelection();
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

  void _onSelectTaskPressed() {
    if (currentTask.active) {
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
              widget.server.serverInterface.commandSelectTasks([]);
              widget.server.currentMap.tasks.resetCooords();
              lasso.reset();
              currentTask.reset();
              taskHistory.reset();
              Navigator.pop(context);
              widget.onOpenTasksOverlay();
            }),
      );
    } else {
      widget.onOpenTasksOverlay();
    }
  }

  void _resetLassoSelection() {
    lasso.reset();
    widget.server.currentMap.selectedArea = [];
  }

  void _resetTasksSelection() {
    widget.server.serverInterface.commandSelectTasks([]);
    widget.server.currentMap.tasks.resetCooords();
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

  void _onActivateEditMode() {
    if (!currentTask.active) {
      //shapes.fromMap(widget.server.maps);
      currentTask.active = true;
      currentTask.fromMap(widget.server.currentMap.tasks);
    }
  }

  void _onActivateLasso() {
    if (!lasso.active) {
      _resetLassoSelection();
      lasso.active = true;
      _onActivateEditMode();
    } else {
      _resetLassoSelection();
    }
  }

  Future<void> _handleSaveTask() async {
    final taskName = await showDialog(
      context: context,
      builder: (context) => CustomizedDialogInput(
        title: 'Save changes',
        content:
            'You are about to exit edit mode. Do you want to save the changes?',
        suggestionText: '', //widget.server.maps.selected,
      ),
    );
    if (taskName == null) {
      return;
    } else if (taskName.isNotEmpty) {
      widget.server.serverInterface.commandSelectTasks([]);
      widget.server.currentMap.tasks.resetCooords();
      _resetLassoSelection();
      currentTask.reset();
      taskHistory.reset();
    } else {
      _openErrorDialog(
          'Task could not be stored. No save routine implemented.');
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
    } else if (currentTask.active && !lasso.active) {
      currentTask.selectPoint(details, zoomPan);
    }
    setState(() {});
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
    currentTask.unselectAll();
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
        currentTask.scale(screenSize, widget.server.currentMap);
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
                        currentTask: currentTask,
                        colors: Theme.of(context).colorScheme,
                      ),
                    ),
                  ),
                ),
              ),
/************************************Task information****************************************************************/
              if (currentTask.centroids.isNotEmpty && currentTask.active)
                ...currentTask.centroids.entries.expand((entry) {
                  int currentSubtaskNr = 0;
                  return entry.value.map((position) {
                    currentSubtaskNr++;
                    return Positioned(
                      left: position.dx * zoomPan.scale + zoomPan.offset.dx,
                      top: position.dy * zoomPan.scale + zoomPan.offset.dy,
                      child: TaskInformation(
                        taskName: entry.key,
                        subtaskNr: currentSubtaskNr,
                      ),
                    );
                  }).toList();
                }),
/************************************Command Buttons*****************************************************************/
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          CommandButton(
                            icon: BootstrapIcons.plus,
                            onPressed: () {}, //_onAddShape,
                            onLongPressed: () {},
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          CommandButton(
                            icon: BootstrapIcons.dash,
                            onPressed: () {},
                            onLongPressed: () {},
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
                      isActive: currentTask.active,
                      onPressed: () {
                        if (!currentTask.active) {
                          _onActivateEditMode();
                        } else {
                          _handleSaveTask();
                        }
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
                        _onSelectTaskPressed();
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
