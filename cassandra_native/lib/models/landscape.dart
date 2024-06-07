import 'package:flutter/material.dart';
import 'package:polygon/polygon.dart';

class Landscape {
  const Landscape(
      {required this.perimeter,
      this.exclusions,
      this.dockPath,
      this.searchWire});

  Landscape.fromJson(Map<String, dynamic> json, this.perimeter, this.exclusions,
      this.dockPath, this.searchWire);

  final Polygon perimeter;
  final List<Polygon>? exclusions;
  final List<Offset>? dockPath;
  final List<Offset>? searchWire;
}
