import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math';

import 'package:cassandra_native/models/server.dart';
import 'package:cassandra_native/models/maps.dart';
import 'package:cassandra_native/components/logic/map_logic.dart';
import 'package:cassandra_native/components/logic/lasso_logic.dart';
import 'package:cassandra_native/components/logic/shapes_logic.dart';

// should be refactored to make rover size selectable
const double minRoverImageSize = 20;
const double baseLineWidth = 2.0;

class MapPainter extends CustomPainter {
  final Offset offset;
  final double scale;
  final ui.Image? roverImage;
  final Server currentServer;
  final Shapes shapes;
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
    final Maps maps = currentServer.maps;

    // brushes
    // strokes
    var strokeNoColor05 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5 * adjustedLineWidth;

    var strokeNoColor10 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = adjustedLineWidth;

    // stroke with round caps
    var strokeRoundCapsNoColor10 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = adjustedLineWidth
      ..strokeCap = StrokeCap.round;

    // fills
    var fillNoColor = Paint()..style = PaintingStyle.fill;

    // draw perimeter
    strokeNoColor10.color = shapes.active
        ? colors.inversePrimary.withOpacity(0.15)
        : colors.inversePrimary;
    Path pathPerimeter = Path();
    pathPerimeter = _drawPolygonFromGeoJson(pathPerimeter, maps.scaledPerimeter);
    canvas.drawPath(pathPerimeter, strokeNoColor10);

