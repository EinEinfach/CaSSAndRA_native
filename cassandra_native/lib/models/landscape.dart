import 'package:cassandra_native/models/mow_parameters.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:cassandra_native/models/tasks.dart';
import 'package:cassandra_native/models/schedule.dart';

class Landscape {
  String? mapId;
  String? receivedMapId;
  List<Offset> perimeter = [];
  List<Offset> shiftedPerimeter = [];
  List<Offset> scaledPerimeter = [];
  List<List<Offset>> exclusions = [];
  List<List<Offset>> shiftedExclusions = [];
  List<List<Offset>> scaledExclusions = [];
  List<Offset> dockPath = [];
  List<Offset> shiftedDockPath = [];
  List<Offset> scaledDockPath = [];
  List<Offset> searchWire = [];
  List<Offset> shiftedSearchWire = [];
  List<Offset> scaledSearchWire = [];

  String? previewId;
  String? receivedPreviewId;
  List<Offset> preview = [];
  List<Offset> shiftedPreview = [];
  List<Offset> scaledPreview = [];

  String? mowPathId;
  String? receivedMowPathId;
  List<Offset> mowPath = [];
  List<Offset> shiftedMowPath = [];
  List<Offset> scaledMowPath = [];

  String? obstaclesId;
  String? receivedObstaclesId;
  List<List<Offset>> obstacles = [];
  List<List<Offset>> shiftedObstacles = [];
  List<List<Offset>> scaledObstacles = [];

  List<List<Offset>> shapesBouquet = [[]];

  // mow progress
  int idxPercent = 0;
  int distancePercent = 0;

  int areaTotal = 0;
  int finishedDistance = 0;
  int totalDistance = 0;

  // selection lasso etc.
  List<Offset> selectedArea = [];
  Offset? gotoPoint;
  // min and max of map x and y coordinates
  double minX = double.infinity;
  double minY = double.infinity;
  double maxX = double.negativeInfinity;
  double maxY = double.negativeInfinity;
  // shifted max coordinates to remove negative values from x and y coordinates
  double shiftedMaxX = double.negativeInfinity;
  double shiftedMaxY = double.negativeInfinity;
  // offset to center map in canvas
  double offsetX = 0;
  double offsetY = 0;
  // ratio meter to available screen size
  double mapScale = 1.0;

  // tasks
  Tasks tasks = Tasks();
  Schedule schedule = Schedule();

  void coordsJsonToClassData(String message) {
    try {
      var decodedMessage = jsonDecode(message) as Map<String, dynamic>;
      if (decodedMessage["features"][0]["properties"]["name"] ==
          'current map') {
        _currentMapJsonToClassData(decodedMessage);
      } else if (decodedMessage["features"][0]["properties"]["name"] ==
          'current preview') {
        _previewJsonToClassData(decodedMessage);
      } else if (decodedMessage["features"][0]["properties"]["name"] ==
          'current mow path') {
        _mowPathJsonToClassData(decodedMessage);
      } else if (decodedMessage["features"][0]["properties"]["name"] ==
          'obstacles') {
        _obstaclesJsonToClassData(decodedMessage);
      } else if (decodedMessage["features"][0]["properties"]["name"] ==
          'task') {
        _taskPreviewJsonToClassData(decodedMessage);
      } else if (decodedMessage["features"][0]["properties"]["name"] ==
          'taskPreview') {
        _taskUpdatedCoordsToClassData(decodedMessage);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Invalid JSON received: $e');
      }
    }
  }

