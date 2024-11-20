import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math';

import 'package:cassandra_native/models/server.dart';
import 'package:cassandra_native/models/maps.dart';
import 'package:cassandra_native/components/logic/map_logic.dart';

// should be refactored to make rover size selectable
const double minRoverImageSize = 20;
const double baseLineWidth = 2.0;

class MapPainter extends CustomPainter {
  final Offset offset;
  final double scale;
  final ui.Image? roverImage;
  final Server currentServer;
  final ShapeLogic shapes;
  final LassoLogic lasso;
  final RecorderLogic recoderLogic;
  final ColorScheme colors;
  final Offset currentPostion;
  final double currentAngle;

  const MapPainter({
    required this.offset,
    required this.scale,
    required this.roverImage,
    required this.currentServer,
    required this.shapes,
    required this.lasso,
    required this.recoderLogic,
    required this.currentPostion,
    required this.currentAngle,
    required this.colors,
  });

  Path drawPolygon(Path path, List<Offset> points) {
    if (points.isNotEmpty) {
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
    final Maps maps = currentServer.maps;

    // draw perimeter
    var polygonBrush = Paint()
      ..color = shapes.active
          ? colors.inversePrimary.withOpacity(0.15)
          : colors.inversePrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = adjustedLineWidth;

    Path pathPerimeter = Path();
    pathPerimeter = drawPolygonFromGeoJson(pathPerimeter, maps.scaledPerimeter);
    canvas.drawPath(pathPerimeter, polygonBrush);

    if (shapes.active) {
      var polygonBrush = Paint()
        ..color = shapes.selectedShape == 'perimeter'
            ? colors.error
            : colors.inversePrimary
        ..style = PaintingStyle.stroke
        ..strokeWidth = adjustedLineWidth;

      pathPerimeter = Path();
      pathPerimeter = drawPolygonFromGeoJson(pathPerimeter, shapes.perimeter);
      canvas.drawPath(pathPerimeter, polygonBrush);

      polygonBrush = Paint()
        ..color = colors.onSurface
        ..style = PaintingStyle.fill;
      for (int i = 0; i < shapes.perimeter.length - 1; i++) {
        canvas.drawCircle(shapes.perimeter[i], 2 / scale, polygonBrush);
      }

      if (shapes.selectedShape == 'perimeter' &&
          shapes.selectedPointIndex != null) {
        final selectedPoint = shapes.perimeter[shapes.selectedPointIndex!];
        var selectedPointBrush = Paint()
          ..color = colors.error
          ..style = PaintingStyle.stroke
          ..strokeWidth = adjustedLineWidth
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
            Offset(selectedPoint.dx - 6 / scale, selectedPoint.dy),
            Offset(selectedPoint.dx + 6 / scale, selectedPoint.dy),
            selectedPointBrush);
        canvas.drawLine(
            Offset(selectedPoint.dx, selectedPoint.dy - 6 / scale),
            Offset(selectedPoint.dx, selectedPoint.dy + 6 / scale),
            selectedPointBrush);
      }
      if (shapes.selectedShape == 'perimeter' && shapes.selectedPointIndex == null) {
        var perimeterFillColor = Paint()
          ..color = colors.onSurface.withOpacity(0.4)
          ..style = PaintingStyle.fill;
        canvas.drawPath(pathPerimeter, perimeterFillColor);
      } 
    }

    // draw exclusions
    var exclusionsStrokeBrusch = Paint()
      ..color = shapes.active
          ? colors.inversePrimary.withOpacity(0.15)
          : colors.inversePrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = adjustedLineWidth;

    var exclusionsFillColor = Paint()
      ..color = colors.secondary.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    Path pathExclusions = Path();
    for (var exclusion in maps.scaledExclusions) {
      pathExclusions = drawPolygonFromGeoJson(pathExclusions, exclusion);
    }
    canvas.drawPath(pathExclusions, exclusionsFillColor);
    canvas.drawPath(pathExclusions, exclusionsStrokeBrusch);

    if (shapes.active) {
      exclusionsStrokeBrusch = Paint()
        ..color = shapes.selectedShape == 'exclusion'
            ? colors.error
            : colors.inversePrimary
        ..style = PaintingStyle.stroke
        ..strokeWidth = adjustedLineWidth;

      pathExclusions = Path();
      for (var exclusion in shapes.exclusions) {
        pathExclusions = drawPolygonFromGeoJson(pathExclusions, exclusion);
      }
      canvas.drawPath(pathExclusions, exclusionsStrokeBrusch);

      exclusionsStrokeBrusch = Paint()
        ..color = colors.onSurface
        ..style = PaintingStyle.fill;
      for (var exclusion in shapes.exclusions) {
        for (int i = 0; i < exclusion.length - 1; i++) {
          canvas.drawCircle(exclusion[i], 2 / scale, exclusionsStrokeBrusch);
        }
      }

      if (shapes.selectedShape == 'exclusion' &&
          shapes.selectedExclusionIndex != null &&
          shapes.selectedPointIndex != null) {
        final selectedPoint = shapes.exclusions[shapes.selectedExclusionIndex!]
            [shapes.selectedPointIndex!];
        var selectedPointBrush = Paint()
          ..color = colors.error
          ..style = PaintingStyle.stroke
          ..strokeWidth = adjustedLineWidth
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
            Offset(selectedPoint.dx - 6 / scale, selectedPoint.dy),
            Offset(selectedPoint.dx + 6 / scale, selectedPoint.dy),
            selectedPointBrush);
        canvas.drawLine(
            Offset(selectedPoint.dx, selectedPoint.dy - 6 / scale),
            Offset(selectedPoint.dx, selectedPoint.dy + 6 / scale),
            selectedPointBrush);
      }
      if (shapes.selectedShape == 'exclusion' && shapes.selectedPointIndex == null && shapes.selectedExclusionIndex != null) {
        Path pathSelectedExclusion = Path();
        pathSelectedExclusion = drawPolygonFromGeoJson(pathSelectedExclusion, shapes.exclusions[shapes.selectedExclusionIndex!]);
        var exclusionSelectedFillColor = Paint()
          ..color = colors.onSurface.withOpacity(0.4)
          ..style = PaintingStyle.fill;
        canvas.drawPath(pathSelectedExclusion, exclusionSelectedFillColor);
      } 
    }

