import 'package:flutter/material.dart';
import 'dart:convert';

class Landscape {
  String mapId = '';
  List<Offset> perimeter = [];
  List<Offset> exclusion = [];
  List<List<Offset>> exclusions = [];
  List<Offset> dockPath = [];
  List<Offset> searchWire = [];
  List<Offset> shiftedPerimeter = [];
  List<List<Offset>> shiftedExclusions = [];
  List<Offset> shiftedDockPath = [];
  List<Offset> shiftedSearchWire = [];
  List<Offset> scaledPerimeter = [];
  List<List<Offset>> scaledExclusions = [];
  List<Offset> scaledDockPath = [];
  List<Offset> scaledSearchWire = [];
  List<List<Offset>> mapForPlot = [[]];
  double minX = double.infinity;
  double minY = double.infinity;
  double maxX = double.negativeInfinity;
  double maxY = double.negativeInfinity;
  double shiftedMaxX = double.negativeInfinity;
  double shiftedMaxY = double.negativeInfinity;

  void jsonToClassData(String message) {
    _resetCoords();
    var decodedMessage = jsonDecode(message) as Map<String, dynamic>;
    try {
      for (var feature in decodedMessage["features"]) {
        if (feature['properties']['name'] == 'perimeter') {
          for (var coord in feature['geometry']['coordinates'][0]) {
            perimeter.add(Offset(coord[0], coord[1]));
          }
          mapForPlot[0] = perimeter;
        } else if (feature['properties']['name'] == 'exclusion') {
          exclusion = [];
          for (var coord in feature['geometry']['coordinates'][0]) {
            exclusion.add(Offset(coord[0], coord[1]));
          }
          mapForPlot.add(exclusion);
          exclusions.add(exclusion);
        } else if (feature['properties']['name'] == 'dockpoints') {
          for (var coord in feature['geometry']['coordinates']) {
            dockPath.add(Offset(coord[0], coord[1]));
          }
          mapForPlot.add(dockPath);
        } else if (feature['properties']['name'] == 'search wire') {
          for (var coord in feature['geometry']['coordinates']) {
            searchWire.add(Offset(coord[0], coord[1]));
          }
          mapForPlot.add(searchWire);
        }
      }
      _findMinAndMax();
      _shiftShapes();
    } catch (e) {
      print('Invalid map json data: $e');
    }
  }

  void _findMinAndMax() {
    for (var polygon in mapForPlot) {
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

  void scaleShapes(double scale, double width, double height) {
    // offset to center map in canvas
    final offsetX = (width - shiftedMaxX * scale) / 2;
    final offsetY = (height + shiftedMaxY * scale) / 2;

    // 1st. scale shapes for canvas screen size
    scaledPerimeter = shiftedPerimeter
        .map((p) => Offset(p.dx * scale, p.dy * scale))
        .toList();
    scaledExclusions = shiftedExclusions
        .map((shape) =>
            shape.map((p) => Offset(p.dx * scale, p.dy * scale)).toList())
        .toList();
    scaledDockPath = shiftedDockPath
        .map((p) => Offset(p.dx * scale, p.dy * scale))
        .toList();
    scaledSearchWire = shiftedSearchWire
        .map((p) => Offset(p.dx * scale, p.dy * scale))
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
    exclusion = [];
    exclusions = [];
    dockPath = [];
    searchWire = [];
    mapForPlot = [[]];
    minX = double.infinity;
    minY = double.infinity;
    maxX = double.negativeInfinity;
    maxY = double.negativeInfinity;
    shiftedMaxX = double.negativeInfinity;
    shiftedMaxY = double.negativeInfinity;
  }
}
