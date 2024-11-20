import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math';

import 'package:cassandra_native/theme/theme.dart';
import 'package:cassandra_native/models/server.dart';
import 'package:cassandra_native/models/landscape.dart';
import 'package:cassandra_native/models/robot.dart';
import 'package:cassandra_native/components/logic/map_logic.dart';

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

  Path drawPolygon(Path path, List<Offset> points) {
    if(points.isNotEmpty) {
      path.moveTo(points[0].dx, points[0].dy);
      for (var point in points.skip(0)) {
        path.lineTo(point.dx, point.dy);
      }
      path.close();
    }
    return path;
  }

  Path drawPolygonFromGeoJson(Path path, List<Offset> points) {
    if (points.isNotEmpty) {
      path.moveTo(points[0].dx, points[0].dy);
      for (int i = 1; i < points.length - 1; i++) {
        path.lineTo(points[i].dx, points[i].dy);
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
    pathPerimeter = drawPolygonFromGeoJson(pathPerimeter, currentMap.scaledPerimeter);
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
    for (var exclusion in currentMap.scaledExclusions) {
      pathExclusions = drawPolygonFromGeoJson(pathExclusions, exclusion);
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

    // draw tasks preview
    if (currentMap.tasks.selected.isNotEmpty) {
      final PreviewColorPalette previewColorPalette = PreviewColorPalette();
      int previewCounter = 0;
      for (var task in currentMap.tasks.selected) {
        Path pathTaskPreview = Path();
        if (currentMap.tasks.scaledPreviews.containsKey(task)) {
          var tasksPreviewBrush = Paint()
            ..color = previewColorPalette.colors[previewCounter]
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.5 * adjustedLineWidth;
          previewCounter++;
          previewCounter = previewCounter == previewColorPalette.colors.length
              ? 0
              : previewCounter;
          for (var subtask in currentMap.tasks.scaledPreviews[task]!) {
            pathTaskPreview = drawLine(pathTaskPreview, subtask);
            canvas.drawPath(pathTaskPreview, tasksPreviewBrush);
          }
        }
      }
    }

    // draw mow path
    if (currentMap.scaledMowPath.isNotEmpty && robot.status == 'mow') {
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

    // draw obstacles
    if (currentMap.scaledObstacles.isNotEmpty) {
      var obstaclesStrokeBrush = Paint()
        ..color = colors.errorContainer
        ..style = PaintingStyle.stroke
        ..strokeWidth = adjustedLineWidth;

      var obstaclesFillColor = Paint()
        ..color = colors.errorContainer.withOpacity(0.6)
        ..style = PaintingStyle.fill;

      Path pathObstacles = Path();
      for (var obstacle in currentMap.scaledObstacles) {
        pathObstacles = drawPolygon(pathObstacles, obstacle);
      }
      canvas.drawPath(pathObstacles, obstaclesFillColor);
      canvas.drawPath(pathObstacles, obstaclesStrokeBrush);
    }

    // draw dockPath
    var dockPathBrush = Paint()
      ..color = colors.onSurface
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5 * adjustedLineWidth;

    Path pathDock = Path();
    pathDock = drawLine(pathDock, currentMap.scaledDockPath);
    canvas.drawPath(pathDock, dockPathBrush);

    // draw searchWire
    Path pathSearchWire = Path();
    pathSearchWire = drawLine(pathSearchWire, currentMap.scaledSearchWire);
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

    // draw target point
    if (robot.status == 'mow' ||
        robot.status == 'transit' ||
        robot.status == 'docking') {
      var targetPointBrush = Paint()
        ..color = Colors.lightGreen
        ..style = PaintingStyle.stroke
        ..strokeWidth = adjustedLineWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
          Offset(robot.scaledTarget.dx - 6 / scale, robot.scaledTarget.dy),
          Offset(robot.scaledTarget.dx + 6 / scale, robot.scaledTarget.dy),
          targetPointBrush);
      canvas.drawLine(
          Offset(robot.scaledTarget.dx, robot.scaledTarget.dy + 6 / scale),
          Offset(robot.scaledTarget.dx, robot.scaledTarget.dy - 6 / scale),
          targetPointBrush);
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
