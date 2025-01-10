import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math';

import 'package:cassandra_native/theme/theme.dart';
import 'package:cassandra_native/models/server.dart';
import 'package:cassandra_native/models/landscape.dart';
import 'package:cassandra_native/models/robot.dart';
import 'package:cassandra_native/components/logic/map_logic.dart';
import 'package:cassandra_native/components/logic/lasso_logic.dart';

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

  Path _drawPolygon(Path path, List<Offset> points) {
    if (points.isNotEmpty) {
      path.moveTo(points[0].dx, points[0].dy);
      for (var point in points.skip(0)) {
        path.lineTo(point.dx, point.dy);
      }
      path.close();
    }
    return path;
  }

  Path _drawPolygonFromGeoJson(Path path, List<Offset> points) {
    if (points.isNotEmpty) {
      path.moveTo(points[0].dx, points[0].dy);
      for (int i = 1; i < points.length - 1; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      path.close();
    }
    return path;
  }

  Path _drawLine(Path path, List<Offset> points) {
    if (points.isNotEmpty) {
      path.moveTo(points[0].dx, points[0].dy);
      for (var point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path;
  }

  Path _drawDashedLine(
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
          path = _drawLine(path, [currentStart, currentEnd]);
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

    // brushes
    // strokes
    var strokeNoColor05 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5 * adjustedLineWidth;

    var strokeNoColor10 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * adjustedLineWidth;

    // stroke with round caps
    var strokeRoundCapsNoColor10 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = adjustedLineWidth
      ..strokeCap = StrokeCap.round;

    // fills
    var fillNoColor = Paint()..style = PaintingStyle.fill;

    // draw perimeter
    Path pathPerimeter = Path();
    strokeNoColor10.color = colors.inversePrimary;
    pathPerimeter =
        _drawPolygonFromGeoJson(pathPerimeter, currentMap.scaledPerimeter);
    canvas.drawPath(pathPerimeter, strokeNoColor10);

    // draw exclusions
    Path pathExclusions = Path();
    strokeNoColor10.color = colors.inversePrimary;
    fillNoColor.color = colors.secondary;
    for (var exclusion in currentMap.scaledExclusions) {
      pathExclusions = _drawPolygonFromGeoJson(pathExclusions, exclusion);
    }
    canvas.drawPath(pathExclusions, fillNoColor);
    canvas.drawPath(pathExclusions, strokeNoColor10);

    // draw preview
    // var previewBrush = Paint()
    //   ..color = const Color.fromARGB(255, 113, 161, 143)
    //   ..style = PaintingStyle.stroke
    //   ..strokeWidth = 0.5 * adjustedLineWidth;

    // Path pathPreview = Path();
    // pathPreview = drawLine(pathPreview, currentMap.scaledPreview);
    // canvas.drawPath(pathPreview, previewBrush);

    // draw tasks preview
    if (currentMap.tasks.selected.isNotEmpty) {
      final PreviewColorPalette previewColorPalette = PreviewColorPalette();
      int previewCounter = 0;
      for (var task in currentMap.tasks.selected) {
        Path pathTaskPreview = Path();
        if (currentMap.tasks.scaledPreviews.containsKey(task)) {
          strokeNoColor05.color = previewColorPalette.colors[previewCounter];
          previewCounter++;
          previewCounter = previewCounter == previewColorPalette.colors.length
              ? 0
              : previewCounter;
          for (var subtask in currentMap.tasks.scaledPreviews[task]!) {
            pathTaskPreview = _drawLine(pathTaskPreview, subtask);
            canvas.drawPath(pathTaskPreview, strokeNoColor05);
          }
        }
      }
    }

    // draw mow path
    if (currentMap.scaledMowPath.isNotEmpty
     //&& robot.status == 'mow'
     ) {
      //finished
      Path pathMowPathFinished = Path();
      strokeNoColor05.color = Colors.grey.shade300;
      pathMowPathFinished = _drawLine(pathMowPathFinished,
          currentMap.scaledMowPath.sublist(0, robot.mowPointIdx + 1));
      canvas.drawPath(pathMowPathFinished, strokeNoColor05);

      // unfinished
      Path pathMowPath = Path();
      strokeNoColor05.color = Colors.green;
      pathMowPath = _drawLine(
          pathMowPath, currentMap.scaledMowPath.sublist(robot.mowPointIdx));
      canvas.drawPath(pathMowPath, strokeNoColor05);

      // current
      if (robot.mowPointIdx > 0) {
        var pathMowPathCurrent = Path();
        strokeNoColor05.color = Colors.black;
        pathMowPathCurrent = _drawDashedLine(
          pathMowPathCurrent,
          [
            currentMap.scaledMowPath[robot.mowPointIdx - 1],
            currentMap.scaledMowPath[robot.mowPointIdx]
          ],
          2.0,
          2.0,
        );
        canvas.drawPath(pathMowPathCurrent, strokeNoColor05);
      }
    }

    // draw obstacles
    if (currentMap.scaledObstacles.isNotEmpty) {
      Path pathObstacles = Path();
      strokeNoColor10.color = colors.errorContainer;
      fillNoColor.color = colors.errorContainer.withOpacity(0.6);
      for (var obstacle in currentMap.scaledObstacles) {
        pathObstacles = _drawPolygon(pathObstacles, obstacle);
      }
      canvas.drawPath(pathObstacles, fillNoColor);
      canvas.drawPath(pathObstacles, strokeNoColor10);
    }

    // draw dockPath

    Path pathDock = Path();
    strokeNoColor05.color = colors.onSurface;
    pathDock = _drawLine(pathDock, currentMap.scaledDockPath);
    canvas.drawPath(pathDock, strokeNoColor05);

    // draw searchWire
    Path pathSearchWire = Path();
    strokeNoColor05.color = colors.onSurface;
    pathSearchWire = _drawLine(pathSearchWire, currentMap.scaledSearchWire);
    canvas.drawPath(pathSearchWire, strokeNoColor05);

    // draw lassoSelection
    if (lasso.selection.isNotEmpty) {
      strokeNoColor05.color = lasso.selectedPointIndex != null
          ? colors.error
          : colors.onSurface.withOpacity(0.4);
      Path pathLassoSelection = Path();
      pathLassoSelection = _drawPolygon(pathLassoSelection, lasso.selection);
      canvas.drawPath(pathLassoSelection, strokeNoColor05);
      if (lasso.selected) {
        fillNoColor.color = colors.onSurface.withOpacity(0.4);
        canvas.drawPath(pathLassoSelection, fillNoColor);
      }
    }

    // draw lassoSelectionPoints
    if (lasso.selectionPoints.isNotEmpty) {
      fillNoColor.color = lasso.selectedPointIndex != null
          ? colors.error
          : colors.onSurface.withOpacity(0.5);
      for (Offset point in lasso.selectionPoints) {
        canvas.drawCircle(point, 2 / scale, fillNoColor);
      }
    }

    // draw selected lasso point
    if (lasso.selectedPointIndex != null) {
      final selectedPoint = lasso.selection[lasso.selectedPointIndex!];
      strokeRoundCapsNoColor10.color = colors.error;
      canvas.drawLine(
          Offset(selectedPoint.dx - 6 / scale, selectedPoint.dy),
          Offset(selectedPoint.dx + 6 / scale, selectedPoint.dy),
          strokeRoundCapsNoColor10);
      canvas.drawLine(
          Offset(selectedPoint.dx, selectedPoint.dy - 6 / scale),
          Offset(selectedPoint.dx, selectedPoint.dy + 6 / scale),
          strokeRoundCapsNoColor10);
    }

    // draw go to point
    if (gotoPoint.coords != null) {
      strokeRoundCapsNoColor10.color =
          gotoPoint.selected ? colors.error : colors.onSurface;
      canvas.drawLine(
          Offset(gotoPoint.coords!.dx - 6 / scale, gotoPoint.coords!.dy),
          Offset(gotoPoint.coords!.dx + 6 / scale, gotoPoint.coords!.dy),
          strokeRoundCapsNoColor10);
      canvas.drawLine(
          Offset(gotoPoint.coords!.dx, gotoPoint.coords!.dy + 6 / scale),
          Offset(gotoPoint.coords!.dx, gotoPoint.coords!.dy - 6 / scale),
          strokeRoundCapsNoColor10);
    }

    // draw target point
    if (robot.status == 'mow' ||
        robot.status == 'transit' ||
        robot.status == 'docking') {
      strokeRoundCapsNoColor10.color = Colors.lightGreen;
      canvas.drawLine(
          Offset(robot.scaledTarget.dx - 6 / scale, robot.scaledTarget.dy),
          Offset(robot.scaledTarget.dx + 6 / scale, robot.scaledTarget.dy),
          strokeRoundCapsNoColor10);
      canvas.drawLine(
          Offset(robot.scaledTarget.dx, robot.scaledTarget.dy + 6 / scale),
          Offset(robot.scaledTarget.dx, robot.scaledTarget.dy - 6 / scale),
          strokeRoundCapsNoColor10);
    }

    // draw rover image
    if (roverImage != null) {
      double imageSize = 1 * currentMap.mapScale;
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
