import 'package:flutter/material.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:polybool/polybool.dart';

import 'package:cassandra_native/models/landscape.dart';
import 'package:cassandra_native/models/maps.dart';
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

class ShapesHistory {
  List<ShapeLogic> progress = [];
}

class ShapeLogic {
  bool active = false;
  List<Offset> selectionPoints = [];
  int? selectedPointIndex;
  int? selectedExclusionIndex;
  List<Offset> perimeter = [];
  List<Offset> perimeterCartesian = [];
  List<List<Offset>> exclusions = [];
  List<List<Offset>> exclusionsCartesian = [];
  List<Offset> dockPath = [];
  List<Offset> dockPathCartesian = [];
  List<Offset> searchWire = [];
  List<Offset> searchWireCartesian = [];
  bool selected = false;
  String? selectedShape;
  Offset? lastPosition;

  void reset() {
    active = false;
    perimeter = [];
    perimeterCartesian = [];
    exclusions = [];
    exclusionsCartesian = [];
    dockPath = [];
    dockPathCartesian = [];
    searchWire = [];
    searchWireCartesian = [];
    selectionPoints = [];
    selectedPointIndex = null;
    selectedExclusionIndex = null;
    selected = false;
    selectedShape = null;
    lastPosition = null;
  }

  void setMap(Maps selectedMap) {
    if (selectedMap.selected != '') {
      perimeter = List.of(selectedMap.scaledPerimeter);
      perimeterCartesian = List.of(selectedMap.perimeter);
      for (var exclusion in selectedMap.scaledExclusions) {
        exclusions.add(List.of(exclusion));
      }
      for (var exclusion in selectedMap.exclusions) {
        exclusionsCartesian.add(List.of(exclusion));
      }
      dockPath = List.of(selectedMap.scaledDockPath);
      dockPathCartesian = List.of(selectedMap.dockPath);
      searchWire = List.of(selectedMap.scaledSearchWire);
      searchWireCartesian = List.of(selectedMap.searchWire);
    }
  }

  void onLongPressedStart(LongPressStartDetails details, ZoomPanLogic zoomPan) {
    double minDistance = 20 / zoomPan.scale;
    double currentDistance = double.infinity;
    final Offset scaledAndMovedCoords =
        (details.localPosition - zoomPan.offset) / zoomPan.scale;
    for (int i = 0; i < perimeter.length; i++) {
      if ((perimeter[i] - scaledAndMovedCoords).distance < minDistance &&
          (perimeter[i] - scaledAndMovedCoords).distance < currentDistance) {
        currentDistance = (perimeter[i] - scaledAndMovedCoords).distance;
        selectedShape = 'perimeter';
        selectedPointIndex = i;
      }
    }
    for (int k = 0; k < exclusions.length; k++) {
      for (int i = 0; i < exclusions[k].length; i++) {
        if ((exclusions[k][i] - scaledAndMovedCoords).distance < minDistance &&
            (exclusions[k][i] - scaledAndMovedCoords).distance <
                currentDistance) {
          currentDistance = (exclusions[k][i] - scaledAndMovedCoords).distance;
          selectedShape = 'exclusion';
          selectedExclusionIndex = k;
          selectedPointIndex = i;
        }
      }
    }
    for (int i = 0; i < dockPath.length; i++) {
      if ((dockPath[i] - scaledAndMovedCoords).distance < minDistance &&
          (dockPath[i] - scaledAndMovedCoords).distance < currentDistance) {
        currentDistance = (dockPath[i] - scaledAndMovedCoords).distance;
        selectedShape = 'dockPath';
        selectedPointIndex = i;
      }
    }
    for (int i = 0; i < searchWire.length; i++) {
      if ((searchWire[i] - scaledAndMovedCoords).distance < minDistance &&
          (searchWire[i] - scaledAndMovedCoords).distance < currentDistance) {
        currentDistance = (searchWire[i] - scaledAndMovedCoords).distance;
        selectedShape = 'searchWire';
        selectedPointIndex = i;
      }
    }
    if (isPointInsidePolygon(scaledAndMovedCoords, perimeter) &&
        selectedPointIndex == null) {
      selected = true;
      selectedShape = 'perimeter';
      lastPosition = scaledAndMovedCoords;
    }
  }

  void onLongPressedMoveUpdate(
      LongPressMoveUpdateDetails details, ZoomPanLogic zoomPan) {
    if (selectedPointIndex != null) {
      _moveSelectedPoint(details, zoomPan);
    } else if (selected) {
      _moveShape(details, zoomPan);
    }
  }

  void onLongPressedEnd(Maps maps) {
    if (perimeter.isNotEmpty) {
      perimeterCartesian = _canvasCoordsToCartesian(perimeter, maps);
    }
    if (exclusions.isNotEmpty) {
      exclusionsCartesian = [];
      for (var exclusion in exclusions) {
        exclusionsCartesian.add(_canvasCoordsToCartesian(exclusion, maps));
      }
    }
    if (dockPath.isNotEmpty) {
      dockPathCartesian = _canvasCoordsToCartesian(dockPath, maps);
    }
    if (searchWire.isNotEmpty) {
      searchWireCartesian = _canvasCoordsToCartesian(searchWire, maps);
    }
  }

