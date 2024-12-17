import 'package:flutter/material.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';

import 'package:cassandra_native/components/logic/shapes_logic.dart';
import 'package:cassandra_native/components/logic/lasso_logic.dart';
import 'package:cassandra_native/components/common/customized_elevated_icon_button.dart';
import 'package:cassandra_native/models/maps.dart';

class PointInformation extends StatelessWidget {
  final Shapes shapes;
  final LassoLogic lasso;
  final Maps maps;
  final bool insertPointActive;
  final VoidCallback onRemovePoint;
  final VoidCallback onAddPointActivate;
  final VoidCallback onRemoveShape;
  const PointInformation({
    super.key,
    required this.shapes,
    required this.lasso,
    required this.maps,
    required this.insertPointActive,
    required this.onRemovePoint,
    required this.onAddPointActivate,
    required this.onRemoveShape,
  });

  @override
  Widget build(BuildContext context) {
    String selectedShape = '';
    if (lasso.selectedPointCoords != null) {
      selectedShape = 'lasso';
    } else if (shapes.selectedShape == 'dockPath') {
      selectedShape = 'dock path';
    } else if (shapes.selectedShape == 'searchWire') {
      selectedShape = 'search wire';
    } else {
      selectedShape = shapes.selectedShape!;
    }
    final selectedPointCoords = lasso.selection.isNotEmpty
        ? lasso.selectedPointCoords
        : shapes.selectedPointCoords!;
    final selectedPointCoordsStart = lasso.selection.isNotEmpty
        ? lasso.selectedPointCoordsStart
        : shapes.selectedPointCoordsStart;

    final Offset cartesianCoords = Offset(
        ((selectedPointCoords!.dx - maps.offsetX) / maps.mapScale) + maps.minX,
        -(selectedPointCoords.dy - maps.offsetY) / maps.mapScale + maps.minY);

    final Offset cartesianCoordsStart = Offset(
        ((selectedPointCoordsStart!.dx - maps.offsetX) / maps.mapScale) +
            maps.minX,
        -(selectedPointCoordsStart.dy - maps.offsetY) / maps.mapScale +
            maps.minY);
    final double distance = (cartesianCoords - cartesianCoordsStart).distance;

    return Container(
      padding: EdgeInsets.all(5),
      width: 180,
      decoration: BoxDecoration(
        color: Colors.transparent,
        // color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            selectedShape,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            'x: ${cartesianCoords.dx.toStringAsFixed(2)} (${cartesianCoordsStart.dx.toStringAsFixed(2)})\ny: ${cartesianCoords.dy.toStringAsFixed(2)} (${cartesianCoordsStart.dy.toStringAsFixed(2)})\ndistance: ${distance.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          SizedBox(
            height: 4,
          ),
          // Text(
          //   'distance: ${distance.toStringAsFixed(2)}',
          //   style: Theme.of(context).textTheme.bodySmall,
          // ),
          // Text(
          //   '${shapes.selectedShape} idx: ${shapes.selectedPointIndex}',
          //   style: Theme.of(context).textTheme.bodySmall,
          // ),
          SizedBox(
            height: 4,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              CustomizedElevatedIconButton(
                icon: BootstrapIcons.node_plus,
                isActive: insertPointActive,
                onPressed: onAddPointActivate,
              ),
              CustomizedElevatedIconButton(
                icon: BootstrapIcons.trash,
                isActive: false,
                onPressed: onRemoveShape,
              ),
              CustomizedElevatedIconButton(
                icon: BootstrapIcons.node_minus,
                isActive: false,
                onPressed: onRemovePoint,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
