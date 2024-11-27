import 'package:flutter/material.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';

import 'package:cassandra_native/models/landscape.dart';
import 'package:cassandra_native/utils/custom_shape_calcs.dart';

class ZoomPanLogic {
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

class RecorderLogic {
  bool recording = false;
  String selectedShape = 'polygon';
  List<Offset> coordinates = [];
  IconData recordButtonIcon = BootstrapIcons.record_fill;

  void onLongPress() {
    recording = true;
    recordButtonIcon = Icons.pause;
  }

  void onPress() {
    if (recording) {
      recording = false;
      recordButtonIcon = BootstrapIcons.record_fill;
    } else {}
  }

  void onRecordingNewCoordianates(Offset newCoord) {
    if (coordinates.isEmpty ||
        newCoord != coordinates[coordinates.length - 1]) {
      coordinates.add(newCoord);
    }
  }
}

class MapPointLogic {
  bool active = false;
  bool selected = false;
  Offset? coords;

  void reset() {
    active = false;
    selected = false;
    coords = null;
  }

  void setCoords(
      TapDownDetails details, ZoomPanLogic zoomPan, Landscape currentMap) {
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

  void onLongPressedStart(LongPressStartDetails details, ZoomPanLogic zoomPan) {
    double minDistance = 20 / zoomPan.scale;
    final Offset scaledAndMovedCoords =
        (details.localPosition - zoomPan.offset) / zoomPan.scale;
    if (coords != null &&
        (coords! - scaledAndMovedCoords).distance < minDistance) {
      selected = true;
    }
  }

  void onLongPressedMoveUpdate(
      LongPressMoveUpdateDetails details, ZoomPanLogic zoomPan) {
    if (selected) {
      _moveSelectedPoint(details, zoomPan);
    }
  }

  void onDoubleTap() {
    coords = null;
  }

  void _moveSelectedPoint(
      LongPressMoveUpdateDetails details, ZoomPanLogic zoomPan) {
    final Offset scaledAndMovedCoords =
        (details.localPosition - zoomPan.offset) / zoomPan.scale;
    coords = scaledAndMovedCoords;
  }

  void onLongPressedEnd(Landscape currentMap) {
    selected = false;
    if (!isPointInsidePolygon(coords!, currentMap.scaledPerimeter)) {
      coords = null;
      return;
    }
    for (List<Offset> exclusion in currentMap.scaledExclusions) {
      if (isPointInsidePolygon(coords!, exclusion)) {
        coords = null;
        return;
      }
    }
  }
}

class MapRobotLogic {
  bool focusOnMowerActive = false;
}
