import 'package:flutter/material.dart';

import 'package:cassandra_native/models/server.dart';
import 'package:cassandra_native/models/landscape.dart';
import 'package:cassandra_native/models/robot.dart';
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

class LassoLogic {
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

  void onLongPressedStart(LongPressStartDetails details, ZoomPanLogic zoomPan) {
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
      LongPressMoveUpdateDetails details, ZoomPanLogic zoomPan) {
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

  void _moveSelectedPoint(LongPressMoveUpdateDetails details, ZoomPanLogic zoomPan) {
    final Offset scaledAndMovedCoords =
        (details.localPosition - zoomPan.offset) / zoomPan.scale;
    selection[selectedPointIndex!] = scaledAndMovedCoords;
    selectionPoints[selectedPointIndex!] = scaledAndMovedCoords;
  }

  void _moveLasso(LongPressMoveUpdateDetails details, ZoomPanLogic zoomPan) {
    final Offset scaledAndMovedCoords =
        (details.localPosition - zoomPan.offset) / zoomPan.scale;
    final Offset delta = scaledAndMovedCoords - lastPosition!;
    selection = selection.map((point) => point + delta).toList();
    selectionPoints = selectionPoints.map((point) => point + delta).toList();
    lastPosition = scaledAndMovedCoords;
  }
}

class MapPointLogic {
  bool active = false;
  Offset? coords;

  void reset() {
    active = false;
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
}

class TasksSelectionLogic {
  bool active = false;

  void reset() {
    active = false;
  }
}

class MapUiLogic {
  List<String> statePlayPlayButton = [
    'idle',
    'charging',
    'docked',
    'stop',
    'move',
    'offline'
  ];
  bool focusOnMowerActive = false;
  bool jobActive = false;
  IconData playButtonIcon = Icons.play_arrow;

  void onRobotStatusCheck(Robot robot) {
    if (statePlayPlayButton.contains(robot.status)) {
      jobActive = false;
      playButtonIcon = Icons.play_arrow;
    } else {
      jobActive = true;
      playButtonIcon = Icons.pause;
    }
  }
}

class MapAnimationLogic {
  MapAnimationLogic({required this.robot});
  Robot robot;
  bool get active => _checkAnimationState();
  List<String> statesForAnimation = [
    'mow',
    'transit',
    'docking',
    'move',
  ];
  Offset oldPosition = Offset.zero;
  double oldAngle = 0;
  Offset get newPosition => robot.scaledPosition;
  double get newAngle => robot.angle;
  bool _checkAnimationState() {
    return statesForAnimation.contains(robot.status);
  }
}

class StatusWindowLogic {
  StatusWindowLogic({required this.currentServer});

  Server currentServer;

  String get uiEstimationTime => _calcEstimationTime();
  String get duration => _calcDurataion();
  String get totalSqm => _calcTotalSqm();

  String _calcEstimationTime() {
    Robot robot = currentServer.robot;
    Landscape currentMap = currentServer.currentMap;

    if (robot.status == 'mow' && robot.secondsPerIdx != null && currentMap.scaledMowPath.length > robot.mowPointIdx) {
      final int nowMilliseconds = DateTime.now().millisecondsSinceEpoch;
      final estimatedMilliseconds = nowMilliseconds +
          (currentMap.scaledMowPath.sublist(robot.mowPointIdx).length *
                  (robot.secondsPerIdx! * 1000))
              .toInt();
      DateTime estimatedDateTime =
          DateTime.fromMillisecondsSinceEpoch(estimatedMilliseconds);

      // round to the next 5min
      final int minutesToAdd = 5 - (estimatedDateTime.minute % 5);
      estimatedDateTime = estimatedDateTime.add(
        Duration(minutes: minutesToAdd),
      );
      return '${estimatedDateTime.hour.toString().padLeft(2, '0')}:${estimatedDateTime.minute.toString().padLeft(2, '0')}';
    }
    return '--:--';
  }

  String _calcDurataion() {
    final Robot robot = currentServer.robot;
    final Landscape currentMap = currentServer.currentMap;

    if (robot.status == 'mow' && robot.secondsPerIdx != null && currentMap.scaledMowPath.length > robot.mowPointIdx) {
      final double seconds =
          currentMap.scaledMowPath.length * robot.secondsPerIdx!;
      return (seconds / 3600).toStringAsFixed(1);
    }
    return '-.-';
  }

  String _calcTotalSqm() {
    final Robot robot = currentServer.robot;
    final Landscape currentMap = currentServer.currentMap;
    if (robot.status == 'mow') {
      return '${currentMap.areaTotal.toString()}m\u00B2';
    }
    return '--';
  }
}

