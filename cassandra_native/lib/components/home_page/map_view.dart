import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:math';
import 'package:vector_math/vector_math_64.dart' as vmath;

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
  final TransformationController _transformationController =
      TransformationController();
  Matrix4 currentTransformation = Matrix4.identity();
  double baseLineWidth = 2;
  ui.Image? roverImage;
  Offset roverPostion = const Offset(0, 0);
  double roverRotation = 0;
  late IconData playButtonIcon;
  bool focusOnMowerActive = false;
  bool lassoSelectionActive = false;
  List<Offset> lassoSelection = [];

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
      //mapForPlot = widget.server.currentMap.mapForPlot;
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
        //mapForPlot = widget.server.currentMap.mapForPlot;
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
        GestureDetector(
          onPanStart: (_) {
            if (lassoSelectionActive) {
              setState(() {
                lassoSelection = [];
              });
            }
          },
          onPanUpdate: (details) {
            if (lassoSelectionActive) {
              setState(() {
                RenderBox renderBox = context.findRenderObject() as RenderBox;
                Offset localPosition =
                    renderBox.globalToLocal(details.globalPosition);

                Offset transformedPosition = _applyInverseMatrixTransformation(
                    localPosition, currentTransformation);
                lassoSelection.add(transformedPosition);
                lassoSelection = simplifyPath(lassoSelection, 0.3);
              });
            }
          },
          onPanEnd: (_) {
            if (lassoSelectionActive) {
              setState(() {
                lassoSelectionActive = false;
                //lassoSelection = simplifyPath(lassoSelection, 5.0);
              });
            }
          },
          child: !lassoSelectionActive
              ? InteractiveViewer(
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
                          interactiveViewerActive: !lassoSelectionActive,
                          currentMap: widget.server.currentMap,
                          colors: Theme.of(context).colorScheme,
                          transformationController: _transformationController,
                          transformationControllerValue:
                              _transformationController.value,
                          lineWidth: baseLineWidth,
                          roverImage: roverImage,
                          roverPosition: widget.server.robot.scaledPosition,
                          roverRotation: widget.server.robot.angle,
                          pxToMeter: scale,
                          mowPointIdx: widget.server.robot.mowPointIdx,
                          lassoSelection: lassoSelection,
                        ),
                      ),
                    ),
                  ),
                )
              : SizedBox(
                  width: screenSize.width,
                  height: screenSize.height,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: CustomPaint(
                      painter: MapPainter(
                        interactiveViewerActive: !lassoSelectionActive,
                        currentMap: widget.server.currentMap,
                        colors: Theme.of(context).colorScheme,
                        transformationController: _transformationController,
                        transformationControllerValue: currentTransformation,
                        lineWidth: baseLineWidth,
                        roverImage: roverImage,
                        roverPosition: widget.server.robot.scaledPosition,
                        roverRotation: widget.server.robot.angle,
                        pxToMeter: scale,
                        mowPointIdx: widget.server.robot.mowPointIdx,
                        lassoSelection: lassoSelection,
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
                lassoSelectionActive = false;
                _transformationController.value = Matrix4.identity();
              },
            ),
            MapButton(
              icon: Icons.center_focus_weak_outlined,
              onPressed: () {
                focusOnMowerActive = !focusOnMowerActive;
                lassoSelectionActive = false;
                focusOnMower(widget.server.robot.scaledPosition);
              },
            ),
            MapButton(
              icon: Icons.gesture_outlined,
              onPressed: () {
                currentTransformation = _transformationController.value.clone();
                focusOnMowerActive = false;
                lassoSelectionActive = !lassoSelectionActive;
                lassoSelection = [];
                setState(() {});
              },
            ),
          ],
        ),
      ]);
    });
  }

  // Ramer-Douglas-Peucker Algorithmus zur Vereinfachung des Polygons
  List<Offset> simplifyPath(List<Offset> points, double tolerance) {
    if (points.length < 3) return points;
    return _ramerDouglasPeucker(points, tolerance);
  }

  // Der Ramer-Douglas-Peucker Algorithmus rekursiv
  List<Offset> _ramerDouglasPeucker(List<Offset> points, double epsilon) {
    if (points.length < 2) return points;

    double dmax = 0.0;
    int index = 0;
    for (int i = 1; i < points.length - 1; i++) {
      double d = _perpendicularDistance(
          points[i], points[0], points[points.length - 1]);
      if (d > dmax) {
        index = i;
        dmax = d;
      }
    }

    if (dmax > epsilon) {
      List<Offset> recResults1 =
          _ramerDouglasPeucker(points.sublist(0, index + 1), epsilon);
      List<Offset> recResults2 =
          _ramerDouglasPeucker(points.sublist(index), epsilon);

      return recResults1.sublist(0, recResults1.length - 1) + recResults2;
    } else {
      return [points[0], points[points.length - 1]];
    }
  }

  // Berechne den Abstand eines Punktes zur Linie
  double _perpendicularDistance(
      Offset point, Offset lineStart, Offset lineEnd) {
    double dx = lineEnd.dx - lineStart.dx;
    double dy = lineEnd.dy - lineStart.dy;
    double mag = sqrt(dx * dx + dy * dy);
    if (mag > 0.0) {
      dx /= mag;
      dy /= mag;
    }
    double pvx = point.dx - lineStart.dx;
    double pvy = point.dy - lineStart.dy;
    double pvdot = dx * pvx + dy * pvy;
    double ax = pvx - pvdot * dx;
    double ay = pvy - pvdot * dy;
    return sqrt(ax * ax + ay * ay);
  }

  Offset _applyInverseMatrixTransformation(Offset point, Matrix4 matrix) {
    final vmath.Vector3 transformed3D = vmath.Vector3(point.dx, point.dy, 0);
    Matrix4 invertedMatrix = Matrix4.inverted(matrix);
    final vmath.Vector3 result = invertedMatrix.transform3(transformed3D);
    return Offset(result.x, result.y);
  }
}