  void onTap() {
    selectedPointIndex = null;
    selectedExclusionIndex = null;
    selected = false;
    selectedShape = null;
  }

  void onDoubleTap() {
    if (selectedPointIndex != null) {
      if (selectedShape == 'perimeter' && perimeter.length > 4) {
        _removePerimeterPoint();
      }
      if (selectedShape == 'exclusion' &&
          exclusions[selectedExclusionIndex!].length > 4) {
        _removeExclusionPoint();
      }
      if (selectedShape == 'dockPath' && dockPath.length > 2) {
        dockPath.removeAt(selectedPointIndex!);
      }
      if (selectedShape == 'searchWire' && searchWire.length > 2) {
        searchWire.removeAt(selectedPointIndex!);
      }
      onTap();
    }
  }

  void scaleShapes(Size screenSize, Maps maps) {
    perimeter = perimeterCartesian
        .map((p) => Offset(p.dx - maps.minX, -(p.dy - maps.minY)))
        .toList();
    perimeter = perimeter
        .map((p) => Offset(p.dx * maps.mapScale, p.dy * maps.mapScale))
        .toList();
    perimeter = perimeter
        .map((p) => Offset(p.dx + maps.offsetX, p.dy + maps.offsetY))
        .toList();

    exclusions = exclusionsCartesian
        .map((shape) => shape
            .map((p) => Offset(p.dx - maps.minX, -(p.dy - maps.minY)))
            .toList())
        .toList();
    exclusions = exclusions
        .map((shape) => shape
            .map((p) => Offset(p.dx * maps.mapScale, p.dy * maps.mapScale))
            .toList())
        .toList();
    exclusions = exclusions
        .map((shape) => shape
            .map((p) => Offset(p.dx + maps.offsetX, p.dy + maps.offsetY))
            .toList())
        .toList();

    dockPath = dockPathCartesian
        .map((p) => Offset(p.dx - maps.minX, -(p.dy - maps.minY)))
        .toList();
    dockPath = dockPath
        .map((p) => Offset(p.dx * maps.mapScale, p.dy * maps.mapScale))
        .toList();
    dockPath = dockPath
        .map((p) => Offset(p.dx + maps.offsetX, p.dy + maps.offsetY))
        .toList();

    searchWire = searchWireCartesian
        .map((p) => Offset(p.dx - maps.minX, -(p.dy - maps.minY)))
        .toList();
    searchWire = searchWire
        .map((p) => Offset(p.dx * maps.mapScale, p.dy * maps.mapScale))
        .toList();
    searchWire = searchWire
        .map((p) => Offset(p.dx + maps.offsetX, p.dy + maps.offsetY))
        .toList();
  }

  void _moveSelectedPoint(
      LongPressMoveUpdateDetails details, ZoomPanLogic zoomPan) {
    final Offset scaledAndMovedCoords =
        (details.localPosition - zoomPan.offset) / zoomPan.scale;
    if (selectedShape == 'perimeter') {
      perimeter[selectedPointIndex!] = scaledAndMovedCoords;
    } else if (selectedShape == 'exclusion') {
      exclusions[selectedExclusionIndex!][selectedPointIndex!] =
          scaledAndMovedCoords;
    } else if (selectedShape == 'dockPath') {
      dockPath[selectedPointIndex!] = scaledAndMovedCoords;
    } else if (selectedShape == 'searchWire') {
      searchWire[selectedPointIndex!] = scaledAndMovedCoords;
    }
  }

  void _moveShape(LongPressMoveUpdateDetails details, ZoomPanLogic zoomPan) {
    final Offset scaledAndMovedCoords =
        (details.localPosition - zoomPan.offset) / zoomPan.scale;
    final Offset delta = scaledAndMovedCoords - lastPosition!;
    perimeter = perimeter.map((point) => point + delta).toList();
    selectionPoints = selectionPoints.map((point) => point + delta).toList();
    lastPosition = scaledAndMovedCoords;
  }

  List<Offset> _canvasCoordsToCartesian(List<Offset> shape, Maps maps) {
    shape = shape
        .map((p) => Offset(p.dx - maps.offsetX, p.dy - maps.offsetY))
        .toList();
    shape = shape
        .map((p) => Offset(p.dx / maps.mapScale, p.dy / maps.mapScale))
        .toList();
    shape =
        shape.map((p) => Offset(p.dx + maps.minX, -p.dy + maps.minY)).toList();
    return shape;
  }

  void _removePerimeterPoint() {
    if (selectedPointIndex == 0) {
      perimeter.removeAt(selectedPointIndex!);
      perimeter.removeAt(perimeter.length - 1);
      perimeter.add(perimeter[0]);
    } else {
      perimeter.removeAt(selectedPointIndex!);
    }
  }

