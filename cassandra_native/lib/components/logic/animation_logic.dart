import 'package:flutter/material.dart';

import 'package:cassandra_native/models/robot.dart';

class MapAnimationLogic {
  MapAnimationLogic({required this.robot});
  Robot robot;
  bool get active => _checkAnimationState();
  List<String> statesForAnimation = [
    'mow',
    'transit',
    'docking',
    'move',
  ];
  Offset oldPosition = Offset.zero;
  double oldAngle = 0;
  Offset get newPosition => robot.scaledPosition;
  Offset get newMapsPosition => robot.mapsScaledPosition;
  double get newAngle => robot.angle;
  bool _checkAnimationState() {
    return statesForAnimation.contains(robot.status);
  }
}