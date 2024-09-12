import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:ui' as ui;

import '../../models/server.dart';
import 'package:cassandra_native/comm/mqtt_manager.dart';
import 'package:cassandra_native/components/home_page/map_painter.dart';
import 'package:cassandra_native/components/home_page/map_button.dart';
import 'package:cassandra_native/components/home_page/play_button.dart';
import 'package:cassandra_native/utils/custom_shape_calcs.dart';

class MapView extends StatefulWidget {
  final Server server;
  const MapView({super.key, required this.server});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  //zoom and pan
  Offset _offset = Offset.zero;
  double _scale = 1.0;
  double _previousScale = 1.0;
  Offset _focalPoint = Offset.zero;
  Offset _initialFocalPoint = Offset.zero;

  //selcection
  bool lassoSelectionActive = false;
  List<Offset> lassoSelection = [];
  List<Offset> lassoSelectionPoints = [];

  //ui
  ui.Image? roverImage;
  bool focusOnMowerActive = false;
  IconData playButtonIcon = Icons.play_arrow;

  @override
  void dispose() {
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

  void _focusOnMower() {
    Size screenSize = MediaQuery.of(context).size;
    _offset = Offset(
        screenSize.width / 2 - widget.server.robot.scaledPosition.dx * _scale,
        screenSize.height / 2 - widget.server.robot.scaledPosition.dy * _scale);
    //setState(() {});
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
    //Size screenSize = MediaQuery.of(context).size;
    return LayoutBuilder(builder: (context, constraints) {
      // calc new min an max coords
      final shiftedMaxX = widget.server.currentMap.shiftedMaxX;
      final shiftedMaxY = widget.server.currentMap.shiftedMaxY;

      // calc scale factor 1:1 depends on container size
      double mapScale = 1.0;
      if (shiftedMaxX / shiftedMaxY >
          constraints.maxWidth / constraints.maxHeight) {
        mapScale = constraints.maxWidth / shiftedMaxX;
      } else {
        mapScale = constraints.maxHeight / shiftedMaxY;
      }

      // calc coords to canvas coords on 1:1 scale
      widget.server.currentMap
          .scaleShapes(mapScale, constraints.maxWidth, constraints.maxHeight);
      widget.server.currentMap.scalePreview(mapScale);
      widget.server.currentMap.scaleMowPath(mapScale);
      widget.server.robot.scalePosition(mapScale, constraints.maxWidth,
          constraints.maxHeight, widget.server.currentMap);

      // zoom focus on mower
      if (focusOnMowerActive) {
        _focusOnMower();
      }

      return Stack(
        children: [
          GestureDetector(
            onScaleStart: (details) {
              //selection or zoom and
              if (lassoSelectionActive) {
                lassoSelection = [];
                lassoSelectionPoints = [];
              } else {
                _previousScale = _scale;
                _focalPoint = details.focalPoint;
                _initialFocalPoint = details.focalPoint;
              }
            },
            onScaleUpdate: (details) {
              setState(() {
                //selection or zoom and pan

                //selection
                if (lassoSelectionActive) {
                  RenderBox box = context.findRenderObject() as RenderBox;
                  Offset widgetGlobalPosition = box.localToGlobal(Offset.zero);
                  Offset selection =
                      (details.focalPoint - widgetGlobalPosition - _offset) /
                          _scale;
                  lassoSelection.add(selection);

                  //zoom and pan
                } else {
                  //limit sensivity of zoom
                  double newScale = (_previousScale * details.scale)
                      .clamp(0.5, double.infinity);

                  //calc new offset to center zoom between focal point
                  Offset focalPointDelta = _initialFocalPoint - _offset;
                  _offset =
                      _offset - (focalPointDelta * (newScale / _scale - 1));
                  _scale = _previousScale * details.scale;

                  //if map is just moved, callc new offset
                  if (details.scale == 1.0) {
                    _offset += details.focalPoint - _focalPoint;
                    _focalPoint = details.focalPoint;
                  }

                  //set new scale
                  _scale = newScale;
                }
              });
            },
            onScaleEnd: (_) {
              if (lassoSelectionActive) {
                setState(() {
                  lassoSelectionActive = false;
                  lassoSelection = simplifyPath(lassoSelection, 2.0/_scale);
                  lassoSelectionPoints = lassoSelection;
                });
              }
            },
            child: SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: AspectRatio(
                aspectRatio: 1,
                child: CustomPaint(
                  painter: MapPainter(
                      offset: _offset,
                      scale: _scale,
                      roverImage: roverImage,
                      currentServer: widget.server,
                      lassoSelection: lassoSelection,
                      lassoSelectionPoints: lassoSelectionPoints,
                      colors: Theme.of(context).colorScheme),
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
                  _offset = Offset.zero;
                  _scale = 1.0;
                  setState(() {});
                },
              ),
              MapButton(
                icon: Icons.center_focus_weak_outlined,
                onPressed: () {
                  focusOnMowerActive = !focusOnMowerActive;
                  lassoSelectionActive = false;
                  _focusOnMower();
                  setState(() {});
                },
              ),
              MapButton(
                icon: Icons.gesture_outlined,
                onPressed: () {
                  //currentTransformation = _transformationController.value.clone();
                  focusOnMowerActive = false;
                  lassoSelectionActive = !lassoSelectionActive;
                  lassoSelection = [];
                  lassoSelectionPoints = [];
                  setState(() {});
                },
              ),
            ],
          ),
        ],
      );
    });
  }
}
