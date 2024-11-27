import 'package:flutter/material.dart';
import 'package:polybool/polybool.dart';

import 'package:cassandra_native/models/maps.dart';
import 'package:cassandra_native/components/logic/map_logic.dart';
import 'package:cassandra_native/utils/custom_shape_calcs.dart';

class ShapesHistory {
  List<Shapes> progress = [];
  int? currentIdx;

  void reset() {
    progress = [];
    currentIdx = null;
  }

  void addNewProgress(Shapes shapeLogic) {
    if (progress.isNotEmpty) {
      currentIdx = currentIdx! + 1;
      progress = progress.sublist(0, currentIdx!);
      progress.add(shapeLogic.copy());
    } else {
      progress.add(shapeLogic.copy());
      currentIdx = 0;
    }
  }

  Shapes prevProgress() {
    if (currentIdx! > 0) {
      currentIdx = currentIdx! - 1;
    }
    return progress[currentIdx!];
  }

  Shapes nextProgress() {
    if (currentIdx! < progress.length - 1) {
      currentIdx = currentIdx! + 1;
    }
    return progress[currentIdx!];
  }
}

class Shapes {
  Shapes({
    this.active = false,
    List<Offset>? selectionPoints,
    this.selectedPointIndex,
    this.selectedExclusionIndex,
    this.selectedPointCoords,
    this.selectedPointCoordsStart,
    List<Offset>? perimeter,
    List<Offset>? perimeterCartesian,
    List<List<Offset>>? exclusions,
    List<List<Offset>>? exclusionsCartesian,
    List<Offset>? dockPath,
    List<Offset>? dockPathCartesian,
    List<Offset>? searchWire,
    List<Offset>? searchWireCartesian,
    this.selected = false,
    this.selectedShape,
    this.lastPosition,
  })  : selectionPoints = selectionPoints ?? [],
        perimeter = perimeter ?? [],
        perimeterCartesian = perimeterCartesian ?? [],
        exclusions = exclusions ?? [],
        exclusionsCartesian = exclusionsCartesian ?? [],
        dockPath = dockPath ?? [],
        dockPathCartesian = dockPathCartesian ?? [],
        searchWire = searchWire ?? [],
        searchWireCartesian = searchWireCartesian ?? [];

  bool active;
  List<Offset> selectionPoints;
  int? selectedPointIndex;
  int? selectedExclusionIndex;
  Offset? selectedPointCoords;
  Offset? selectedPointCoordsStart;
  List<Offset> perimeter;
  List<Offset> perimeterCartesian;
  List<List<Offset>> exclusions;
  List<List<Offset>> exclusionsCartesian;
  List<Offset> dockPath;
  List<Offset> dockPathCartesian;
  List<Offset> searchWire;
  List<Offset> searchWireCartesian;
  bool selected;
  String? selectedShape;
  Offset? lastPosition;

