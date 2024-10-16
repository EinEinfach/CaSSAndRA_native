import 'dart:convert';
import 'package:flutter/foundation.dart';

class Maps {
  String? loaded; 
  List<dynamic>? available;

  void mapsJsonToClassData(String message) {
    var decodedMessage = jsonDecode(message) as Map<String, dynamic>;
    try {
      loaded = decodedMessage['loaded'];
      available = decodedMessage['available'];
    } catch (e) {
      if(kDebugMode) {
        debugPrint('Invalid maps JSON: $e');
      }
    }
  }
}