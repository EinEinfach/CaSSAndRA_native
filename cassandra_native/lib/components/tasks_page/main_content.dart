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
import 'package:cassandra_native/components/common/dialogs/new_mow_parameters.dart';
import 'package:cassandra_native/components/home_page/status_bar.dart';
import 'package:cassandra_native/components/logic/lasso_logic.dart';
import 'package:cassandra_native/components/logic/map_logic.dart';
import 'package:cassandra_native/components/tasks_page/map_painter.dart';
import 'package:cassandra_native/components/tasks_page/task_information.dart';
import 'package:cassandra_native/components/tasks_page/point_information.dart';
import 'package:cassandra_native/components/tasks_page/tasks_overview.dart';
import 'package:cassandra_native/utils/custom_shape_calcs.dart';

// globals
import 'package:cassandra_native/data/user_data.dart' as user;

class MainContent extends StatefulWidget {
  final Server server;
  final void Function() openMowParametersOverlay;
  // final void Function() onOpenTasksOverlay;

  const MainContent({
    super.key,
    required this.server,
    required this.openMowParametersOverlay,
    // required this.onOpenTasksOverlay,
  });

  @override
  State<MainContent> createState() => _MainContentState();
}

class _MainContentState extends State<MainContent> {
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
    _resetTasksSelection();
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

