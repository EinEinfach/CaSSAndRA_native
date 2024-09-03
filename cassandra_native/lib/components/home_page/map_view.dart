import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'dart:convert';

import 'package:cassandra_native/components/home_page/map_painter.dart';
import 'package:cassandra_native/components/home_page/map_button.dart';
import 'package:cassandra_native/components/home_page/play_button.dart';
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
  bool focusOnMowerActive = false;

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

  void focusOnMower(Offset position) {
    Size screenSize = MediaQuery.of(context).size;
    double currentScale = _transformationController.value.getMaxScaleOnAxis();

    double translateX = (screenSize.width / 2) - (position.dx * currentScale);
    double translateY = (screenSize.height / 2) - (position.dy * currentScale);

    _transformationController.value = Matrix4.identity()
      ..translate(translateX, translateY)
      ..scale(currentScale);
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
        widget.server.robot.status == 'transit' ||
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
      
      // focus on mower
      if (focusOnMowerActive) {
        focusOnMower(widget.server.robot.scaledPosition);
      }

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
                painter: MapPainter(
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MapButton(
              icon: Icons.zoom_in_map,
              onPressed: () {
                focusOnMowerActive = false;
                _transformationController.value = Matrix4.identity();
              },
            ),
            MapButton(
              icon: Icons.center_focus_weak_outlined,
              onPressed: () {
                focusOnMowerActive = !focusOnMowerActive;
                focusOnMower(widget.server.robot.scaledPosition);
              },
            ),
          ],
        ),
      ]);
    });
  }
}