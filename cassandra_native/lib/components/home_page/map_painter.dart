import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math';

import 'package:cassandra_native/models/server.dart';
import 'package:cassandra_native/models/landscape.dart';
import 'package:cassandra_native/models/robot.dart';

// should be refactored to make rover size selectable
const double minRoverImageSize = 20;
const double baseLineWidth = 2.0;

class MapPainter extends CustomPainter {
  final Offset offset;
  final double scale;
  final ui.Image? roverImage;
  final Server currentServer;
  final List<Offset> lassoSelection;
  final List<Offset> lassoSelectionPoints;
  final bool lassoPointSelected;
  final bool lassoSelected;
  final ColorScheme colors;

  const MapPainter({
    required this.offset,
    required this.scale,
    required this.roverImage,
    required this.currentServer,
    required this.lassoSelection,
    required this.lassoSelectionPoints,
    required this.lassoPointSelected,
    required this.lassoSelected,
    required this.colors,
  });

  Path drawPolygon(Path path, List<Offset> points) {
    if (points.isNotEmpty) {
      path.moveTo(points[0].dx, points[0].dy);
      for (var point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      path.close();
    }
    return path;
  }

  Path drawLine(Path path, List<Offset> points) {
    if (points.isNotEmpty) {
      path.moveTo(points[0].dx, points[0].dy);
      for (var point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path;
  }

  Path drawDashedLine(
      Path path, List<Offset> points, double dashWidth, double dashSpace) {
    if (points.length >= 2) {
      double distance = (points[1] - points[0]).distance;
      Offset direction = (points[1] - points[0]) / distance;
      double currentDistance = 0;
      while (currentDistance < distance) {
        final currentStart = points[0] + direction * currentDistance;
        final currentEnd =
            points[0] + direction * (currentDistance + dashWidth);
        if ((currentDistance + dashWidth) <= distance) {
          path = drawLine(path, [currentStart, currentEnd]);
        }
        currentDistance += dashWidth + dashSpace;
      }
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);

    final adjustedLineWidth = baseLineWidth / scale;
    final Landscape currentMap = currentServer.currentMap;
    final Robot robot = currentServer.robot;

    // draw perimeter
    var polygonBrush = Paint()
      ..color = colors.inversePrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = adjustedLineWidth;

    Path pathPerimeter = Path();
    pathPerimeter = drawPolygon(pathPerimeter, currentMap.scaledPerimeter);
    canvas.drawPath(pathPerimeter, polygonBrush);

    // draw exclusions
    var exclusionsStrokeBrusch = Paint()
      ..color = colors.inversePrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = adjustedLineWidth;

    var exclusionsFillColor = Paint()
      ..color = colors.primary
      ..style = PaintingStyle.fill;

    Path pathExclusions = Path();
    for (var exclusion in currentMap.scaledExclusions) {
      pathExclusions = drawPolygon(pathExclusions, exclusion);
    }
    canvas.drawPath(pathExclusions, exclusionsFillColor);
    canvas.drawPath(pathExclusions, exclusionsStrokeBrusch);

    // draw preview
    var previewBrush = Paint()
      ..color = const Color.fromARGB(255, 113, 161, 143)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5 * adjustedLineWidth;

    Path pathPreview = Path();
    pathPreview = drawLine(pathPreview, currentMap.scaledPreview);
    canvas.drawPath(pathPreview, previewBrush);

    // draw mow path
    var mowPathBrush = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5 * adjustedLineWidth;

    var mowPathFinishedBrush = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5 * adjustedLineWidth;

    var mowPathCurrent = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5 * adjustedLineWidth;

    if (currentMap.scaledMowPath.isNotEmpty) {
      //finished
      Path pathMowPathFinished = Path();
      pathMowPathFinished = drawLine(pathMowPathFinished,
          currentMap.scaledMowPath.sublist(0, robot.mowPointIdx + 1));
      canvas.drawPath(pathMowPathFinished, mowPathFinishedBrush);

      // unfinished
      Path pathMowPath = Path();
      pathMowPath = drawLine(
          pathMowPath, currentMap.scaledMowPath.sublist(robot.mowPointIdx));
      canvas.drawPath(pathMowPath, mowPathBrush);

      // current
      if (robot.mowPointIdx > 0) {
        var pathMowPathCurrent = Path();
        pathMowPathCurrent = drawDashedLine(
          pathMowPathCurrent,
          [
            currentMap.scaledMowPath[robot.mowPointIdx - 1],
            currentMap.scaledMowPath[robot.mowPointIdx]
          ],
          2.0,
          2.0,
        );
        canvas.drawPath(pathMowPathCurrent, mowPathCurrent);
      }
    }

    // draw dockPath
    var dockPathBrush = Paint()
      ..color = colors.onSurface
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8 * adjustedLineWidth;

    Path pathDock = Path();
    pathDock = drawLine(pathDock, currentMap.scaledDockPath);
    canvas.drawPath(pathDock, dockPathBrush);

    // draw searchWire
    Path pathSearchWire = Path();
    pathSearchWire = drawLine(pathSearchWire, currentMap.scaledSearchWire);
    canvas.drawPath(pathSearchWire, dockPathBrush);

    // draw lassoSelection
    if (lassoSelection.isNotEmpty) {
      var lassoSelectionBrush = Paint()
        ..color = lassoPointSelected? colors.error : colors.onSurface.withOpacity(0.4)
        ..style = lassoSelected? PaintingStyle.fill : PaintingStyle.stroke
        ..strokeWidth = 0.5 * adjustedLineWidth;
      Path pathLassoSelection = Path();
      pathLassoSelection = drawPolygon(pathLassoSelection, lassoSelection);
      canvas.drawPath(pathLassoSelection, lassoSelectionBrush);
    }

    // draw lassoSelectionPoints
    if (lassoSelectionPoints.isNotEmpty) {
      var lassoSelectionPointsBrush = Paint()
        ..color = lassoPointSelected? colors.error : colors.onSurface.withOpacity(0.5)
        ..style = PaintingStyle.fill;
      for (Offset point in lassoSelectionPoints) {
        canvas.drawCircle(point, 2/scale, lassoSelectionPointsBrush);
      }
    }


    // draw rover image
    if (roverImage != null) {
      double imageSize = 1 * currentMap.mapScale;
      imageSize = max(imageSize, minRoverImageSize);

      // rotate rover image
      canvas.save();
      canvas.translate(robot.scaledPosition.dx, robot.scaledPosition.dy);
      canvas.rotate(-robot.angle);
      canvas.translate(-robot.scaledPosition.dx, -robot.scaledPosition.dy);

      final rect = Rect.fromCenter(
          center: robot.scaledPosition, width: imageSize, height: imageSize);
      paintImage(
          canvas: canvas, rect: rect, image: roverImage!, fit: BoxFit.cover);

      // restore saved canvas
      canvas.restore();
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
