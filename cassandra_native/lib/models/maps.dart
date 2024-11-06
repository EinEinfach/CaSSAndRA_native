import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class Maps {
  String? loaded;
  String selected = '';
  List<dynamic> available = [];
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

  List<List<Offset>> _shapesBouquet = [[]];

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

  void resetSelection() {
    _resetCoords();
    selected = '';
  }

  void mapsJsonToClassData(String message) {
    var decodedMessage = jsonDecode(message) as Map<String, dynamic>;
    try {
      loaded = decodedMessage['loaded'];
      available = decodedMessage['available'];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Invalid maps JSON: $e');
      }
    }
  }

  void mapsCoordsJsonToClassData(String message) {
    var decodedMessage = jsonDecode(message) as Map<String, dynamic>;
    List<Offset> exclusion = [];
    if (decodedMessage.isEmpty) {
      _resetCoords();
      selected = '';
      return;
    }
    _resetCoords();
    try {
      for (var feature in decodedMessage["features"]) {
        if (feature['properties']['name'] == 'perimeter') {
          for (var coord in feature['geometry']['coordinates'][0]) {
            perimeter.add(Offset(coord[0], coord[1]));
          }
          _shapesBouquet[0] = perimeter;
        } else if (feature['properties']['name'] == 'exclusion') {
          exclusion = [];
          for (var coord in feature['geometry']['coordinates'][0]) {
            exclusion.add(Offset(coord[0], coord[1]));
          }
          _shapesBouquet.add(exclusion);
          exclusions.add(exclusion);
        } else if (feature['properties']['name'] == 'dockpoints') {
          for (var coord in feature['geometry']['coordinates']) {
            dockPath.add(Offset(coord[0], coord[1]));
          }
          _shapesBouquet.add(dockPath);
        } else if (feature['properties']['name'] == 'search wire') {
          for (var coord in feature['geometry']['coordinates']) {
            searchWire.add(Offset(coord[0], coord[1]));
          }
          _shapesBouquet.add(searchWire);
        }
      }
      _findMinAndMax();
      _shiftShapes();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Invalid map json data: $e');
      }
    }
  }

  void _findMinAndMax() {
    for (var polygon in _shapesBouquet) {
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

  void _resetCoords() {
    perimeter = [];
    exclusions = [];
    dockPath = [];
    searchWire = [];
    _shapesBouquet = [[]];
    minX = double.infinity;
    minY = double.infinity;
    maxX = double.negativeInfinity;
    maxY = double.negativeInfinity;
    shiftedMaxX = double.negativeInfinity;
    shiftedMaxY = double.negativeInfinity;
  }
}
