import 'package:flutter/material.dart';
import 'dart:convert';

class Landscape {
  String mapId = '';
  List<Offset> perimeter = [];
  List<Offset> exclusion = [];
  List<List<Offset>> exclusions = [];
  List<Offset> dockPath = [];
  List<Offset> searchWire = [];
  List<List<Offset>> mapForPlot = [[]];

  void jsonToCoords(String message) {
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
    }
    catch(e){
      print('Invalid map json data: $e');
    }
    
  }

  void _resetCoords() {
    perimeter = [];
    exclusion = [];
    exclusions = [];
    dockPath = [];
    searchWire = [];
    mapForPlot = [[]];
  }
}
