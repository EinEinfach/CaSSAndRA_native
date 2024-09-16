import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:cassandra_native/comm/mqtt_manager.dart';

class CmdList {
  CmdList({required this.id, required this.serverNamePrefix});

  String serverInterface = 'api_cmd';
  String id;
  String serverNamePrefix;

  Map<String, List<double>> _coordsToMap(List<Offset> coords){
    final List<double> xValues = coords.map((p) => p.dx).toList();
    final List<double> yValues = coords.map((p) => p.dy).toList();
    final Map<String, List<double>> coordsMap = {"x": xValues, "y": yValues};
    return coordsMap;
  }

  Map<String, dynamic> _addTopicAndCommandToValue(String topicValue, String commandValue, dynamic value) {
    final Map<String, dynamic> command = {"command": commandValue, "value": value};
    final Map<String, dynamic> topic = {topicValue: command};
    return topic;
  }

  void _sendCommand(String command) {
    MqttManager.instance.publish(id, '$serverNamePrefix/$serverInterface', command);
  }

  void commandMove(double linearSpeed, double angularSpeed) {
    final List<double> movementValue = [linearSpeed, angularSpeed];
    final Map<String, dynamic> cmdMove = _addTopicAndCommandToValue('robot', 'move', movementValue);
    final String cmdMoveJson = jsonEncode(cmdMove);
    _sendCommand(cmdMoveJson);
  }

  void commandUpdateCoords(String value) {
    final Map<String, dynamic> cmdUpdateCoords = _addTopicAndCommandToValue('coords', 'update', [value]);
    final String cmdUpdateCoordsJson = jsonEncode(cmdUpdateCoords);
    _sendCommand(cmdUpdateCoordsJson);
  }

  void commandSetSelection(List<Offset> selection) {
    final Map<String, List<double>> selectionCoords = _coordsToMap(selection);
    final Map<String, dynamic> cmdSetSelection = _addTopicAndCommandToValue('map', 'set selection', selectionCoords);
    final String cmdSetSelectionJson = jsonEncode(cmdSetSelection);
    _sendCommand(cmdSetSelectionJson);
  }

  void commandMow(String value) {
    final Map<String, dynamic> cmdMow = _addTopicAndCommandToValue('robot', 'mow', [value]);
    final String cmdMowJson = jsonEncode(cmdMow);
    _sendCommand(cmdMowJson);
  }

  void commandStop() {
    final Map<String, dynamic> cmdStop = _addTopicAndCommandToValue('robot', 'stop', []);
    final String cmdStopJson = jsonEncode(cmdStop);
    _sendCommand(cmdStopJson);
  }

}