    // draw dockPath and search wire
    var dockPathBrush = Paint()
      ..color =
          shapes.active ? colors.onSurface.withOpacity(0.15) : colors.onSurface
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5 * adjustedLineWidth;

    var searchWireBrush = Paint()
      ..color =
          shapes.active ? colors.onSurface.withOpacity(0.15) : colors.onSurface
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5 * adjustedLineWidth;

    Path pathDock = Path();
    pathDock = drawLine(pathDock, maps.scaledDockPath);
    canvas.drawPath(pathDock, dockPathBrush);

    Path pathSearchWire = Path();
    pathSearchWire = drawLine(pathSearchWire, maps.scaledSearchWire);
    canvas.drawPath(pathSearchWire, searchWireBrush);

    if (shapes.active) {
      dockPathBrush = Paint()
        ..color = shapes.selectedShape == 'dockPath'
            ? colors.error
            : colors.inversePrimary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5 * adjustedLineWidth;

      pathDock = Path();
      pathDock = drawLine(pathDock, shapes.dockPath);
      canvas.drawPath(pathDock, dockPathBrush);

      searchWireBrush = Paint()
        ..color = shapes.selectedShape == 'searchWire'
            ? colors.error
            : colors.inversePrimary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5 * adjustedLineWidth;

      pathSearchWire = Path();
      pathSearchWire = drawLine(pathSearchWire, shapes.searchWire);
      canvas.drawPath(pathSearchWire, searchWireBrush);

      dockPathBrush = Paint()
        ..color = colors.onSurface
        ..style = PaintingStyle.fill;
      for (Offset point in shapes.dockPath) {
        canvas.drawCircle(point, 2 / scale, dockPathBrush);
      }
      for (Offset point in shapes.searchWire) {
        canvas.drawCircle(point, 2 / scale, dockPathBrush);
      }

      if (shapes.selectedShape == 'dockPath' &&
          shapes.selectedPointIndex != null) {
        final selectedPoint = shapes.dockPath[shapes.selectedPointIndex!];
        var selectedPointBrush = Paint()
          ..color = colors.error
          ..style = PaintingStyle.stroke
          ..strokeWidth = adjustedLineWidth
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
            Offset(selectedPoint.dx - 6 / scale, selectedPoint.dy),
            Offset(selectedPoint.dx + 6 / scale, selectedPoint.dy),
            selectedPointBrush);
        canvas.drawLine(
            Offset(selectedPoint.dx, selectedPoint.dy - 6 / scale),
            Offset(selectedPoint.dx, selectedPoint.dy + 6 / scale),
            selectedPointBrush);
      }