  Shapes copy() {
    List<List<Offset>> tmpExclusions = [];
    List<List<Offset>> tmpExclusionsCartesian = [];
    for (var exclusion in exclusions) {
      tmpExclusions.add(List.of(exclusion));
    }
    for (var exclusion in exclusionsCartesian) {
      tmpExclusionsCartesian.add(List.of(exclusion));
    }
    Shapes shapeLogicCopy = Shapes(
      active: active,
      selectionPoints: selectionPoints,
      selectedPointIndex: selectedPointIndex,
      selectedExclusionIndex: selectedExclusionIndex,
      selectedPointCoords: selectedPointCoords,
      selectedPointCoordsStart: selectedPointCoordsStart,
      perimeter: List.of(perimeter),
      perimeterCartesian: List.of(perimeterCartesian),
      exclusions: tmpExclusions,
      exclusionsCartesian: tmpExclusionsCartesian,
      dockPath: List.of(dockPath),
      dockPathCartesian: List.of(dockPathCartesian),
      searchWire: List.of(searchWire),
      searchWireCartesian: List.of(searchWireCartesian),
      selected: selected,
      selectedShape: selectedShape,
      lastPosition: lastPosition,
    );
    return shapeLogicCopy;
  }

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
    selectedPointCoords = null;
    selectedPointCoordsStart = null;
    selected = false;
    selectedShape = null;
    lastPosition = null;
  }

  void fromMap(Maps selectedMap) {
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

  void selectPoint(LongPressStartDetails details, ZoomPanLogic zoomPan) {
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
        selectedPointCoords = perimeter[i];
        selectedPointCoordsStart = perimeter[i];
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
          selectedPointCoords = exclusions[k][i];
          selectedPointCoordsStart = exclusions[k][i];
        }
      }
    }
    for (int i = 0; i < dockPath.length; i++) {
      if ((dockPath[i] - scaledAndMovedCoords).distance < minDistance &&
          (dockPath[i] - scaledAndMovedCoords).distance < currentDistance) {
        currentDistance = (dockPath[i] - scaledAndMovedCoords).distance;
        selectedShape = 'dockPath';
        selectedPointIndex = i;
        selectedPointCoords = dockPath[i];
        selectedPointCoordsStart = dockPath[i];
      }
    }
    for (int i = 0; i < searchWire.length; i++) {
      if ((searchWire[i] - scaledAndMovedCoords).distance < minDistance &&
          (searchWire[i] - scaledAndMovedCoords).distance < currentDistance) {
        currentDistance = (searchWire[i] - scaledAndMovedCoords).distance;
        selectedShape = 'searchWire';
        selectedPointIndex = i;
        selectedPointCoords = searchWire[i];
        selectedPointCoordsStart = searchWire[i];
      }
    }
    if (selectedPointIndex == null) {
      selectShape(details, zoomPan);
    }
  }

  void selectShape(LongPressStartDetails details, ZoomPanLogic zoomPan) {
    final Offset scaledAndMovedCoords =
        (details.localPosition - zoomPan.offset) / zoomPan.scale;
    for (int i = 0; i < exclusions.length; i++) {
      if (isPointInsidePolygon(scaledAndMovedCoords, exclusions[i])) {
        selected = true;
        selectedShape = 'exclusion';
        selectedExclusionIndex = i;
        lastPosition = scaledAndMovedCoords;
        return;
      }
    }
    if (isPointInsidePolygon(scaledAndMovedCoords, perimeter)) {
      selected = true;
      selectedShape = 'perimeter';
      lastPosition = scaledAndMovedCoords;
    }
  }

  void move(
      LongPressMoveUpdateDetails details, ZoomPanLogic zoomPan) {
    if (selectedPointIndex != null) {
      _moveSelectedPoint(details, zoomPan);
    } else if (selected) {
      _moveShape(details, zoomPan);
    }
  }

  void toCartesian(Maps maps) {
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

  void unselectAll() {
    selectedPointIndex = null;
    selectedExclusionIndex = null;
    selectedPointCoords = null;
    selectedPointCoordsStart = null;
    selected = false;
    selectedShape = null;
  }

  void removePoint() {
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
      unselectAll();
    }
  }

  void scale(Size screenSize, Maps maps) {
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

  Map<String, dynamic> toGeoJson(String name) {
    List<dynamic> features = [];
    Map<String, dynamic> mapJson = {};
    if (perimeterCartesian.isNotEmpty) {
      final nameFeature = {
        'type': 'Feature',
        'properties': {'name': name}
      };
      features.add(nameFeature);
      var perimeterFeature = {
        'type': 'Feature',
        'properties': {'name': 'perimeter'},
        'geometry': {
          'type': 'Polygon',
          'coordinates': perimeterCartesian.map((p) => [p.dx, p.dy]).toList(),
        }
      };
      features.add(perimeterFeature);
      if (exclusionsCartesian.isNotEmpty) {
        for (var exclusion in exclusionsCartesian) {
          var exclusionsFeature = {
            'type': 'Feature',
            'properties': {'name': 'exclusion'},
            'geometry': {
              'type': 'Polygon',
              'coordinates': exclusion.map((p) => [p.dx, p.dy]).toList(),
            }
          };
          features.add(exclusionsFeature);
        }
      }
      if (dockPathCartesian.isNotEmpty) {
        var dockPathFeature = {
          'type': 'Feature',
          'properties': {'name': 'dockPath'},
          'geometry': {
            'type': 'LineString',
            'coordinates': dockPathCartesian.map((p) => [p.dx, p.dy]).toList(),
          }
        };
        features.add(dockPathFeature);
      }
      if (searchWireCartesian.isNotEmpty) {
        var searchWireFeature = {
          'type': 'Feature',
          'properties': {'name': 'searchWire'},
          'geometry': {
            'type': 'LineString',
            'coordinates':
                searchWireCartesian.map((p) => [p.dx, p.dy]).toList(),
          }
        };
        features.add(searchWireFeature);
      }
      mapJson = {'type': 'FeatureCollection', 'features': features};
    }
    return mapJson;
  }

  void _moveSelectedPoint(
      LongPressMoveUpdateDetails details, ZoomPanLogic zoomPan) {
    final Offset scaledAndMovedCoords =
        (details.localPosition - zoomPan.offset) / zoomPan.scale;
    if (selectedShape == 'perimeter') {
      if (selectedPointIndex! == 0 ||
          selectedPointIndex == perimeter.length - 1) {
        perimeter.first = scaledAndMovedCoords;
        perimeter.last = scaledAndMovedCoords;
        selectedPointCoords = scaledAndMovedCoords;
      } else {
        perimeter[selectedPointIndex!] = scaledAndMovedCoords;
        selectedPointCoords = scaledAndMovedCoords;
      }
    } else if (selectedShape == 'exclusion') {
      if (selectedPointIndex! == 0 ||
          selectedPointIndex! ==
              exclusions[selectedExclusionIndex!].length - 1) {
        exclusions[selectedExclusionIndex!].first = scaledAndMovedCoords;
        exclusions[selectedExclusionIndex!].last = scaledAndMovedCoords;
        selectedPointCoords = scaledAndMovedCoords;
      } else {
        exclusions[selectedExclusionIndex!][selectedPointIndex!] =
            scaledAndMovedCoords;
        selectedPointCoords = scaledAndMovedCoords;
      }
    } else if (selectedShape == 'dockPath') {
      dockPath[selectedPointIndex!] = scaledAndMovedCoords;
      selectedPointCoords = scaledAndMovedCoords;
    } else if (selectedShape == 'searchWire') {
      searchWire[selectedPointIndex!] = scaledAndMovedCoords;
      selectedPointCoords = scaledAndMovedCoords;
    }
  }

  void _moveShape(LongPressMoveUpdateDetails details, ZoomPanLogic zoomPan) {
    final Offset scaledAndMovedCoords =
        (details.localPosition - zoomPan.offset) / zoomPan.scale;
    final Offset delta = scaledAndMovedCoords - lastPosition!;
    if (selectedShape == 'perimeter') {
      perimeter = perimeter.map((point) => point + delta).toList();
      selectionPoints = selectionPoints.map((point) => point + delta).toList();
      lastPosition = scaledAndMovedCoords;
    } else if (selectedShape == 'exclusion' && selectedExclusionIndex != null) {
      exclusions[selectedExclusionIndex!] = exclusions[selectedExclusionIndex!]
          .map((point) => point + delta)
          .toList();
      lastPosition = scaledAndMovedCoords;
    }
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
    if (shapeType == 'polygon' &&
        shape.length > 2 &&
        !hasSelfIntersections(shape)) {
      if (perimeter.isEmpty) {
        shape.add(shape.first);
        perimeter = List.of(shape);
      } else if (_intersectShapes([perimeter], [shape]).isNotEmpty) {
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
    if (shapeType == 'polygon' &&
        shape.length > 2 &&
        !hasSelfIntersections(shape)) {
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

  void addPoint(TapDownDetails details, ZoomPanLogic zoomPan) {
    final Offset scaledAndMovedCoords =
        (details.localPosition - zoomPan.offset) / zoomPan.scale;
    if (selectedPointIndex == null || selectedShape == null) return;
    double minDistance = 20 / zoomPan.scale;
    double currentDistance = double.infinity;
    int? insertIndex;
    Offset? newPoint;
    late List<Offset> newShape;
    if (selectedShape == 'perimeter') {
      newShape = perimeter;
    } else if (selectedShape == 'exclusion') {
      newShape = exclusions[selectedExclusionIndex!];
    } else if (selectedShape == 'dockPath') {
      newShape = dockPath;
    } else {
      newShape = searchWire;
    }

    for (int i = 0; i < newShape.length; i++) {
      Offset start = newShape[i];
      Offset end = newShape[(i + 1) % newShape.length];
      Offset closestPoint =
          getClosestPointOnSegment(start, end, scaledAndMovedCoords);
      double distance = (scaledAndMovedCoords - closestPoint).distance;
      if (distance < currentDistance && distance < minDistance) {
        currentDistance = distance;
        insertIndex = i + 1;
        newPoint = closestPoint;
      }
    }
    if (newPoint != null && insertIndex != null) {
      newShape.insert(insertIndex, newPoint);
    }
  }
}
