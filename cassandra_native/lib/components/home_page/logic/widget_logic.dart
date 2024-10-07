import 'package:flutter/material.dart';

class ZoomPan {
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

class Lasso {
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
}

class MapPoint {
  Offset? coords;

  void reset() {
    coords = null;
  }
}