  void _removeExclusionPoint() {
    if (selectedPointIndex == 0) {
      exclusions[selectedExclusionIndex!].removeAt(selectedPointIndex!);
      exclusions[selectedExclusionIndex!]
          .removeAt(exclusions[selectedExclusionIndex!].length - 1);
      exclusions[selectedExclusionIndex!]
          .add(exclusions[selectedExclusionIndex!][0]);
    } else {
      exclusions[selectedExclusionIndex!].removeAt(selectedPointIndex!);
    }
  }

  void addShape(List<Offset> shape, String shapeType) {
    if (shapeType == 'polygon' && shape.length > 2 && !hasSelfIntersections(shape)) {
      if (perimeter.isEmpty) {
        shape.add(shape.first);
        perimeter = List.of(shape);
      } else if (_intersectShapes([perimeter], [shape]).isNotEmpty){
        exclusions = _differenceShapes([shape], exclusions);
        perimeter = _unionShapes([shape], [perimeter])[0];
      }
    } else if (shapeType == 'dockPath') {
      if (perimeter.isNotEmpty) dockPath.addAll(shape);
    } else if (shapeType == 'searchWire') {
      if (perimeter.isNotEmpty) searchWire.addAll(shape);
    }
  }

  void removeShape(List<Offset> shape, String shapeType) {
    if (shapeType == 'polygon' && shape.length > 2 && !hasSelfIntersections(shape)) {
      if (perimeter.isEmpty) {
        return;
      } else if (exclusions.isEmpty) {
        shape.add(shape.first);
        exclusions.add(shape);
      } else {
        exclusions = _unionShapes([shape], exclusions);
        final newShapes = _differenceShapes(exclusions, [perimeter]);
        perimeter = newShapes.last;
        exclusions = newShapes.sublist(0, newShapes.length - 1);
      }
    }
  }

  List<List<Offset>> _unionShapes(
      List<List<Offset>> shapesToAdd, List<List<Offset>> shapes) {
    List<List<Offset>> newShapes = [];
    Polygon uniedPolygons = Polygon(
            regions: shapes
                .map((shape) => _listOffsetToListCoordinate(shape))
                .toList())
        .union(Polygon(
            regions: shapesToAdd
                .map((shape) => _listOffsetToListCoordinate(shape))
                .toList()));
    newShapes = uniedPolygons.regions.map((shape) {
      final closedPolygon = _listCoordinateToListOffset(shape);
      closedPolygon.add(closedPolygon.first);
      return closedPolygon;
    }).toList();
    return newShapes;
  }

  List<List<Offset>> _differenceShapes(
      List<List<Offset>> shapesToSub, List<List<Offset>> shapes) {
    List<List<Offset>> newShapes = [];
    Polygon differencedPolygon = Polygon(
            regions: shapes
                .map((shape) => _listOffsetToListCoordinate(shape))
                .toList())
        .difference(Polygon(
            regions: shapesToSub
                .map((shape) => _listOffsetToListCoordinate(shape))
                .toList()));
    newShapes = differencedPolygon.regions.map((shape) {
      final closedPolygon = _listCoordinateToListOffset(shape);
      closedPolygon.add(closedPolygon.first);
      return closedPolygon;
    }).toList();
    return newShapes;
  }

  List<List<Offset>> _intersectShapes(
      List<List<Offset>> shapesToIntersect, List<List<Offset>> shapes) {
    List<List<Offset>> newShapes = [];
    Polygon intersectedPolygon = Polygon(
            regions: shapesToIntersect
                .map((shape) => _listOffsetToListCoordinate(shape))
                .toList())
        .intersect(Polygon(
            regions: shapes
                .map((shape) => _listOffsetToListCoordinate(shape))
                .toList()));
    newShapes = intersectedPolygon.regions.map((shape) {
      final closedPolygon = _listCoordinateToListOffset(shape);
      closedPolygon.add(closedPolygon.first);
      return closedPolygon;
    }).toList();
    return newShapes;
  }

  List<Coordinate> _listOffsetToListCoordinate(List<Offset> coords) {
    return coords.map((p) => Coordinate(p.dx, p.dy)).toList();
  }

  List<Offset> _listCoordinateToListOffset(List<Coordinate> coords) {
    return coords.map((p) => Offset(p.x, p.y)).toList();
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

  void onTap() {
    selectedPointIndex = null;
    selected = false;
  }

  void onDoubleTap() {
    if (selectedPointIndex != null && selection.length > 3) {
      selection.removeAt(selectedPointIndex!);
      onTap();
    }
  }

  void onScaleEnd(ZoomPanLogic zoomPan) {
    active = false;
    selection = simplifyPath(selection, 2.0 / zoomPan.scale);
    selectionPoints = selection;
  }

  void onLongPressedEnd() {
    // selectedPointIndex = null;
    selected = false;
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
