import 'package:flutter/foundation.dart';
import 'dart:convert';

class Schedule {
  bool active = false;
  Map<String, dynamic> timeTable = {};

  void scheduleJsonToClassData(String message) {
    var decodedMessage = jsonDecode(message) as Map<String, dynamic>;
    try {
      active = decodedMessage['scheduleActive'];
      timeTable['monday'] = {
        'timeRange': List.from(decodedMessage['timeRange'][0]['monday']),
        'tasks': List.from(decodedMessage['tasks'][0]['monday'])
      };
      timeTable['tuesday'] = {
        'timeRange': List.from(decodedMessage['timeRange'][1]['tuesday']),
        'tasks': List.from(decodedMessage['tasks'][1]['tuesday'])
      };
      timeTable['wednesday'] = {
        'timeRange': List.from(decodedMessage['timeRange'][2]['wednesday']),
        'tasks': List.from(decodedMessage['tasks'][2]['wednesday'])
      };
      timeTable['thursday'] = {
        'timeRange': List.from(decodedMessage['timeRange'][3]['thursday']),
        'tasks': List.from(decodedMessage['tasks'][3]['thursday'])
      };
      timeTable['friday'] = {
        'timeRange': List.from(decodedMessage['timeRange'][4]['friday']),
        'tasks': List.from(decodedMessage['tasks'][4]['friday'])
      };
      timeTable['saturday'] = {
        'timeRange': List.from(decodedMessage['timeRange'][5]['saturday']),
        'tasks': List.from(decodedMessage['tasks'][5]['saturday'])
      };
      timeTable['sunday'] = {
        'timeRange': List.from(decodedMessage['timeRange'][6]['sunday']),
        'tasks': List.from(decodedMessage['tasks'][6]['sunday'])
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Invalid schedule JSON: $e');
      }
    }
  }
}
