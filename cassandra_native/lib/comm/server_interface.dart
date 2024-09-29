import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:cassandra_native/comm/mqtt_manager.dart';

class ServerInterface {
  ServerInterface({
    required this.id,
    required this.mqttServer,
    required this.port,
    required this.serverNamePrefix,
    required this.user,
    required this.password,
  });

  String serverInterface = 'api_cmd';
  String id;
  String mqttServer;
  int port;
  String serverNamePrefix;
  String user;
  String password;

  Map<String, List<double>> _coordsToMap(List<Offset> coords) {
    final List<double> xValues = coords.map((p) => p.dx).toList();
    final List<double> yValues = coords.map((p) => p.dy).toList();
    final Map<String, List<double>> coordsMap = {"x": xValues, "y": yValues};
    return coordsMap;
  }

  Map<String, dynamic> _addTopicAndCommandToValue(
      String topicValue, String commandValue, dynamic value) {
    final Map<String, dynamic> command = {
      "command": commandValue,
      "value": value
    };
    final Map<String, dynamic> topic = {topicValue: command};
    return topic;
  }

  void _sendCommand(String command) {
    MqttManager.instance
        .publish(id, '$serverNamePrefix/$serverInterface', command);
  }

  void commandMove(double linearSpeed, double angularSpeed) {
    final List<double> movementValue = [linearSpeed, angularSpeed];
    final Map<String, dynamic> cmdMove =
        _addTopicAndCommandToValue('robot', 'move', movementValue);
    final String cmdMoveJson = jsonEncode(cmdMove);
    _sendCommand(cmdMoveJson);
  }

  void commandUpdateCoords(String value) {
    final Map<String, dynamic> cmdUpdateCoords =
        _addTopicAndCommandToValue('coords', 'update', [value]);
    final String cmdUpdateCoordsJson = jsonEncode(cmdUpdateCoords);
    _sendCommand(cmdUpdateCoordsJson);
  }

  void commandSetSelection(List<Offset> selection) {
    final Map<String, List<double>> selectionCoords = _coordsToMap(selection);
    final Map<String, dynamic> cmdSetSelection =
        _addTopicAndCommandToValue('map', 'setSelection', selectionCoords);
    final String cmdSetSelectionJson = jsonEncode(cmdSetSelection);
    _sendCommand(cmdSetSelectionJson);
  }

  void commandSetMowParameters(Map<String, dynamic> mowParameters) {
    final Map<String, dynamic> cmdSetMowParameters =
        _addTopicAndCommandToValue('map', 'setMowParameters', mowParameters);
    final String cmdSetMowParametersJson = jsonEncode(cmdSetMowParameters);
    _sendCommand(cmdSetMowParametersJson);
  }

  void commandMow(String value) {
    final Map<String, dynamic> cmdMow =
        _addTopicAndCommandToValue('robot', 'mow', [value]);
    final String cmdMowJson = jsonEncode(cmdMow);
    _sendCommand(cmdMowJson);
  }

  void commandStop() {
    final Map<String, dynamic> cmdStop =
        _addTopicAndCommandToValue('robot', 'stop', []);
    final String cmdStopJson = jsonEncode(cmdStop);
    _sendCommand(cmdStopJson);
  }

  void commandDock() {
    final Map<String, dynamic> cmdDock =
        _addTopicAndCommandToValue('robot', 'dock', []);
    final String cmdDockJson = jsonEncode(cmdDock);
    _sendCommand(cmdDockJson);
  }

  void commandGoto(Offset gotoPoint) {
    final Map<String, List<double>> gotoCoords = _coordsToMap([gotoPoint]);
    final Map<String, dynamic> cmdGoto =
        _addTopicAndCommandToValue('robot', 'go to', gotoCoords);
    final String cmdGotoJson = jsonEncode(cmdGoto);
    _sendCommand(cmdGotoJson);
  }
}
