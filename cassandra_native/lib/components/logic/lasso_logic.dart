import 'package:flutter/material.dart';

import 'package:cassandra_native/models/landscape.dart';
import 'package:cassandra_native/components/logic/map_logic.dart';
import 'package:cassandra_native/utils/custom_shape_calcs.dart';

class LassoLogic {
  bool active = false;
  String selectedShape = 'polygon';
  List<Offset> selection = [];
  List<Offset> selectionPoints = [];
  int? selectedPointIndex;
  bool selected = false;
  Offset? lastPosition;

  void reset() {
    active = false;
    selection = [];
    selectionPoints = [];
    selectedPointIndex = null;
    selected = false;
    lastPosition = null;
  }

  void scale(Landscape currentMap) {
    if (currentMap.selectedArea.isNotEmpty) {
      selection = currentMap.selectedArea
          .map((p) => Offset(p.dx - currentMap.minX, -(p.dy - currentMap.minY)))
          .toList();
      selection = selection
          .map((p) =>
              Offset(p.dx * currentMap.mapScale, p.dy * currentMap.mapScale))
          .toList();
      selection = selection
          .map((p) =>
              Offset(p.dx + currentMap.offsetX, p.dy + currentMap.offsetY))
          .toList();
      selectionPoints = selection;
    }
  }

  void selectPoint(LongPressStartDetails details, ZoomPanLogic zoomPan) {
    double minDistance = 20 / zoomPan.scale;
    double currentDistance = double.infinity;
    final Offset scaledAndMovedCoords =
        (details.localPosition - zoomPan.offset) / zoomPan.scale;
    for (int i = 0; i < selection.length; i++) {
      if ((selection[i] - scaledAndMovedCoords).distance < minDistance &&
          (selection[i] - scaledAndMovedCoords).distance < currentDistance) {
        currentDistance = (selection[i] - scaledAndMovedCoords).distance;
        selectedPointIndex = i;
      }
    }
    if (selectedPointIndex == null) {
      selectShape(details, zoomPan);
    }
  }

  void selectShape(LongPressStartDetails details, ZoomPanLogic zoomPan) {
    final Offset scaledAndMovedCoords =
        (details.localPosition - zoomPan.offset) / zoomPan.scale;
    if (isPointInsidePolygon(scaledAndMovedCoords, selection)) {
      selected = true;
      lastPosition = scaledAndMovedCoords;
    }
  }

  void move(
      LongPressMoveUpdateDetails details, ZoomPanLogic zoomPan) {
    if (selectedPointIndex != null) {
      _moveSelectedPoint(details, zoomPan);
    } else if (selected) {
      _moveLasso(details, zoomPan);
    }
  }

  void unselectAll() {
    unselectPoint();
    unselectShape();
  }

  void unselectShape() {
    selected = false;
  }

  void unselectPoint() {
    selectedPointIndex = null;
  }

  void removePoint() {
    if (selectedPointIndex != null && selection.length > 3) {
      selection.removeAt(selectedPointIndex!);
      unselectAll();
    }
  }

  void onScaleEnd(ZoomPanLogic zoomPan) {
    active = false;
    selection = simplifyPath(selection, 2.0 / zoomPan.scale);
    selectionPoints = selection;
  }

  void _moveSelectedPoint(
      LongPressMoveUpdateDetails details, ZoomPanLogic zoomPan) {
    final Offset scaledAndMovedCoords =
        (details.localPosition - zoomPan.offset) / zoomPan.scale;
    selection[selectedPointIndex!] = scaledAndMovedCoords;
    //selectionPoints[selectedPointIndex!] = scaledAndMovedCoords;
  }

  void _moveLasso(LongPressMoveUpdateDetails details, ZoomPanLogic zoomPan) {
    final Offset scaledAndMovedCoords =
        (details.localPosition - zoomPan.offset) / zoomPan.scale;
    final Offset delta = scaledAndMovedCoords - lastPosition!;
    selection = selection.map((point) => point + delta).toList();
    selectionPoints = selection;
    lastPosition = scaledAndMovedCoords;
  }
}
