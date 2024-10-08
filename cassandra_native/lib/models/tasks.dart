import 'package:flutter/foundation.dart';
import 'dart:convert';

class Tasks {
  List<dynamic> available = [];
  List<dynamic> selected = [];

  void jsonToClassData(String message) {
    var decodedMessage = jsonDecode(message) as Map<String, dynamic>;
    try {
      available = decodedMessage['available'];
      selected = decodedMessage['selected'];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Invalid tasks json data: $e');
      }
    }
  }
}
