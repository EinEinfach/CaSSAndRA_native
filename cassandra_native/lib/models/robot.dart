import 'package:flutter/material.dart';
import 'dart:convert';

class Robot {
  String status = 'offline';
  Offset position = Offset(0, 0);
  Offset target = Offset(0, 0);
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
}