import 'package:flutter/material.dart';

import 'package:cassandra_native/models/landscape.dart';
import 'package:cassandra_native/utils/custom_shape_calcs.dart';

class ZoomPan {
  Offset offset = Offset.zero;
  double scale = 1.0;
  double previousScale = 1.0;
  Offset focalPoint = Offset.zero;
  Offset initialFocalPoint = Offset.zero;

  void focusOnPoint(Offset point, Size screenSize) {
    offset = Offset(screenSize.width / 2 - point.dx * scale,
        screenSize.height / 2 - point.dy * scale);
  }
}

class Lasso {
  bool active = false;
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

  void onScreenSizeChanged(Landscape currentMap) {
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

  void onLongPressedStart(LongPressStartDetails details, ZoomPan zoomPan) {
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
    if (isPointInsidePolygon(scaledAndMovedCoords, selection) &&
        selectedPointIndex == null) {
      selected = true;
      lastPosition = scaledAndMovedCoords;
    }
  }

  void onLongPressedMoveUpdate(
      LongPressMoveUpdateDetails details, ZoomPan zoomPan) {
    if (selectedPointIndex != null) {
      _moveSelectedPoint(details, zoomPan);
    } else if (selected) {
      _moveLasso(details, zoomPan);
    }
  }

  void onLongPressedEnd() {
    selectedPointIndex = null;
    selected = false;
  }

  void _moveSelectedPoint(LongPressMoveUpdateDetails details, ZoomPan zoomPan) {
    final Offset scaledAndMovedCoords =
        (details.localPosition - zoomPan.offset) / zoomPan.scale;
    selection[selectedPointIndex!] = scaledAndMovedCoords;
    selectionPoints[selectedPointIndex!] = scaledAndMovedCoords;
  }

  void _moveLasso(LongPressMoveUpdateDetails details, ZoomPan zoomPan) {
    final Offset scaledAndMovedCoords =
        (details.localPosition - zoomPan.offset) / zoomPan.scale;
    final Offset delta = scaledAndMovedCoords - lastPosition!;
    selection = selection.map((point) => point + delta).toList();
    selectionPoints = selectionPoints.map((point) => point + delta).toList();
    lastPosition = scaledAndMovedCoords;
  }
}

class MapPoint {
  Offset? coords;

  void reset() {
    coords = null;
  }

  void setCoords(
      TapDownDetails details, ZoomPan zoomPan, Landscape currentMap) {
    final scaledAndMovedCoords =
        (details.localPosition - zoomPan.offset) / zoomPan.scale;
    if (isPointInsidePolygon(
        scaledAndMovedCoords, currentMap.scaledPerimeter)) {
      for (List<Offset> exclusion in currentMap.scaledExclusions) {
        if (isPointInsidePolygon(scaledAndMovedCoords, exclusion)) {
          return;
        }
      }
      coords = scaledAndMovedCoords;
    }
  }

  void onScreenSizeChanged(Landscape currentMap) {
    if (currentMap.perimeter.isNotEmpty &&
        coords != null &&
        currentMap.gotoPoint != null) {
      coords = Offset(
          (currentMap.gotoPoint!.dx - currentMap.minX) * currentMap.mapScale +
              currentMap.offsetX,
          -(currentMap.gotoPoint!.dy - currentMap.minY) * currentMap.mapScale +
              currentMap.offsetY);
    }
  }
}
