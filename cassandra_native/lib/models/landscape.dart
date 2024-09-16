import 'package:flutter/material.dart';
import 'dart:convert';

class Landscape {
  String mapId = '';
  String receivedMapId = '';
  String previewId = '';
  String receivedPreviewId = '';
  String mowPathId = '';
  String receivedMowPathId = '';
  List<Offset> perimeter = [];
  List<Offset> exclusion = [];
  List<List<Offset>> exclusions = [];
  List<Offset> dockPath = [];
  List<Offset> searchWire = [];
  List<Offset> shiftedPerimeter = [];
  List<List<Offset>> shiftedExclusions = [];
  List<Offset> shiftedDockPath = [];
  List<Offset> shiftedSearchWire = [];
  List<Offset> shiftedPreview = [];
  List<Offset> shiftedMowPath = [];
  List<Offset> scaledPerimeter = [];
  List<List<Offset>> scaledExclusions = [];
  List<Offset> scaledDockPath = [];
  List<Offset> scaledSearchWire = [];
  List<Offset> scaledPreview = [];
  List<Offset> scaledMowPath = [];
  List<List<Offset>> shapesBouquet = [[]];
  List<Offset> preview = [];
  List<Offset> mowPath = [];
  // selection lasso etc.
  List<Offset> selectedArea = [];
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

  void coordsJsonToClassData(String message) {
    var decodedMessage = jsonDecode(message) as Map<String, dynamic>;
    if (decodedMessage["features"][0]["properties"]["name"] == 'current map') {
      _currentMapJsonToClassData(decodedMessage);
    } else if (decodedMessage["features"][0]["properties"]["name"] ==
        'current preview') {
      _previewJsonToClassData(decodedMessage);
    } else if (decodedMessage["features"][0]["properties"]["name"] ==
        'current mow path') {
      _mowPathJsonToClassData(decodedMessage);
    }
  }

  void mapJsonToClassData(String message) {
    var decodedMessage = jsonDecode(message) as Map<String, dynamic>;
    receivedMapId = decodedMessage['mapId'];
    receivedPreviewId = decodedMessage['previewId'];
    receivedMowPathId = decodedMessage['mowPathId'];
  }

  void _currentMapJsonToClassData(Map decodedMessage) {
    _resetCoords();
    try {
      for (var feature in decodedMessage["features"]) {
        if (feature['properties']['name'] == 'perimeter') {
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
      print('Invalid map json data: $e');
    }
  }

  void _previewJsonToClassData(Map decodedMessage) {
    _resetPreviewCoords();
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
      print('Invalid preview json data: $e');
    }
  }

  void _mowPathJsonToClassData(Map decodedMessage) {
    _resetMowPathCoords();
    try {
      if (decodedMessage['features'][1]['geometry']['coordinates'].isEmpty) {
        mowPathId = decodedMessage["features"][0]["properties"]["id"];
        return;
      }
      _resetPreviewCoords();
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
      print('Invalid mow path json data: $e');
    }
  }

  void lassoSelectionToJsonData(List<Offset> selection, double scale) {
    selectedArea = _canvasCoordsToCartesian(selection, scale);
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

  void scaleShapes(double width, double height) {
    offsetX = (width - shiftedMaxX * mapScale) / 2;
    offsetY = (height + shiftedMaxY * mapScale) / 2;

    // 1st. scale shapes for canvas screen size
    scaledPerimeter = shiftedPerimeter
        .map((p) => Offset(p.dx * mapScale, p.dy * mapScale))
        .toList();
    scaledExclusions = shiftedExclusions
        .map((shape) =>
            shape.map((p) => Offset(p.dx * mapScale, p.dy * mapScale)).toList())
        .toList();
    scaledDockPath =
        shiftedDockPath.map((p) => Offset(p.dx * mapScale, p.dy * mapScale)).toList();
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
    scaledPreview =
        shiftedPreview.map((p) => Offset(p.dx * mapScale, p.dy * mapScale)).toList();
    scaledPreview = scaledPreview
        .map((p) => Offset(p.dx + offsetX, p.dy + offsetY))
        .toList();
  }

  void _shiftMowPath() {
    shiftedMowPath =
        mowPath.map((p) => Offset(p.dx - minX, -(p.dy - minY))).toList();
  }

  void scaleMowPath() {
    scaledMowPath =
        shiftedMowPath.map((p) => Offset(p.dx * mapScale, p.dy * mapScale)).toList();
    scaledMowPath = scaledMowPath
        .map((p) => Offset(p.dx + offsetX, p.dy + offsetY))
        .toList();
  }

  void _resetCoords() {
    perimeter = [];
    exclusion = [];
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

  void _resetPreviewCoords() {
    preview = [];
    shiftedPreview = [];
    scaledPreview = [];
  }

  void _resetMowPathCoords() {
    mowPath = [];
    shiftedMowPath = [];
    scaledMowPath = [];
  }
}
