import 'dart:math';
import 'package:flutter/material.dart';

// Ramer-Douglas-Peucker Algorithmus zur Vereinfachung des Polygons
List<Offset> simplifyPath(List<Offset> points, double tolerance) {
  if (points.length < 3) return points;
  return _ramerDouglasPeucker(points, tolerance);
}

// Der Ramer-Douglas-Peucker Algorithmus rekursiv
List<Offset> _ramerDouglasPeucker(List<Offset> points, double epsilon) {
  if (points.length < 2) return points;

  double dmax = 0.0;
  int index = 0;
  for (int i = 1; i < points.length - 1; i++) {
    double d =
        _perpendicularDistance(points[i], points[0], points[points.length - 1]);
    if (d > dmax) {
      index = i;
      dmax = d;
    }
  }

  if (dmax > epsilon) {
    List<Offset> recResults1 =
        _ramerDouglasPeucker(points.sublist(0, index + 1), epsilon);
    List<Offset> recResults2 =
        _ramerDouglasPeucker(points.sublist(index), epsilon);

    return recResults1.sublist(0, recResults1.length - 1) + recResults2;
  } else {
    return [points[0], points[points.length - 1]];
  }
}

// Berechne den Abstand eines Punktes zur Linie
double _perpendicularDistance(Offset point, Offset lineStart, Offset lineEnd) {
  double dx = lineEnd.dx - lineStart.dx;
  double dy = lineEnd.dy - lineStart.dy;
  double mag = sqrt(dx * dx + dy * dy);
  if (mag > 0.0) {
    dx /= mag;
    dy /= mag;
  }
  double pvx = point.dx - lineStart.dx;
  double pvy = point.dy - lineStart.dy;
  double pvdot = dx * pvx + dy * pvy;
  double ax = pvx - pvdot * dx;
  double ay = pvy - pvdot * dy;
  return sqrt(ax * ax + ay * ay);
}

// Prüfe ob der Punkt innerhalb des Polygons liegt
bool isPointInsidePolygon(Offset point, List<Offset> polygon) {
  Path path = Path()..moveTo(polygon[0].dx, polygon[0].dy);
  for (int i = 1; i < polygon.length; i++) {
    path.lineTo(polygon[i].dx, polygon[i].dy);
  }
  path.close();
  return path.contains(point);
}

// Normalisiere den Winkel auf die kurzeste Drehung
double normalizeAngle(double startAngle, double endAngle) {
  double delta = endAngle - startAngle;
  if (delta > pi) {
    delta -= 2*pi;
  } else if (delta < -pi) {
    delta += 2*pi;
  }
  return startAngle + delta;
}