    if (shapes.active) {
      strokeNoColor10.color = shapes.selectedShape == 'perimeter'
          ? colors.error
          : colors.inversePrimary;
      pathPerimeter = Path();
      pathPerimeter = _drawPolygonFromGeoJson(pathPerimeter, shapes.perimeter);
      canvas.drawPath(pathPerimeter, strokeNoColor10);

      fillNoColor.color = colors.onSurface;
      for (int i = 0; i < shapes.perimeter.length - 1; i++) {
        canvas.drawCircle(shapes.perimeter[i], 2 / scale, fillNoColor);
      }

      if (shapes.selectedShape == 'perimeter' &&
          shapes.selectedPointIndex != null) {
        final selectedPoint = shapes.perimeter[shapes.selectedPointIndex!];
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
      if (shapes.selectedShape == 'perimeter' &&
          shapes.selectedPointIndex == null) {
        fillNoColor.color = colors.onSurface.withOpacity(0.4);
        canvas.drawPath(pathPerimeter, fillNoColor);
      }
    }

    // draw exclusions
    strokeNoColor10.color = shapes.active
        ? colors.inversePrimary.withOpacity(0.15)
        : colors.inversePrimary;
    fillNoColor.color = colors.secondary.withOpacity(0.7);
    Path pathExclusions = Path();
    for (var exclusion in maps.scaledExclusions) {
      pathExclusions = _drawPolygonFromGeoJson(pathExclusions, exclusion);
    }
    canvas.drawPath(pathExclusions, fillNoColor);
    canvas.drawPath(pathExclusions, strokeNoColor10);

    if (shapes.active) {
      strokeNoColor10.color = shapes.selectedShape == 'exclusion'
          ? colors.error
          : colors.inversePrimary;
      pathExclusions = Path();
      for (var exclusion in shapes.exclusions) {
        pathExclusions = _drawPolygonFromGeoJson(pathExclusions, exclusion);
      }
      canvas.drawPath(pathExclusions, strokeNoColor10);

      fillNoColor.color = colors.onSurface;
      for (var exclusion in shapes.exclusions) {
        for (int i = 0; i < exclusion.length - 1; i++) {
          canvas.drawCircle(exclusion[i], 2 / scale, fillNoColor);
        }
      }

      if (shapes.selectedShape == 'exclusion' &&
          shapes.selectedExclusionIndex != null &&
          shapes.selectedPointIndex != null) {
        final selectedPoint = shapes.exclusions[shapes.selectedExclusionIndex!]
            [shapes.selectedPointIndex!];
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
      if (shapes.selectedShape == 'exclusion' &&
          shapes.selectedPointIndex == null &&
          shapes.selectedExclusionIndex != null) {
        Path pathSelectedExclusion = Path();
        pathSelectedExclusion = _drawPolygonFromGeoJson(pathSelectedExclusion,
            shapes.exclusions[shapes.selectedExclusionIndex!]);
        fillNoColor.color = colors.onSurface.withOpacity(0.4);
        canvas.drawPath(pathSelectedExclusion, fillNoColor);
      }
    }

    // draw dockPath and search wire
    strokeNoColor05.color =
        shapes.active ? colors.onSurface.withOpacity(0.15) : colors.onSurface;
    Path pathDock = Path();
    pathDock = _drawLine(pathDock, maps.scaledDockPath);
    canvas.drawPath(pathDock, strokeNoColor05);

    Path pathSearchWire = Path();
    pathSearchWire = _drawLine(pathSearchWire, maps.scaledSearchWire);
    canvas.drawPath(pathSearchWire, strokeNoColor05);

    if (shapes.active) {
      strokeNoColor05.color = shapes.selectedShape == 'dockPath'
          ? colors.error
          : colors.inversePrimary;
      pathDock = Path();
      pathDock = _drawLine(pathDock, shapes.dockPath);
      canvas.drawPath(pathDock, strokeNoColor05);

      strokeNoColor05.color = shapes.selectedShape == 'searchWire'
          ? colors.error
          : colors.inversePrimary;
      pathSearchWire = Path();
      pathSearchWire = _drawLine(pathSearchWire, shapes.searchWire);
      canvas.drawPath(pathSearchWire, strokeNoColor05);

      fillNoColor.color = colors.onSurface;
      for (Offset point in shapes.dockPath) {
        canvas.drawCircle(point, 2 / scale, fillNoColor);
      }
      for (Offset point in shapes.searchWire) {
        canvas.drawCircle(point, 2 / scale, fillNoColor);
      }

      if (shapes.selectedShape == 'dockPath' &&
          shapes.selectedPointIndex != null) {
        final selectedPoint = shapes.dockPath[shapes.selectedPointIndex!];
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

      if (shapes.selectedShape == 'searchWire' &&
          shapes.selectedPointIndex != null) {
        final selectedPoint = shapes.searchWire[shapes.selectedPointIndex!];
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
    }

    // draw lassoSelection
    if (lasso.selection.isNotEmpty) {
      strokeNoColor05.color = lasso.selectedPointIndex != null
          ? colors.error
          : colors.onSurface.withOpacity(0.4);
      Path pathLassoSelection = Path();
      pathLassoSelection = lasso.selectedShape == 'polygon'
          ? _drawPolygon(pathLassoSelection, lasso.selection)
          : _drawLine(pathLassoSelection, lasso.selection);
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

    // draw new shape
    if (recoderLogic.coordinates.isNotEmpty) {
      strokeNoColor05.color = colors.onSurface.withOpacity(0.4);
      Path pathRecordedShape = Path();
      if (recoderLogic.selectedShape == 'polygon') {
        pathRecordedShape =
            _drawPolygon(pathRecordedShape, recoderLogic.coordinates);
      } else {
        pathRecordedShape =
            _drawLine(pathRecordedShape, recoderLogic.coordinates);
      }
      canvas.drawPath(pathRecordedShape, strokeNoColor05);
    }

    // draw position point
    strokeRoundCapsNoColor10.color = colors.error;
    canvas.drawLine(
        Offset(currentPostion.dx - 6 / scale, currentPostion.dy),
        Offset(currentPostion.dx + 6 / scale, currentPostion.dy),
        strokeRoundCapsNoColor10);
    canvas.drawLine(
        Offset(currentPostion.dx, currentPostion.dy - 6 / scale),
        Offset(currentPostion.dx, currentPostion.dy + 6 / scale),
        strokeRoundCapsNoColor10);

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