  void mapJsonToClassData(String message) {
    var decodedMessage = jsonDecode(message) as Map<String, dynamic>;
    try {
      receivedMapId = decodedMessage['mapId'];
      receivedPreviewId = decodedMessage['previewId'];
      receivedMowPathId = decodedMessage['mowPathId'];
      receivedObstaclesId = decodedMessage['obstaclesId'];
      idxPercent = decodedMessage['mowprogressIdxPercent'];
      distancePercent = decodedMessage['mowprogressDistancePercent'];
      areaTotal = decodedMessage['areaTotal'];
      finishedDistance = decodedMessage['finishedDistance'];
      totalDistance = decodedMessage['distanceTotal'];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Invalid map JSON: $e');
      }
    }
  }

  void _currentMapJsonToClassData(Map decodedMessage) {
    List<Offset> exclusion = [];
    _resetCoords();
    try {
      for (var feature in decodedMessage["features"]) {
        if (feature['properties']['name'] == 'perimeter' &&
            feature['geometry']['coordinates'].isNotEmpty) {
          for (var coord in feature['geometry']['coordinates'][0]) {
            perimeter.add(Offset(coord[0], coord[1]));
          }
          shapesBouquet[0] = perimeter;
        } else if (feature['properties']['name'] == 'exclusion') {
          exclusion = [];
          for (var coord in feature['geometry']['coordinates'][0]) {
            exclusion.add(Offset(coord[0], coord[1]));
          }
          shapesBouquet.add(exclusion);
          exclusions.add(exclusion);
        } else if (feature['properties']['name'] == 'dockpoints') {
          for (var coord in feature['geometry']['coordinates']) {
            dockPath.add(Offset(coord[0], coord[1]));
          }
          shapesBouquet.add(dockPath);
        } else if (feature['properties']['name'] == 'search wire') {
          for (var coord in feature['geometry']['coordinates']) {
            searchWire.add(Offset(coord[0], coord[1]));
          }
          shapesBouquet.add(searchWire);
        }
      }
      mapId = decodedMessage["features"][0]["properties"]["id"];
      _findMinAndMax();
      _shiftShapes();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Invalid map json data: $e');
      }
    }
  }

  void _previewJsonToClassData(Map decodedMessage) {
    resetPreviewCoords();
    try {
      if (decodedMessage['features'][1]['geometry']['coordinates'].isEmpty) {
        previewId = decodedMessage["features"][0]["properties"]["id"];
        return;
      }
      for (var feature in decodedMessage["features"]) {
        if (feature['properties']['name'] == 'preview') {
          for (var coord in feature['geometry']['coordinates'][0]) {
            preview.add(Offset(coord[0], coord[1]));
          }
        }
      }
      previewId = decodedMessage["features"][0]["properties"]["id"];
      _shiftPreview();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Invalid preview json data: $e');
      }
    }
  }

  void _mowPathJsonToClassData(Map decodedMessage) {
    resetMowPathCoords();
    try {
      if (decodedMessage['features'][1]['geometry']['coordinates'].isEmpty) {
        mowPathId = decodedMessage["features"][0]["properties"]["id"];
        return;
      }
      for (var feature in decodedMessage["features"]) {
        if (feature['properties']['name'] == 'mow path') {
          for (var coord in feature['geometry']['coordinates'][0]) {
            mowPath.add(Offset(coord[0], coord[1]));
          }
        }
      }
      mowPathId = decodedMessage["features"][0]["properties"]["id"];
      _shiftMowPath();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Invalid mow path json data: $e');
      }
    }
  }

  void _obstaclesJsonToClassData(Map decodedMessage) {
    List<Offset> obstacle = [];
    resetObstaclesCoords();
    try {
      if (decodedMessage['features'][1]['geometry']['coordinates'].isEmpty) {
        obstaclesId = decodedMessage["features"][0]["properties"]["id"];
        return;
      }
      for (var feature in decodedMessage["features"]) {
        if (feature['properties']['name'] == 'obstacle') {
          obstacle = [];
          for (var coord in feature['geometry']['coordinates'][0]) {
            obstacle.add(Offset(coord[0], coord[1]));
          }
          obstacles.add(obstacle);
        }
      }
      obstaclesId = decodedMessage["features"][0]["properties"]["id"];
      _shiftObstacles();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('JSON to class data for obstacles failed: $e');
      }
    }
  }

  void lassoSelectionToJsonData(List<Offset> selection) {
    selectedArea = _canvasCoordsToCartesian(selection, mapScale);
  }

  void gotoPointToJsonData(Offset selection) {
    gotoPoint = _canvasCoordsToCartesian([selection], mapScale)[0];
  }

  void _taskPreviewJsonToClassData(Map decodedMessage) {
    final List<List<Offset>> previews = [];
    final List<List<Offset>> selections = [];
    final List<MowParameters> mowParameters = [];
    try {
      for (var feature in decodedMessage["features"]) {
        final List<Offset> coords = [];
        if (feature["properties"]["name"] != 'task' &&
            feature["geometry"]["coordinates"].isNotEmpty) {
          for (var coord in feature['geometry']['coordinates'][0]) {
            coords.add(Offset(coord[0], coord[1]));
          }
        }
        if (feature["properties"]["name"] != 'task' &&
            feature['geometry']['type'] == 'LineString') {
          previews.add(coords);
        }
        if (feature["properties"]["name"] != 'task' &&
            feature['geometry']['type'] == 'Polygon') {
          selections.add(coords);
          mowParameters.add(MowParameters.fromJson(feature["properties"]));
        }
        //previews.add(preview);
      }
      tasks.previews[decodedMessage["features"][0]["properties"]["id"]] =
          previews;
      tasks.selections[decodedMessage["features"][0]["properties"]["id"]] =
          selections;
      tasks.mowParameters[decodedMessage["features"][0]["properties"]["id"]] =
          mowParameters;
      _shiftTaskPreview();
      _shiftTaskSelection();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('JSON to class data for task preivew failed: $e');
      }
    }
  }

  void _taskUpdatedCoordsToClassData(Map decodedMessage) {
    try {
      tasks.udpatedCoords['taskName'] = decodedMessage['features'][0]['properties']['taskName'];
      tasks.udpatedCoords['subtaskNr'] = decodedMessage['features'][1]['properties']['subtaskNr'];
      tasks.udpatedCoords['preview'] = decodedMessage['features'][1]['geometry'];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('JSON to class data for task updated coords failed: $e');
      }
    }
  }

  List<Offset> _canvasCoordsToCartesian(List<Offset> shape, double scale) {
    shape = shape.map((p) => Offset(p.dx - offsetX, p.dy - offsetY)).toList();
    shape = shape.map((p) => Offset(p.dx / scale, p.dy / scale)).toList();
    shape = shape.map((p) => Offset(p.dx + minX, -p.dy + minY)).toList();
    return shape;
  }

  void _findMinAndMax() {
    for (var polygon in shapesBouquet) {
      for (var point in polygon) {
        if (point.dx < minX) minX = point.dx;
        if (point.dy < minY) minY = point.dy;
        if (point.dx > maxX) maxX = point.dx;
        if (point.dy > maxY) maxY = point.dy;
      }
    }
    shiftedMaxX = maxX - minX;
    shiftedMaxY = maxY - minY;
  }

  void _shiftShapes() {
    shiftedPerimeter =
        perimeter.map((p) => Offset(p.dx - minX, -(p.dy - minY))).toList();
    shiftedExclusions = exclusions
        .map((shape) =>
            shape.map((p) => Offset(p.dx - minX, -(p.dy - minY))).toList())
        .toList();
    shiftedDockPath =
        dockPath.map((p) => Offset(p.dx - minX, -(p.dy - minY))).toList();
    shiftedSearchWire =
        searchWire.map((p) => Offset(p.dx - minX, -(p.dy - minY))).toList();
  }

  void scaleShapes(Size screenSize) {
    if (shiftedMaxX / shiftedMaxY > screenSize.width / screenSize.height) {
      mapScale = screenSize.width / shiftedMaxX;
    } else {
      mapScale = screenSize.height / shiftedMaxY;
    }
    offsetX = (screenSize.width - shiftedMaxX * mapScale) / 2;
    offsetY = (screenSize.height + shiftedMaxY * mapScale) / 2;

    // 1st. scale shapes for canvas screen size
    scaledPerimeter = shiftedPerimeter
        .map((p) => Offset(p.dx * mapScale, p.dy * mapScale))
        .toList();
    scaledExclusions = shiftedExclusions
        .map((shape) =>
            shape.map((p) => Offset(p.dx * mapScale, p.dy * mapScale)).toList())
        .toList();
    scaledDockPath = shiftedDockPath
        .map((p) => Offset(p.dx * mapScale, p.dy * mapScale))
        .toList();
    scaledSearchWire = shiftedSearchWire
        .map((p) => Offset(p.dx * mapScale, p.dy * mapScale))
        .toList();

    // 2nd. center shapes for canvas
    scaledPerimeter = scaledPerimeter
        .map((p) => Offset(p.dx + offsetX, p.dy + offsetY))
        .toList();
    scaledExclusions = scaledExclusions
        .map((shape) =>
            shape.map((p) => Offset(p.dx + offsetX, p.dy + offsetY)).toList())
        .toList();
    scaledDockPath = scaledDockPath
        .map((p) => Offset(p.dx + offsetX, p.dy + offsetY))
        .toList();
    scaledSearchWire = scaledSearchWire
        .map((p) => Offset(p.dx + offsetX, p.dy + offsetY))
        .toList();
  }

  void _shiftPreview() {
    shiftedPreview =
        preview.map((p) => Offset(p.dx - minX, -(p.dy - minY))).toList();
  }

  void scalePreview() {
    scaledPreview = shiftedPreview
        .map((p) => Offset(p.dx * mapScale, p.dy * mapScale))
        .toList();
    scaledPreview = scaledPreview
        .map((p) => Offset(p.dx + offsetX, p.dy + offsetY))
        .toList();
  }

  void _shiftMowPath() {
    shiftedMowPath =
        mowPath.map((p) => Offset(p.dx - minX, -(p.dy - minY))).toList();
  }

  void scaleMowPath() {
    scaledMowPath = shiftedMowPath
        .map((p) => Offset(p.dx * mapScale, p.dy * mapScale))
        .toList();
    scaledMowPath = scaledMowPath
        .map((p) => Offset(p.dx + offsetX, p.dy + offsetY))
        .toList();
  }

  void _shiftObstacles() {
    shiftedObstacles = obstacles
        .map((shape) =>
            shape.map((p) => Offset(p.dx - minX, -(p.dy - minY))).toList())
        .toList();
  }

  void scaleObstacles() {
    scaledObstacles = shiftedObstacles
        .map((shape) =>
            shape.map((p) => Offset(p.dx * mapScale, p.dy * mapScale)).toList())
        .toList();
    scaledObstacles = scaledObstacles
        .map((shape) =>
            shape.map((p) => Offset(p.dx + offsetX, p.dy + offsetY)).toList())
        .toList();
  }

  void _shiftTaskPreview() {
    for (var taskName in tasks.previews.keys) {
      tasks.shiftedPreviews[taskName] = tasks.previews[taskName]!
          .map((shape) =>
              shape.map((p) => Offset(p.dx - minX, -(p.dy - minY))).toList())
          .toList();
    }

    scaleTaskPreview();
  }

  void scaleTaskPreview() {
    for (var taskName in tasks.shiftedPreviews.keys) {
      tasks.scaledPreviews[taskName] = tasks.shiftedPreviews[taskName]!
          .map((shape) => shape
              .map((p) => Offset(p.dx * mapScale, p.dy * mapScale))
              .toList())
          .toList();
      tasks.scaledPreviews[taskName] = tasks.scaledPreviews[taskName]!
          .map((shape) =>
              shape.map((p) => Offset(p.dx + offsetX, p.dy + offsetY)).toList())
          .toList();
    }
  }

  void _shiftTaskSelection() {
    for (var taskName in tasks.selections.keys) {
      tasks.shiftedSelections[taskName] = tasks.selections[taskName]!
          .map((shape) =>
              shape.map((p) => Offset(p.dx - minX, -(p.dy - minY))).toList())
          .toList();
    }

    scaleTaskSelection();
  }

  void scaleTaskSelection() {
    for (var taskName in tasks.shiftedSelections.keys) {
      tasks.scaledSelections[taskName] = tasks.shiftedSelections[taskName]!
          .map((shape) => shape
              .map((p) => Offset(p.dx * mapScale, p.dy * mapScale))
              .toList())
          .toList();
      tasks.scaledSelections[taskName] = tasks.scaledSelections[taskName]!
          .map((shape) =>
              shape.map((p) => Offset(p.dx + offsetX, p.dy + offsetY)).toList())
          .toList();
    }
  }

  void _resetCoords() {
    perimeter = [];
    exclusions = [];
    dockPath = [];
    searchWire = [];
    shapesBouquet = [[]];
    minX = double.infinity;
    minY = double.infinity;
    maxX = double.negativeInfinity;
    maxY = double.negativeInfinity;
    shiftedMaxX = double.negativeInfinity;
    shiftedMaxY = double.negativeInfinity;
  }

  void resetPreviewCoords() {
    preview = [];
    shiftedPreview = [];
    scaledPreview = [];
  }

  void resetMowPathCoords() {
    mowPath = [];
    shiftedMowPath = [];
    scaledMowPath = [];
  }

  void resetObstaclesCoords() {
    obstacles = [];
    shiftedObstacles = [];
    scaledObstacles = [];
  }
}
