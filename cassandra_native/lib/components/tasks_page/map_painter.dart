import 'package:flutter/material.dart';

import 'package:cassandra_native/components/logic/lasso_logic.dart';
import 'package:cassandra_native/components/logic/tasks_logic.dart';
import 'package:cassandra_native/models/server.dart';
import 'package:cassandra_native/models/landscape.dart';
import 'package:cassandra_native/theme/theme.dart';

const double baseLineWidth = 2.0;

class MapPainter extends CustomPainter {
  final Offset offset;
  final double scale;
  final Server currentServer;
  final LassoLogic lasso;
  final Task currentTask;
  final ColorScheme colors;

  MapPainter({
    required this.offset,
    required this.scale,
    required this.currentServer,
    required this.lasso,
    required this.currentTask,
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

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);

    final adjustedLineWidth = baseLineWidth / scale;
    final Landscape currentMap = currentServer.currentMap;

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

    // draw tasks
    if (currentMap.tasks.selected.isNotEmpty) {
      PreviewColorPalette previewColorPalette = PreviewColorPalette();
      int previewCounter = 0;
      for (var taskName in currentMap.tasks.selected) {
        // draw routes
        Path pathTaskPreview = Path();
        if (currentMap.tasks.scaledPreviews.containsKey(taskName)) {
          strokeNoColor05.color = currentTask.active
              ? colors.onSurface.withOpacity(0.1)
              : previewColorPalette.colors[previewCounter];
          previewCounter++;
          previewCounter = previewCounter == previewColorPalette.colors.length
              ? 0
              : previewCounter;
          for (var task in currentMap.tasks.scaledPreviews[taskName]!) {
            pathTaskPreview = _drawLine(pathTaskPreview, task);
            canvas.drawPath(pathTaskPreview, strokeNoColor05);
          }
        }
      }
    }

    // draw tasks to edit
    if (currentTask.active) {
      PreviewColorPalette previewColorPalette = PreviewColorPalette();
      int previewCounter = 0;
      fillNoColor.color = colors.onSurface.withOpacity(0.5);
      for (var taskName in currentTask.selections.keys) {
        // draw selections
        Path pathTaskPreview = Path();
        Path pathTaskSelection = Path();
        strokeNoColor05.color =
            previewColorPalette.colors[previewCounter].withOpacity(0.6);
        previewCounter++;
        previewCounter = previewCounter == previewColorPalette.colors.length
            ? 0
            : previewCounter;
        for (var preview in currentTask.previews[taskName]!) {
          pathTaskPreview = _drawLine(pathTaskPreview, preview);
          canvas.drawPath(pathTaskPreview, strokeNoColor05);
        }
        for (var selection in currentTask.selections[taskName]!) {
          strokeNoColor05.color = taskName == currentTask.selectedTask
              ? colors.error
              : colors.onSurface.withOpacity(0.4);
          pathTaskSelection =
              _drawPolygonFromGeoJson(pathTaskSelection, selection);
          canvas.drawPath(pathTaskSelection, strokeNoColor05);
          for (var point in selection) {
            canvas.drawCircle(point, 2 / scale, fillNoColor);
          }
        }
      }
    }

    // draw selected task point
    if (currentTask.active &&
        currentTask.selectedTask != null &&
        currentTask.selectedSubtask != null &&
        currentTask.selectedPointIndex != null) {
      final selectedPoint = currentTask.selections[currentTask.selectedTask!]![
          currentTask.selectedSubtask!][currentTask.selectedPointIndex!];
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

    // fill selected task
    if (currentTask.active &&
        currentTask.selectedTask != null &&
        currentTask.selectedPointIndex == null) {
      fillNoColor.color = colors.onSurface.withOpacity(0.4);
      Path pathTaskSelection = Path();
      pathTaskSelection = _drawPolygonFromGeoJson(
          pathTaskSelection,
          currentTask.selections[currentTask.selectedTask!]![
              currentTask.selectedSubtask!]);
      canvas.drawPath(pathTaskSelection, fillNoColor);
    }

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

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
