import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math';

import 'package:cassandra_native/models/landscape.dart';

// later make rover image selectable in settings
const minRoverImageSize = 20.0;

class MapPainter extends CustomPainter {
  final bool interactiveViewerActive;
  final Landscape currentMap;
  final ColorScheme colors;
  final TransformationController transformationController;
  final Matrix4 transformationControllerValue;
  final double lineWidth;
  final ui.Image? roverImage;
  final Offset roverPosition;
  final double roverRotation;
  final double pxToMeter;
  final int mowPointIdx;
  final List<Offset> lassoSelection;

  const MapPainter({
    required this.interactiveViewerActive,
    required this.currentMap,
    required this.colors,
    required this.transformationController,
    required this.transformationControllerValue,
    required this.lineWidth,
    required this.roverImage,
    required this.roverPosition,
    required this.roverRotation,
    required this.pxToMeter,
    required this.mowPointIdx,
    required this.lassoSelection,
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

  @override
  void paint(Canvas canvas, Size size) {
    late double scale;
    if (interactiveViewerActive) {
      scale = transformationController.value.getMaxScaleOnAxis();
    } else {
      scale = transformationControllerValue.getMaxScaleOnAxis();
      canvas.transform(transformationControllerValue.storage);
    }
    
    final adjustedLineWidth = lineWidth / scale;
    //canvas.transform(transformationControllerValue.storage);

    // draw perimeter
    var polygonBrush = Paint()
      ..color = colors.inversePrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = adjustedLineWidth;

    var pathPerimeter = Path();
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

    var pathExclusions = Path();
    for (var exclusion in currentMap.scaledExclusions) {
      pathExclusions = drawPolygon(pathExclusions, exclusion);
    }
    canvas.drawPath(pathExclusions, exclusionsFillColor);
    canvas.drawPath(pathExclusions, exclusionsStrokeBrusch);

    // draw preview
    var previewBrush = Paint()
      ..color = Color.fromARGB(255, 113, 161, 143)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5 * adjustedLineWidth;

    var pathPreview = Path();
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
      var pathMowPathFinished = Path();
      pathMowPathFinished = drawLine(pathMowPathFinished,
          currentMap.scaledMowPath.sublist(0, mowPointIdx + 1));
      canvas.drawPath(pathMowPathFinished, mowPathFinishedBrush);

      // unfinished
      var pathMowPath = Path();
      pathMowPath =
          drawLine(pathMowPath, currentMap.scaledMowPath.sublist(mowPointIdx));
      canvas.drawPath(pathMowPath, mowPathBrush);

      // current
      if (mowPointIdx > 0) {
        double dashWidth = 2.0;
        double dashSpace = 2.0;
        double distance = (currentMap.scaledMowPath[mowPointIdx] -
                currentMap.scaledMowPath[mowPointIdx - 1])
            .distance;
        Offset direction = (currentMap.scaledMowPath[mowPointIdx] -
                currentMap.scaledMowPath[mowPointIdx - 1]) /
            distance;
        double currentDistance = 0;
        while (currentDistance < distance) {
          final currentStart = currentMap.scaledMowPath[mowPointIdx - 1] +
              direction * currentDistance;
          final currentEnd = currentMap.scaledMowPath[mowPointIdx - 1] +
              direction * (currentDistance + dashWidth);
          if ((currentDistance + dashWidth) <= distance) {
            canvas.drawLine(currentStart, currentEnd, mowPathCurrent);
          }
          currentDistance += dashWidth + dashSpace;
        }
      }
    }

    // draw dockPath
    var dockPathBrush = Paint()
      ..color = colors.onSurface
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8 * adjustedLineWidth;

    var pathDock = Path();
    pathDock = drawLine(pathDock, currentMap.scaledDockPath);
    canvas.drawPath(pathDock, dockPathBrush);

    // draw searchWire
    var pathSearchWire = Path();
    pathSearchWire = drawLine(pathSearchWire, currentMap.scaledSearchWire);
    canvas.drawPath(pathSearchWire, dockPathBrush);

    // draw lassoSelection
    if (lassoSelection.isNotEmpty) {
      var lassoSelectionBrush = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5 * adjustedLineWidth;
      Path pathLassoSelection = Path();
      pathLassoSelection = drawPolygon(pathLassoSelection, lassoSelection);
      canvas.drawPath(pathLassoSelection, lassoSelectionBrush);
    }

    // draw rower image
    if (roverImage != null) {
      double imageSize = 1 * pxToMeter;
      imageSize = max(imageSize, minRoverImageSize);

      // rotate rover image
      canvas.save();
      canvas.translate(roverPosition.dx, roverPosition.dy);
      canvas.rotate(-roverRotation);
      canvas.translate(-roverPosition.dx, -roverPosition.dy);

      final rect = Rect.fromCenter(
          center: roverPosition, width: imageSize, height: imageSize);
      paintImage(
          canvas: canvas, rect: rect, image: roverImage!, fit: BoxFit.cover);

      // restore saved canvas
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
