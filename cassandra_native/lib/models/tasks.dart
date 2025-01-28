import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

import 'package:cassandra_native/models/mow_parameters.dart';

class Tasks {
  List<dynamic> available = [];
  List<dynamic> selected = [];
  Map<String, List<List<Offset>>> previews = {};
  Map<String, List<List<Offset>>> shiftedPreviews = {};
  Map<String, List<List<Offset>>> scaledPreviews = {};
  Map<String, List<List<Offset>>> selections = {};
  Map<String, List<List<Offset>>> shiftedSelections = {};
  Map<String, List<List<Offset>>> scaledSelections = {};
  Map<String, List<MowParameters>> mowParameters = {};
  Map<String, dynamic> udpatedCoords = {};

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

  void resetCooords () {
    selected = [];
    previews = {};
    shiftedPreviews = {};
    scaledPreviews = {};
    selections = {};
    shiftedSelections = {};
    scaledSelections = {};
  }
}
