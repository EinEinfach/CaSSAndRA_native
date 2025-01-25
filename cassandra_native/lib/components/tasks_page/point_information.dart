import 'package:flutter/material.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';

import 'package:cassandra_native/components/logic/tasks_logic.dart';
import 'package:cassandra_native/components/logic/lasso_logic.dart';
import 'package:cassandra_native/components/common/buttons/customized_elevated_icon_button.dart';
import 'package:cassandra_native/models/landscape.dart';

class PointInformation extends StatelessWidget {
  final Task task;
  final LassoLogic lasso;
  final Landscape currentMap;
  final bool insertPointActive;
  final VoidCallback onRemovePoint;
  final VoidCallback onAddPointActivate;
  final void Function(LongPressStartDetails) selectTaskOrPointInformation;
  final void Function(LongPressMoveUpdateDetails) movePointInformation;

  const PointInformation({
    super.key,
    required this.task,
    required this.lasso,
    required this.currentMap,
    required this.insertPointActive,
    required this.onRemovePoint,
    required this.onAddPointActivate,
    required this.selectTaskOrPointInformation,
    required this.movePointInformation,
  });

  @override
  Widget build(BuildContext context) {
    String selectedTask = '';
    if (lasso.selectedPointCoords != null) {
      selectedTask = 'lasso';
    } else {
      selectedTask = task.selectedTask!;
    }
    final selectedPointCoords = lasso.selection.isNotEmpty
        ? lasso.selectedPointCoords
        : task.selections[task.selectedTask!]![task.selectedSubtask!]
            [task.selectedPointIndex!];
    final selectedPointCoordsStart = lasso.selection.isNotEmpty
        ? lasso.selectedPointCoordsStart
        : task.selectedPointCoordsStart;

    final Offset cartesianCoords = Offset(
        (selectedPointCoords!.dx - currentMap.offsetX) / currentMap.mapScale +
            currentMap.minX,
        -(selectedPointCoords.dy - currentMap.offsetY) / currentMap.mapScale +
            currentMap.minY);

    final Offset cartesianCoordsStart = Offset(
        ((selectedPointCoordsStart!.dx - currentMap.offsetX) /
                currentMap.mapScale) +
            currentMap.minX,
        -((selectedPointCoordsStart.dy - currentMap.offsetY) /
                currentMap.mapScale) +
            currentMap.minY);
    final double distance = (cartesianCoords - cartesianCoordsStart).distance;

    return Container(
        padding: EdgeInsets.all(5),
        width: 180,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              selectedTask,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              'x: ${cartesianCoords.dx.toStringAsFixed(2)} (${cartesianCoordsStart.dx.toStringAsFixed(2)})\ny: ${cartesianCoords.dy.toStringAsFixed(2)} (${cartesianCoordsStart.dy.toStringAsFixed(2)})\ndistance: ${distance.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            SizedBox(
              height: 4,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                GestureDetector(
                  onLongPressStart: (details) =>
                      selectTaskOrPointInformation(details),
                  onLongPressMoveUpdate: (details) =>
                      movePointInformation(details),
                  child: Icon(
                    Icons.drag_indicator,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                CustomizedElevatedIconButton(
                  icon: BootstrapIcons.node_plus,
                  isActive: insertPointActive,
                  onPressed: onAddPointActivate,
                ),
                CustomizedElevatedIconButton(
                  icon: BootstrapIcons.node_minus,
                  isActive: false,
                  onPressed: onRemovePoint,
                ),
              ],
            ),
          ],
        ));
  }
}
