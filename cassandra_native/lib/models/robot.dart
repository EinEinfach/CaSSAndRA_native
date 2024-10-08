import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';

import 'package:cassandra_native/models/landscape.dart';

class Robot {
  String status = 'offline';
  String? lastStatus;
  Offset position = const Offset(0, 0);
  Offset target = const Offset(0, 0);
  Offset scaledPosition = const Offset(0, 0);
  Offset scaledTarget = const Offset(0, 0);
  double angle = 0;
  int mowPointIdx = 0;
  int soc = 0;
  double voltage = 0;
  double current = 0;
  String rtkSolution = 'invalid';
  int visibleSatellites = 0;
  int dgpsSatellites = 0;
  String rtkAge = '99+d';

  void jsonToClassData(String message) {
    var decodedMessage = jsonDecode(message) as Map<String, dynamic>;
    try {
      position = Offset(
          decodedMessage['position']['x'], decodedMessage['position']['y']);
      target =
          Offset(decodedMessage['target']['x'], decodedMessage['target']['y']);
      angle = decodedMessage['angle'];
      status = decodedMessage['status'];
      mowPointIdx = decodedMessage['mowPointIdx'];
      soc = decodedMessage['battery']['soc'];
      voltage = decodedMessage['battery']['voltage'];
      current = decodedMessage['battery']['electricCurrent'];
      visibleSatellites = decodedMessage['gps']['visible'];
      dgpsSatellites = decodedMessage['gps']['dgps'];
      rtkAge = decodedMessage['gps']['age'];
      rtkSolution = decodedMessage['gps']['solution'];

      //notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Invalid robot json data: $e');
      }
    }
  }

  void scalePosition(Size screenSize, Landscape currentMap) {
    if (currentMap.perimeter.isNotEmpty) {
      scaledPosition = Offset(
          (position.dx - currentMap.minX) * currentMap.mapScale +
              currentMap.offsetX,
          -(position.dy - currentMap.minY) * currentMap.mapScale +
              currentMap.offsetY);
      scaledTarget = Offset(
          (target.dx - currentMap.minX) * currentMap.mapScale +
              currentMap.offsetX,
          -(target.dy - currentMap.minY) * currentMap.mapScale +
              currentMap.offsetY);
    } else {
      scaledPosition = Offset(screenSize.width / 2, screenSize.height / 2);
    }
  }
}
