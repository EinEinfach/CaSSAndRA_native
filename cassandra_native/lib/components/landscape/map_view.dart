import 'dart:math';

import 'package:cassandra_native/models/landscape.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'dart:convert';

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
  String currentMapId = '';
  String previewId = '';
  final TransformationController _transformationController =
      TransformationController();
  double baseLineWidth = 2;
  ui.Image? roverImage;
  Offset roverPostion = const Offset(0, 0);
  double roverRotation = 0;

  @override
  void dispose() {
    MqttManager.instance.disconnect(widget.server.id);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadImage('lib/images/rover0grad.png');
    _connectToServer();
    setState(() {
      mapForPlot = widget.server.currentMap.mapForPlot;
      currentMapId = widget.server.currentMap.mapId;
      previewId = widget.server.currentMap.previewId;
    });
  }

  void onMessageReceived(String topic, String message) {
    setState(() {
      if (topic.contains('/robot')) {
        widget.server.robot.jsonToClassData(message);
      } else if (topic.contains('/map')) {
        var decodedMessage = jsonDecode(message) as Map<String, dynamic>;
        String receivedMapId = decodedMessage['mapId'];
        String receivedPriviewId = decodedMessage['previewId'];
        if (receivedMapId != currentMapId) {
          MqttManager.instance.publish(
              widget.server.id,
              '${widget.server.serverNamePrefix}/api_cmd',
              '{"coords": {"command": "update", "value": ["currentMap"]}}');
          currentMapId = receivedMapId;
          widget.server.currentMap.mapId = receivedMapId;
        }
        else if (receivedPriviewId != previewId){
          MqttManager.instance.publish(
              widget.server.id,
              '${widget.server.serverNamePrefix}/api_cmd',
              '{"coords": {"command": "update", "value": ["preview"]}}');
          previewId = receivedPriviewId;
          widget.server.currentMap.previewId = receivedPriviewId;
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

  Future _connectToServer() async {
    await MqttManager.instance.connect(widget.server.mqttServer,
        widget.server.port, widget.server.id, onMessageReceived);
    MqttManager.instance
        .subscribe(widget.server.id, '${widget.server.serverNamePrefix}/robot');
    MqttManager.instance
        .subscribe(widget.server.id, '${widget.server.serverNamePrefix}/map');
    MqttManager.instance.subscribe(
        widget.server.id, '${widget.server.serverNamePrefix}/coords');
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
      widget.server.robot.scalePosition(scale, width, height, widget.server.currentMap);

      return InteractiveViewer(
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
              ),
            ),
          ),
        ),
      );
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

  const PolygonPainter({
    required this.currentMap,
    required this.colors,
    required this.transformationController,
    required this.lineWidth,
    required this.roverImage,
    required this.roverPosition,
    required this.roverRotation,
    required this.pxToMeter,
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

    var polygonBrush = Paint()
      ..color = colors.inversePrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = adjustedLineWidth;

    var exclusionsStrokeBrusch = Paint()
      ..color = colors.inversePrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = adjustedLineWidth;

    var exclusionsFillColor = Paint()
      ..color = colors.primary
      ..style = PaintingStyle.fill;

    var dockPathBrush = Paint()
      ..color = colors.onSurface
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8 * adjustedLineWidth;

    // draw perimeter
    var pathPerimeter = Path();
    pathPerimeter = drawPolygon(pathPerimeter, currentMap.scaledPerimeter);
    canvas.drawPath(pathPerimeter, polygonBrush);

    // draw exclusions
    var pathExclusions = Path();
    for (var exclusion in currentMap.scaledExclusions) {
      pathExclusions = drawPolygon(pathExclusions, exclusion);
    }
    canvas.drawPath(pathExclusions, exclusionsFillColor);
    canvas.drawPath(pathExclusions, exclusionsStrokeBrusch);

    // draw dockPath
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
