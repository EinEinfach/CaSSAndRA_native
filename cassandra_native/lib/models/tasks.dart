import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

class Tasks {
  List<dynamic> available = [];
  List<dynamic> selected = [];
  Map<String, List<List<Offset>>> previews = {};
  Map<String, List<List<Offset>>> shiftedPreviews = {};
  Map<String, List<List<Offset>>> scaledPreviews = {};

  void jsonToClassData(String message) {
    var decodedMessage = jsonDecode(message) as Map<String, dynamic>;
    try {
      available = decodedMessage['available'];
      available.sort();
      selected = decodedMessage['selected'];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Invalid tasks json data: $e');
      }
    }
  }
}
