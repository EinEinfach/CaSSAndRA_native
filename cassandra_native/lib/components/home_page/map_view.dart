import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:math';

import 'package:cassandra_native/components/home_page/map_button.dart';
import 'package:cassandra_native/components/home_page/play_button.dart';
import 'package:cassandra_native/models/landscape.dart';
import 'package:cassandra_native/models/server.dart';
import 'package:cassandra_native/comm/mqtt_manager.dart';

// later make rover image selectable in settings
const minRoverImageSize = 20.0;

class MapView extends StatefulWidget {
  final Server server;

  const MapView({super.key, required this.server});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  String serverData = '';
  List<List<Offset>> mapForPlot = [[]];
  final TransformationController _transformationController =
      TransformationController();
  double baseLineWidth = 2;
  ui.Image? roverImage;
  Offset roverPostion = const Offset(0, 0);
  double roverRotation = 0;
  late IconData playButtonIcon;

  @override
  void dispose() {
    //MqttManager.instance.disconnect(widget.server.id);
    MqttManager.instance
        .unregisterCallback(widget.server.id, onMessageReceived);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadImage('lib/images/rover0grad.png');
    _registerCallback();
    setState(() {
      mapForPlot = widget.server.currentMap.mapForPlot;
      playButtonIcon = _createPlayButtonIcon();
    });
  }

  void onMessageReceived(String clientId, String topic, String message) {
    setState(() {
      if (topic.contains('/robot')) {
        widget.server.robot.jsonToClassData(message);
        playButtonIcon = _createPlayButtonIcon();
      } else if (topic.contains('/map')) {
        var decodedMessage = jsonDecode(message) as Map<String, dynamic>;
        String receivedMapId = decodedMessage['mapId'];
        String receivedPreviewId = decodedMessage['previewId'];
        String receivedMowPathId = decodedMessage['mowPathId'];
        if (receivedMapId != widget.server.currentMap.mapId) {
          MqttManager.instance.publish(
              widget.server.id,
              '${widget.server.serverNamePrefix}/api_cmd',
              '{"coords": {"command": "update", "value": ["currentMap"]}}');
        } else if (receivedPreviewId != widget.server.currentMap.previewId) {
          MqttManager.instance.publish(
              widget.server.id,
              '${widget.server.serverNamePrefix}/api_cmd',
              '{"coords": {"command": "update", "value": ["preview"]}}');
        } else if (receivedMowPathId != widget.server.currentMap.mowPathId) {
          MqttManager.instance.publish(
              widget.server.id,
              '${widget.server.serverNamePrefix}/api_cmd',
              '{"coords": {"command": "update", "value": ["mowPath"]}}');
        }
      } else if (topic.contains('/coords')) {
        widget.server.currentMap.jsonToClassData(message);
        mapForPlot = widget.server.currentMap.mapForPlot;
      }
    });
  }

  Future<void> _loadImage(String asset) async {
    // load rover image
    final data = await rootBundle.load(asset);
    final list = Uint8List.view(data.buffer);
    final codec = await ui.instantiateImageCodec(list);
    final frame = await codec.getNextFrame();
    roverImage = frame.image;
    setState(() {
      roverImage;
    });
  }

  void _registerCallback() {
    MqttManager.instance.registerCallback(widget.server.id, onMessageReceived);
  }

  IconData _createPlayButtonIcon() {
    if (widget.server.robot.status == 'mow' ||
        widget.server.robot.status == 'docking') {
      return Icons.pause;
    } else {
      return Icons.play_arrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    return LayoutBuilder(builder: (context, constraints) {
      // calc container size
      final width = constraints.maxWidth;
      final height = constraints.maxHeight;

      // calc new min an max coords
      final shiftedMaxX = widget.server.currentMap.shiftedMaxX;
      final shiftedMaxY = widget.server.currentMap.shiftedMaxY;

      // calc scale factor 1:1 depends on container size and maxZoom factor
      double scale = 1.0;
      double maxZoom;
      if (shiftedMaxX / shiftedMaxY > width / height) {
        scale = width / shiftedMaxX;
        maxZoom = shiftedMaxX;
      } else {
        scale = height / shiftedMaxY;
        maxZoom = shiftedMaxY;
      }
      if (maxZoom == -double.infinity) {
        maxZoom = 1;
      }

      // calc coords for canvas
      widget.server.currentMap.scaleShapes(scale, width, height);
      widget.server.currentMap.scalePreview(scale);
      widget.server.currentMap.scaleMowPath(scale);
      widget.server.robot
          .scalePosition(scale, width, height, widget.server.currentMap);

      return Stack(children: [
        InteractiveViewer(
          transformationController: _transformationController,
          boundaryMargin: const EdgeInsets.all(double.infinity),
          minScale: 0.8,
          maxScale: maxZoom,
          child: SizedBox(
            width: screenSize.width,
            height: screenSize.height,
            child: AspectRatio(
              aspectRatio: 1,
              child: CustomPaint(
                painter: PolygonPainter(
                  currentMap: widget.server.currentMap,
                  colors: Theme.of(context).colorScheme,
                  transformationController: _transformationController,
                  lineWidth: baseLineWidth,
                  roverImage: roverImage,
                  roverPosition: widget.server.robot.scaledPosition,
                  roverRotation: widget.server.robot.angle,
                  pxToMeter: scale,
                  mowPointIdx: widget.server.robot.mowPointIdx,
                ),
              ),
            ),
          ),
        ),
        PlayButton(icon: playButtonIcon),
        MapButton(
          icon: Icons.zoom_in_map,
          verticalAligment: -1,
          horizontalAlignment: 0,
          onPressed: () {
            _transformationController.value = Matrix4.identity();
          },
        ),
      ]);
    });
  }
}

class PolygonPainter extends CustomPainter {
  final Landscape currentMap;
  final ColorScheme colors;
  final TransformationController transformationController;
  final double lineWidth;
  final ui.Image? roverImage;
  final Offset roverPosition;
  final double roverRotation;
  final double pxToMeter;
  final int mowPointIdx;

  const PolygonPainter({
    required this.currentMap,
    required this.colors,
    required this.transformationController,
    required this.lineWidth,
    required this.roverImage,
    required this.roverPosition,
    required this.roverRotation,
    required this.pxToMeter,
    required this.mowPointIdx,
  });

  Path drawPolygon(Path path, List<Offset> points) {
    if (points.isNotEmpty) {
      path.moveTo(points[0].dx, points[0].dy);
      for (var point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      path.close;
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
    final scale = transformationController.value.getMaxScaleOnAxis();
    final adjustedLineWidth = lineWidth / scale;

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