      if (shapes.selectedShape == 'searchWire' &&
          shapes.selectedPointIndex != null) {
        final selectedPoint = shapes.searchWire[shapes.selectedPointIndex!];
        var selectedPointBrush = Paint()
          ..color = colors.error
          ..style = PaintingStyle.stroke
          ..strokeWidth = adjustedLineWidth
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
            Offset(selectedPoint.dx - 6 / scale, selectedPoint.dy),
            Offset(selectedPoint.dx + 6 / scale, selectedPoint.dy),
            selectedPointBrush);
        canvas.drawLine(
            Offset(selectedPoint.dx, selectedPoint.dy - 6 / scale),
            Offset(selectedPoint.dx, selectedPoint.dy + 6 / scale),
            selectedPointBrush);
      }
    }

    // draw lassoSelection
    if (lasso.selection.isNotEmpty) {
      var lassoSelectionBrush = Paint()
        ..color = lasso.selectedPointIndex != null
            ? colors.error
            : colors.onSurface.withOpacity(0.4)
        ..style = lasso.selected ? PaintingStyle.fill : PaintingStyle.stroke
        ..strokeWidth = 0.5 * adjustedLineWidth;
      Path pathLassoSelection = Path();
      if (lasso.selectedShape == 'polygon') {
        pathLassoSelection = drawPolygon(pathLassoSelection, lasso.selection);
      } else {
        pathLassoSelection = drawLine(pathLassoSelection, lasso.selection);
      }
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

    // draw new shape
    if (recoderLogic.coordinates.isNotEmpty) {
      var recorderBrush = Paint()
        ..color = colors.onSurface.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5 * adjustedLineWidth;
      Path pathRecordedShape = Path();
      if (recoderLogic.selectedShape == 'polygon') {
        pathRecordedShape =
            drawPolygon(pathRecordedShape, recoderLogic.coordinates);
      } else {
        pathRecordedShape =
            drawLine(pathRecordedShape, recoderLogic.coordinates);
      }
      canvas.drawPath(pathRecordedShape, recorderBrush);
    }

    // draw position point
    var positionPointBrush = Paint()
      ..color = colors.error
      ..style = PaintingStyle.stroke
      ..strokeWidth = adjustedLineWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        Offset(currentPostion.dx - 6 / scale, currentPostion.dy),
        Offset(currentPostion.dx + 6 / scale, currentPostion.dy),
        positionPointBrush);
    canvas.drawLine(
        Offset(currentPostion.dx, currentPostion.dy - 6 / scale),
        Offset(currentPostion.dx, currentPostion.dy + 6 / scale),
        positionPointBrush);

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
        canvas: canvas,
        rect: rect,
        image: roverImage!,
        fit: BoxFit.cover,
        colorFilter:
            ColorFilter.mode(Colors.white.withOpacity(0.5), BlendMode.modulate),
      );

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