  void _openTaskMowParametersOverlay(String taskName, int subtaskNr) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        title: Text(
          '$taskName ($subtaskNr)',
          style: TextStyle(fontSize: 14),
        ),
        content: NewMowParameters(
          onSetMowParameters: (mowParameters) {
            currentTask.mowParameters[taskName]![subtaskNr] = mowParameters;
            final subTaskData = currentTask.subtaskToGeoJson(
                taskName,
                subtaskNr,
                currentTask.selectionsCartesian[taskName]![subtaskNr],
                currentTask.mowParameters[taskName]![subtaskNr]);
            widget.server.serverInterface.commandCalculateSubtask(subTaskData);
          },
          mowParameters: currentTask.mowParameters[taskName]![subtaskNr],
        ),
      ),
    );
  }

  void _openTasksOverlay() {
    if (widget.server.currentMap.tasks.available.isNotEmpty) {
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
          content: TasksOverview(
            server: widget.server,
            onCopyTaskPressed: _onCopyTaskPressed,
          ),
          // content: SelectTasks(
          //   server: widget.server,
          //   onSelectionChange: _onSelectedTasksChanged,
          // ),
        ),
      );
    }
  }

  void _onCopyTaskPressed() {
    Navigator.pop(context);
    _openTasksOverlay();
  }

  void _selectTaskOrPointInformation(LongPressStartDetails details) {
    currentTask.selectTaskOrPointInformation(details, zoomPan);
    setState(() {});
  }

  void _moveTaskInformation(
      String taskName, int subtaskNr, LongPressMoveUpdateDetails details) {
    currentTask.moveTaskInformation(taskName, subtaskNr, details, zoomPan);
    setState(() {});
  }

  void _movePointInformation(LongPressMoveUpdateDetails details) {
    if (currentTask.pointInformationPosition != null) {
      currentTask.movePointInformation(
          currentTask.pointInformationPosition!, details, zoomPan);
    } else {
      currentTask.movePointInformation(
          currentTask.selections[currentTask.selectedTask!]![
              currentTask.selectedSubtask!][currentTask.selectedPointIndex!],
          details,
          zoomPan);
    }
    setState(() {});
  }

  Offset _checkPointInformationPosition() {
    if (currentTask.pointInformationPosition != null) {
      return currentTask.pointInformationPosition!;
    } else if (lasso.selectedPointIndex != null) {
      return lasso.selection[lasso.selectedPointIndex!];
    } else if (currentTask.selectedPointIndex != null) {
      return currentTask.selections[currentTask.selectedTask!]![
          currentTask.selectedSubtask!][currentTask.selectedPointIndex!];
    } else {
      return Offset.zero;
    }
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
              _openTasksOverlay();
            }),
      );
    } else {
      _openTasksOverlay();
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
        suggestionText: widget.server.currentMap.tasks.selected.isNotEmpty
            ? widget.server.currentMap.tasks.selected[0]
            : '',
      ),
    );
    if (taskName == null) {
      return;
    } else if (!widget.server.currentMap.tasks.available.contains(taskName)) {
      final geoJson = currentTask.toGeoJson(taskName);
      widget.server.serverInterface.commandSelectTasks([]);
      widget.server.serverInterface.commandSaveTask(geoJson);
      widget.server.currentMap.tasks.resetCooords();
      _resetLassoSelection();
      currentTask.reset();
      taskHistory.reset();
    } else {
      _openErrorDialog(
          'Task could not be stored. The given name is already in use.');
    }
  }

  void _removePoint() {
    lasso.removePoint();
    currentTask.removePoint();
    currentTask.toCartesian(widget.server.currentMap);
    final subtaskData = currentTask.subtaskToGeoJson(
        currentTask.selectedTask!,
        currentTask.selectedSubtask!,
        currentTask.selectionsCartesian[currentTask.selectedTask!]![
            currentTask.selectedSubtask!],
        currentTask.mowParameters[currentTask.selectedTask!]![
            currentTask.selectedSubtask!]);
    currentTask.unselectAll();
    widget.server.serverInterface.commandCalculateSubtask(subtaskData);
    //taskHistory.addNewProgress(currentTask);
    setState(() {});
  }

  void _removeTask() {
    currentTask.removeSubtask();
    currentTask.toCartesian(widget.server.currentMap);
    taskHistory.addNewProgress(currentTask);
  }

  void _removeTaskByButton(String taskName, int subtaskNr) {
    currentTask.selectedTask = taskName;
    currentTask.selectedSubtask = subtaskNr;
    _removeTask();
    setState(() {});
  }

  void _addTask() {
    currentTask.addSubtask(
        lasso.selection, user.currentMowParameters, widget.server.currentMap);
    _resetLassoSelection();
    currentTask.toCartesian(widget.server.currentMap);
    final currentTaskName = '';
    final amountOfSubtasks = currentTask.selections['']!.length;
    final subTaskData = currentTask.subtaskToGeoJson(
        currentTaskName,
        amountOfSubtasks - 1,
        currentTask.selectionsCartesian[currentTaskName]![amountOfSubtasks - 1],
        currentTask.mowParameters[currentTaskName]![amountOfSubtasks - 1]);
    widget.server.serverInterface.commandCalculateSubtask(subTaskData);
    setState(() {});
  }

  void _checkForNewPreview() {
    if (widget.server.currentMap.tasks.udpatedCoords.isNotEmpty) {
      currentTask.updatePreview(widget.server.currentMap.tasks.udpatedCoords);
      widget.server.currentMap.tasks.udpatedCoords = {};
      currentTask.scale(screenSize, widget.server.currentMap);
      taskHistory.addNewProgress(currentTask);
      setState(() {});
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
    } else if (currentTask.active && !lasso.active) {
      currentTask.move(details, zoomPan);
    }
    setState(() {});
  }

  void _onLongPressEnd() {
    if (_moved) {
      currentTask.toCartesian(widget.server.currentMap);
      final subtaskData = currentTask.subtaskToGeoJson(
          currentTask.selectedTask!,
          currentTask.selectedSubtask!,
          currentTask.selectionsCartesian[currentTask.selectedTask!]![
              currentTask.selectedSubtask!],
          currentTask.mowParameters[currentTask.selectedTask!]![
              currentTask.selectedSubtask!]);
      widget.server.serverInterface.commandCalculateSubtask(subtaskData);
      // taskHistory.addNewProgress(currentTask);
    }
    setState(() {});
  }

  void _onTap() {
    lasso.unselectAll();
    currentTask.unselectAll();
    setState(() {});
  }

  void _onDoubleTap() {
    if (lasso.selectedPointIndex != null ||
        currentTask.selectedPointIndex != null) {
      _removePoint();
    } else if (lasso.selected || lasso.selection.isNotEmpty) {
      _resetLassoSelection();
    } else if (currentTask.selectedTask != null &&
        currentTask.selectedSubtask != null &&
        currentTask.selectedPointIndex == null) {
      _removeTask();
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

    // Is there a new preview from the server?
    _checkForNewPreview();

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
/************************************Point information****************************************************************/
              if (lasso.selectedPointIndex != null ||
                  currentTask.selectedPointIndex != null)
                Positioned(
                  left: _checkPointInformationPosition().dx * zoomPan.scale +
                      zoomPan.offset.dx, // -
                  //75,
                  top: _checkPointInformationPosition().dy * zoomPan.scale +
                      zoomPan.offset.dy, // -
                  //160,
                  child: PointInformation(
                    task: currentTask,
                    lasso: lasso,
                    currentMap: widget.server.currentMap,
                    insertPointActive: false,
                    onRemovePoint: _removePoint,
                    onAddPointActivate: () {},
                    selectTaskOrPointInformation: _selectTaskOrPointInformation,
                    movePointInformation: _movePointInformation,
                  ),
                ),
/************************************Task information****************************************************************/
              if (currentTask.centroids.isNotEmpty &&
                  currentTask.active &&
                  lasso.selectedPointIndex == null &&
                  currentTask.selectedPointIndex == null)
                ...currentTask.centroids.entries.expand((entry) {
                  int currentSubtaskNrUi = 0;
                  return entry.value.map((position) {
                    currentSubtaskNrUi++;
                    return Positioned(
                      left: position.dx * zoomPan.scale + zoomPan.offset.dx,
                      top: position.dy * zoomPan.scale + zoomPan.offset.dy,
                      child: TaskInformation(
                        taskName: entry.key,
                        subtaskNrUi: currentSubtaskNrUi,
                        onRemoveTaskPressed: _removeTaskByButton,
                        onEditTaskMowParametersPressed:
                            _openTaskMowParametersOverlay,
                        selectTaskOrPointInformation:
                            _selectTaskOrPointInformation,
                        moveTaskInformation: _moveTaskInformation,
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
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          CommandButton(
                            icon: BootstrapIcons.plus,
                            onPressed: _addTask,
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
                          taskHistory.addNewProgress(currentTask);
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
/*****************************************Butons on top*********************************************/
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
                                  currentTask =
                                      taskHistory.prevProgress().copy();
                                  currentTask.scale(
                                      screenSize, widget.server.currentMap);
                                  widget.server.robot.mapsScalePosition(
                                      screenSize, widget.server.maps);
                                  currentTask.unselectAll();
                                  setState(() {});
                                }),
                            CustomizedElevatedIconButton(
                              icon: Icons.zoom_in_map,
                              isActive: false,
                              onPressed: () {
                                lasso.active = false;
                                zoomPan.offset = Offset.zero;
                                zoomPan.scale = 1.0;
                                setState(() {});
                              },
                            ),
                            CustomizedElevatedIconButton(
                              icon: Icons.redo,
                              isActive: false,
                              onPressed: () {
                                currentTask = taskHistory.nextProgress().copy();
                                currentTask.scale(
                                    screenSize, widget.server.currentMap);
                                widget.server.robot.mapsScalePosition(
                                    screenSize, widget.server.maps);
                                currentTask.unselectAll();
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
        },
      ),
    );
  }
}
