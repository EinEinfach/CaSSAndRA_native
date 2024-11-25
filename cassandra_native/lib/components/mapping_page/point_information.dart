import 'package:flutter/material.dart';

import 'package:cassandra_native/components/logic/map_logic.dart';
import 'package:cassandra_native/models/maps.dart';

class PointInformation extends StatelessWidget {
  final ShapeLogic shapeLogic;
  final Maps maps;
  const PointInformation({
    super.key,
    required this.shapeLogic,
    required this.maps,
  });

  @override
  Widget build(BuildContext context) {
    final Offset cartesianCoords = Offset(
        ((shapeLogic.selectedPointCoords!.dx - maps.offsetX) / maps.mapScale) +
            maps.minX,
        -(shapeLogic.selectedPointCoords!.dy - maps.offsetY) / maps.mapScale +
            maps.minY);
    final Offset cartesianCoordsStart = Offset(
        ((shapeLogic.selectedPointCoordsStart!.dx - maps.offsetX) /
                maps.mapScale) +
            maps.minX,
        -(shapeLogic.selectedPointCoordsStart!.dy - maps.offsetY) /
                maps.mapScale +
            maps.minY);
    final double distance = (cartesianCoords - cartesianCoordsStart).distance;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'start x: ${cartesianCoordsStart.dx.toStringAsFixed(2)} y: ${cartesianCoordsStart.dy.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'end x: ${cartesianCoords.dx.toStringAsFixed(2)} y: ${cartesianCoords.dy.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'distance: ${distance.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
