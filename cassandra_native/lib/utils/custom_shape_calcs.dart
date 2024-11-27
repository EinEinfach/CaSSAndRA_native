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
    delta -= 2 * pi;
  } else if (delta < -pi) {
    delta += 2 * pi;
  }
  return startAngle + delta;
}

// Prüfe ob ein Polygon Selbstüberschneidungen hat
bool hasSelfIntersections(List<Offset> polygon) {
  bool onSegment(Offset p, Offset q, Offset r) {
    return q.dx <= max(p.dx, r.dx) &&
        q.dx >= min(p.dx, r.dx) &&
        q.dy <= max(p.dy, r.dy) &&
        q.dy >= min(p.dy, r.dy);
  }

  int orientation(Offset p, Offset q, Offset r) {
    double val = (q.dy - p.dy) * (r.dx - q.dx) - (q.dx - p.dx) * (r.dy - q.dy);
    if (val == 0) return 0; // collinear
    return (val > 0) ? 1 : 2; // clockwise or counterclockwise
  }

  bool doLinesIntersect(Offset p1, Offset q1, Offset p2, Offset q2) {
    int o1 = orientation(p1, q1, p2);
    int o2 = orientation(p1, q1, q2);
    int o3 = orientation(p2, q2, p1);
    int o4 = orientation(p2, q2, q1);

    // Allgemeiner Fall
    if (o1 != o2 && o3 != o4) return true;

    // Spezielle Fälle (wenn die Punkte kollinear sind)
    if (o1 == 0 && onSegment(p1, p2, q1)) return true;
    if (o2 == 0 && onSegment(p1, q2, q1)) return true;
    if (o3 == 0 && onSegment(p2, p1, q2)) return true;
    if (o4 == 0 && onSegment(p2, q1, q2)) return true;

    return false;
  }

  // Hauptfunktion zur Überprüfung der Selbstüberschneidungen
  for (int i = 0; i < polygon.length; i++) {
    Offset p1 = polygon[i];
    Offset q1 = polygon[(i + 1) % polygon.length];

    // Überprüfe nur Kanten, die mindestens zwei Indizes weiter entfernt sind,
    // um benachbarte Kanten auszuschließen
    for (int j = i + 2; j < polygon.length; j++) {
      // Überspringe die letzte Kante, wenn sie sich mit der ersten Kante überschneidet
      if (i == 0 && j == polygon.length - 1) continue;

      Offset p2 = polygon[j];
      Offset q2 = polygon[(j + 1) % polygon.length];

      if (doLinesIntersect(p1, q1, p2, q2)) {
        return true; // Selbstüberschneidung gefunden
      }
    }
  }

  return false; // Keine Selbstüberschneidung gefunden
}

Offset getClosestPointOnSegment(Offset a, Offset b, Offset p) {
  // Vector AB
  Offset ab = b - a;
  // Vector AP
  Offset ap = p - a;
  // Projection of AP onto AB normalized
  double t = (ap.dx * ab.dx + ap.dy * ab.dy) / (ab.dx * ab.dx + ab.dy * ab.dy);
  t = t.clamp(0.0, 1.0); // Ensure the projection is within the segment
  return Offset(a.dx + t * ab.dx, a.dy + t * ab.dy);
}
