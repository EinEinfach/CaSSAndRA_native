import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math';

import 'package:cassandra_native/models/server.dart';
import 'package:cassandra_native/models/maps.dart';
import 'package:cassandra_native/components/home_page/logic/home_page_logic.dart';

// should be refactored to make rover size selectable
const double minRoverImageSize = 20;
const double baseLineWidth = 2.0;

class MapPainter extends CustomPainter {
  final Offset offset;
  final double scale;
  final ui.Image? roverImage;
  final Server currentServer;
  final LassoLogic lasso;
  final MapPointLogic gotoPoint;
  final ColorScheme colors;
  final Offset currentPostion;
  final double currentAngle;

  const MapPainter({
    required this.offset,
    required this.scale,
    required this.roverImage,
    required this.currentServer,
    required this.lasso,
    required this.gotoPoint,
    required this.currentPostion,
    required this.currentAngle,
    required this.colors,
  });

  Color _getRandomColor(int min, int max) {
    final random = Random();
    int r = min + random.nextInt(max - min);
    int g = min + random.nextInt(max - min);
    int b = min + random.nextInt(max - min);

    return Color.fromARGB(255, r, g, b);
  }

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
    final Maps maps = currentServer.maps;

    // draw perimeter
    var polygonBrush = Paint()
      ..color = colors.inversePrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = adjustedLineWidth;

    Path pathPerimeter = Path();
    pathPerimeter = drawPolygon(pathPerimeter, maps.scaledPerimeter);
    canvas.drawPath(pathPerimeter, polygonBrush);

    // draw exclusions
    var exclusionsStrokeBrusch = Paint()
      ..color = colors.inversePrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = adjustedLineWidth;

    var exclusionsFillColor = Paint()
      ..color = colors.secondary
      ..style = PaintingStyle.fill;

    Path pathExclusions = Path();
    for (var exclusion in maps.scaledExclusions) {
      pathExclusions = drawPolygon(pathExclusions, exclusion);
    }
    canvas.drawPath(pathExclusions, exclusionsFillColor);
    canvas.drawPath(pathExclusions, exclusionsStrokeBrusch);

    // draw preview
    // var previewBrush = Paint()
    //   ..color = const Color.fromARGB(255, 113, 161, 143)
    //   ..style = PaintingStyle.stroke
    //   ..strokeWidth = 0.5 * adjustedLineWidth;

    // Path pathPreview = Path();
    // pathPreview = drawLine(pathPreview, currentMap.scaledPreview);
    // canvas.drawPath(pathPreview, previewBrush);

    // draw dockPath
    var dockPathBrush = Paint()
      ..color = colors.onSurface
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8 * adjustedLineWidth;

    Path pathDock = Path();
    pathDock = drawLine(pathDock, maps.scaledDockPath);
    canvas.drawPath(pathDock, dockPathBrush);

    // draw searchWire
    Path pathSearchWire = Path();
    pathSearchWire = drawLine(pathSearchWire, maps.scaledSearchWire);
    canvas.drawPath(pathSearchWire, dockPathBrush);

    // draw lassoSelection
    if (lasso.selection.isNotEmpty) {
      var lassoSelectionBrush = Paint()
        ..color = lasso.selectedPointIndex != null
            ? colors.error
            : colors.onSurface.withOpacity(0.4)
        ..style = lasso.selected ? PaintingStyle.fill : PaintingStyle.stroke
        ..strokeWidth = 0.5 * adjustedLineWidth;
      Path pathLassoSelection = Path();
      pathLassoSelection = drawPolygon(pathLassoSelection, lasso.selection);
      canvas.drawPath(pathLassoSelection, lassoSelectionBrush);
    }

    // draw lassoSelectionPoints
    if (lasso.selectionPoints.isNotEmpty) {
      var lassoSelectionPointsBrush = Paint()
        ..color = lasso.selectedPointIndex != null
            ? colors.error
            : colors.onSurface.withOpacity(0.5)
        ..style = PaintingStyle.fill;
      for (Offset point in lasso.selectionPoints) {
        canvas.drawCircle(point, 2 / scale, lassoSelectionPointsBrush);
      }
    }

    // draw selected lasso point
    if (lasso.selectedPointIndex != null) {
      final selectedPoint = lasso.selection[lasso.selectedPointIndex!];
      var lassoSelectedPointBrush = Paint()
        ..color = colors.error
        ..style = PaintingStyle.stroke
        ..strokeWidth = adjustedLineWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
          Offset(selectedPoint.dx - 6 / scale, selectedPoint.dy),
          Offset(selectedPoint.dx + 6 / scale, selectedPoint.dy),
          lassoSelectedPointBrush);
      canvas.drawLine(
          Offset(selectedPoint.dx, selectedPoint.dy - 6 / scale),
          Offset(selectedPoint.dx, selectedPoint.dy + 6 / scale),
          lassoSelectedPointBrush);
    }

    // draw go to point
    if (gotoPoint.coords != null) {
      var gotoPointBrush = Paint()
        ..color = gotoPoint.selected ? colors.error : colors.onSurface
        ..style = PaintingStyle.stroke
        ..strokeWidth = adjustedLineWidth
        ..strokeCap = StrokeCap.round;
      //canvas.drawCircle(gotoPoint!, 3 / scale, gotoPointBrush);
      canvas.drawLine(
          Offset(gotoPoint.coords!.dx - 6 / scale, gotoPoint.coords!.dy),
          Offset(gotoPoint.coords!.dx + 6 / scale, gotoPoint.coords!.dy),
          gotoPointBrush);
      canvas.drawLine(
          Offset(gotoPoint.coords!.dx, gotoPoint.coords!.dy + 6 / scale),
          Offset(gotoPoint.coords!.dx, gotoPoint.coords!.dy - 6 / scale),
          gotoPointBrush);
    }


    // draw rover image
    if (roverImage != null) {
      double imageSize = 1 * maps.mapScale;
      imageSize = max(imageSize, minRoverImageSize);
      // rotate rover image
      canvas.save();
      canvas.translate(currentPostion.dx, currentPostion.dy);
      canvas.rotate(-currentAngle);
      canvas.translate(-currentPostion.dx, -currentPostion.dy);

      final rect = Rect.fromCenter(
          center: currentPostion, width: imageSize, height: imageSize);
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
