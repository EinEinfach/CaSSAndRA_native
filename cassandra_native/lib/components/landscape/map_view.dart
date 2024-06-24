import 'dart:math';

import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'dart:convert';

import 'package:cassandra_native/models/server.dart';
import 'package:cassandra_native/comm/mqtt_manager.dart';

// later make rover image selectable in settings
const minRoverImageSize = 30.0;

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
  final TransformationController _transformationController =
      TransformationController();
  double minX = double.infinity,
      minY = double.infinity,
      maxX = double.negativeInfinity,
      maxY = double.negativeInfinity;
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
      roverPostion = Offset(
          widget.server.robot.position.x, widget.server.robot.position.y);
      roverRotation = widget.server.robot.angle;
      mapForPlot = widget.server.currentMap.mapForPlot;
      currentMapId = widget.server.currentMap.mapId;
    });
  }

  void onMessageReceived(String topic, String message) {
    setState(() {
      if (topic.contains('/robot')) {
        var decodedMessage = jsonDecode(message) as Map<String, dynamic>;
        widget.server.robot.position.x = decodedMessage['position']['x'];
        widget.server.robot.position.y = decodedMessage['position']['y'];
        widget.server.robot.angle = decodedMessage['angle'];
        roverPostion = Offset(
            widget.server.robot.position.x, widget.server.robot.position.y);
        roverRotation = widget.server.robot.angle;
      } else if (topic.contains('/map')) {
        var decodedMessage = jsonDecode(message) as Map<String, dynamic>;
        String receivedMapId = decodedMessage['mapId'];
        if (receivedMapId != currentMapId) {
          MqttManager.instance.publish(
              widget.server.id,
              '${widget.server.serverNamePrefix}/api_cmd',
              '{"coords": {"command": "update", "value": ["currentMap"]}}');
          currentMapId = receivedMapId;
          widget.server.currentMap.mapId = receivedMapId;
        }
      } else if (topic.contains('/coords')) {
        widget.server.currentMap.jsonToCoords(message);
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
    await MqttManager.instance
        .connect(widget.server.mqttServer, widget.server.id, onMessageReceived);
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

      // look for min an max coordinates
      for (var polygon in mapForPlot) {
        for (var point in polygon) {
          if (point.dx < minX) minX = point.dx;
          if (point.dy < minY) minY = point.dy;
          if (point.dx > maxX) maxX = point.dx;
          if (point.dy > maxY) maxY = point.dy;
        }
      }

      // shift min coords to 0,0
      final shiftedPolygons = mapForPlot
          .map((polygon) =>
              polygon.map((p) => Offset(p.dx - minX, -(p.dy - minY))).toList())
          .toList();

      // calc new min an max coords
      final shiftedMaxX = maxX - minX;
      final shiftedMaxY = maxY - minY;

      // calc scale factor 1:1 depends on container size and maxZoom factor
      double scale = 1.0;
      double maxZoom = 1.0;
      if (shiftedMaxX / shiftedMaxY > width / height){
        scale = width / shiftedMaxX;
        maxZoom = shiftedMaxX;
      }else {
        scale = height / shiftedMaxY;
        maxZoom = shiftedMaxY;
      }
      
      // final scale = (shiftedMaxX / shiftedMaxY) > (width / height)
      //     ? width / shiftedMaxX
      //     : height / shiftedMaxY;

      // calc coords for canvas
      final scaledPolygons = shiftedPolygons
          .map((polygon) =>
              polygon.map((p) => Offset(p.dx * scale, p.dy * scale)).toList())
          .toList();

      //
      final offsetX = (width - shiftedMaxX * scale) / 2;
      final offsetY = (height + shiftedMaxY * scale) / 2;

      final centeredPolygons = scaledPolygons
          .map((polygon) => polygon
              .map((p) => Offset(p.dx + offsetX, p.dy + offsetY))
              .toList())
          .toList();

      // calc rover postion for canvas
      Offset shiftedRoverPosition = Offset(width / 2, height / 2);
      if (mapForPlot[0].isNotEmpty) {
        shiftedRoverPosition = Offset(
            (roverPostion.dx - minX) * scale + offsetX,
            (-(roverPostion.dy - minY)) * scale + offsetY);
      }

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
                polygons: centeredPolygons,
                colors: Theme.of(context).colorScheme,
                transformationController: _transformationController,
                lineWidth: baseLineWidth,
                roverImage: roverImage,
                roverPosition: shiftedRoverPosition,
                roverRotation: roverRotation,
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
  final List<List<Offset>> polygons;
  final ColorScheme colors;
  final TransformationController transformationController;
  final double lineWidth;
  final ui.Image? roverImage;
  final Offset roverPosition;
  final double roverRotation;
  final double pxToMeter;

  const PolygonPainter({
    required this.polygons,
    required this.colors,
    required this.transformationController,
    required this.lineWidth,
    required this.roverImage,
    required this.roverPosition,
    required this.roverRotation,
    required this.pxToMeter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = transformationController.value.getMaxScaleOnAxis();
    final adjustedLineWidth = lineWidth / scale;

    var polygonBrush = Paint()
      ..color = colors.inversePrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = adjustedLineWidth;

    // check if perimeter empty
    if (polygons[0].isNotEmpty) {
      for (var points in polygons) {
        final path = Path();
        if (points.isNotEmpty) {
          path.moveTo(points[0].dx, points[0].dy);
          for (var point in points.skip(1)) {
            path.lineTo(point.dx, point.dy);
          }
          path.close();
        }
        canvas.drawPath(path, polygonBrush);
      }
    }

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
