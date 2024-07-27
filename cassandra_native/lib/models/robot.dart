import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/widgets.dart';

import 'package:cassandra_native/models/landscape.dart';

class Robot {
  String status = 'offline';
  Offset position = Offset(0, 0);
  Offset target = Offset(0, 0);
  Offset scaledPosition = Offset(0, 0);
  Offset scaledTarget = Offset(0, 0);
  double angle = 0;

  void jsonToClassData(String message){
    var decodedMessage = jsonDecode(message) as Map<String, dynamic>;
    try{
      position = Offset(decodedMessage['position']['x'], decodedMessage['position']['y']);
      angle = decodedMessage['angle'];
    }
    catch(e){
      print('Invalid robot json data: $e');
    }
  }

  void scalePosition(double scale, double width, double height, Landscape currentMap){
    if (currentMap.perimeter.isNotEmpty) {
      scaledPosition = Offset((position.dx - currentMap.minX) * scale + currentMap.offsetX,  -(position.dy -currentMap.minY) * scale + currentMap.offsetY);
    } else {
      scaledPosition = Offset(width/2, height/2);
    }
  }
}