import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

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
    if (MqttManager.instance.isNotConnected(id)) {
      if (kDebugMode) {
        debugPrint('Disconnected. Message could not be sent');
      }
    } else {
      MqttManager.instance
          .publish(id, '$serverNamePrefix/$serverInterface', command);
    }
  }

  void commandMove(double linearSpeed, double angularSpeed) {
    final List<double> movementValue = [linearSpeed, angularSpeed];
    final Map<String, dynamic> cmdMove =
        _addTopicAndCommandToValue('robot', 'move', movementValue);
    final String cmdMoveJson = jsonEncode(cmdMove);
    if (kDebugMode) {
      debugPrint(cmdMoveJson);
    }
    _sendCommand(cmdMoveJson);
  }

  void commandSendMessage(String message) {
    final Map<String, dynamic> cmdSendMessage =
        _addTopicAndCommandToValue('server', 'sendMessage', [message]);
    final String cmdSendMessageJson = jsonEncode(cmdSendMessage);
    if (kDebugMode) {
      debugPrint(cmdSendMessageJson);
    }
    _sendCommand(cmdSendMessageJson);
  }

  void commandRestartServer() {
    final Map<String, dynamic> cmdRestartServer =
        _addTopicAndCommandToValue('server', 'restart', []);
    final String cmdRestartServerJson = jsonEncode(cmdRestartServer);
    if (kDebugMode) {
      debugPrint(cmdRestartServerJson);
    }
    _sendCommand(cmdRestartServerJson);
  }

  void commandUpdateCoords(String value) {
    final Map<String, dynamic> cmdUpdateCoords =
        _addTopicAndCommandToValue('coords', 'update', [value]);
    final String cmdUpdateCoordsJson = jsonEncode(cmdUpdateCoords);
    if (kDebugMode) {
      debugPrint(cmdUpdateCoordsJson);
    }
    _sendCommand(cmdUpdateCoordsJson);
  }

  void commandUpdateSettings() {
    final Map<String, dynamic> cmdUpdateSettings =
        _addTopicAndCommandToValue('settings', 'update', []);
    final String cmdUpdateSettingsJson = jsonEncode(cmdUpdateSettings);
    if (kDebugMode) {
      debugPrint(cmdUpdateSettingsJson);
    }
    _sendCommand(cmdUpdateSettingsJson);
  }

  void commandSetSettings(String command, Map<String, dynamic> settings) {
    final Map<String, dynamic> cmdSetSettings =
        _addTopicAndCommandToValue('settings', command, settings);
    final String cmdSetSettingsJson = jsonEncode(cmdSetSettings);
    if (kDebugMode) {
      debugPrint(cmdSetSettingsJson);
    }
    _sendCommand(cmdSetSettingsJson);
  }

  void commandSetSelection(List<Offset> selection) {
    final Map<String, List<double>> selectionCoords = _coordsToMap(selection);
    final Map<String, dynamic> cmdSetSelection =
        _addTopicAndCommandToValue('map', 'setSelection', selectionCoords);
    final String cmdSetSelectionJson = jsonEncode(cmdSetSelection);
    if (kDebugMode) {
      debugPrint(cmdSetSelectionJson);
    }
    _sendCommand(cmdSetSelectionJson);
  }

  void commandSetMowParameters(Map<String, dynamic> mowParameters) {
    final Map<String, dynamic> cmdSetMowParameters =
        _addTopicAndCommandToValue('map', 'setMowParameters', mowParameters);
    final String cmdSetMowParametersJson = jsonEncode(cmdSetMowParameters);
    if (kDebugMode) {
      debugPrint(cmdSetMowParametersJson);
    }
    _sendCommand(cmdSetMowParametersJson);
  }

  void commandMow(String value) {
    final Map<String, dynamic> cmdMow =
        _addTopicAndCommandToValue('robot', 'mow', [value]);
    final String cmdMowJson = jsonEncode(cmdMow);
    if (kDebugMode) {
      debugPrint(cmdMowJson);
    }
    _sendCommand(cmdMowJson);
  }

  void commandStop() {
    final Map<String, dynamic> cmdStop =
        _addTopicAndCommandToValue('robot', 'stop', []);
    final String cmdStopJson = jsonEncode(cmdStop);
    if (kDebugMode) {
      debugPrint(cmdStopJson);
    }
    _sendCommand(cmdStopJson);
  }

  void commandDock() {
    final Map<String, dynamic> cmdDock =
        _addTopicAndCommandToValue('robot', 'dock', []);
    final String cmdDockJson = jsonEncode(cmdDock);
    if (kDebugMode) {
      debugPrint(cmdDockJson);
    }
    _sendCommand(cmdDockJson);
  }

  void commandGoto(Offset gotoPoint) {
    final Map<String, List<double>> gotoCoords = _coordsToMap([gotoPoint]);
    final Map<String, dynamic> cmdGoto =
        _addTopicAndCommandToValue('robot', 'go to', gotoCoords);
    final String cmdGotoJson = jsonEncode(cmdGoto);
    if (kDebugMode) {
      debugPrint(cmdGotoJson);
    }
    _sendCommand(cmdGotoJson);
  }

  void commandResetObstacles() {
    final Map<String, dynamic> cmdResetObstacles =
        _addTopicAndCommandToValue('map', 'resetObstacles', []);
    final String cmdResetObstaclesJson = jsonEncode(cmdResetObstacles);
    if (kDebugMode) {
      debugPrint(cmdResetObstaclesJson);
    }
    _sendCommand(cmdResetObstaclesJson);
  }

  void commandSelectTasks(List<String> tasks) {
    final Map<String, dynamic> cmdSelectTasks =
        _addTopicAndCommandToValue('tasks', 'select', tasks);
    final String cmdSelectTasksJson = jsonEncode(cmdSelectTasks);
    if (kDebugMode) {
      debugPrint(cmdSelectTasksJson);
    }
    _sendCommand(cmdSelectTasksJson);
  }

  void commandSelectMap(List<String> map) {
    final Map<String, dynamic> cmdSelectMap =
        _addTopicAndCommandToValue('maps', 'select', map);
    final String cmdSelectMapJson = jsonEncode(cmdSelectMap);
    if (kDebugMode) {
      debugPrint(cmdSelectMapJson);
    }
    _sendCommand(cmdSelectMapJson);
  }

  void commandLoadMap(List<String> map) {
    final Map<String, dynamic> cmdLoadMap =
        _addTopicAndCommandToValue('maps', 'load', map);
    final String cmdLoadMapJson = jsonEncode(cmdLoadMap);
    if (kDebugMode) {
      debugPrint(cmdLoadMapJson);
    }
    _sendCommand(cmdLoadMapJson);
  }

  void commandSaveMap(Map<String, dynamic> mapData) {
    final Map<String, dynamic> cmdSaveMap =
        _addTopicAndCommandToValue('maps', 'save', mapData);
    final String cmdSaveMapJson = jsonEncode(cmdSaveMap);
    if (kDebugMode) {
      debugPrint(cmdSaveMapJson);
    }
    _sendCommand(cmdSaveMapJson);
  }

  void commandRemoveMap(List<String> map) {
    final Map<String, dynamic> cmdRemoveMap =
        _addTopicAndCommandToValue('maps', 'remove', map);
    final String cmdRemoveMapJson = jsonEncode(cmdRemoveMap);
    if (kDebugMode) {
      debugPrint(cmdRemoveMapJson);
    }
    _sendCommand(cmdRemoveMapJson);
  }

  void commandRenameMap(List<String> names) {
    final Map<String, dynamic> cmdRenameMap =
        _addTopicAndCommandToValue('maps', 'rename', names);
    final String cmdRenameMapJson = jsonEncode(cmdRenameMap);
    if (kDebugMode) {
      debugPrint(cmdRenameMapJson);
    }
    _sendCommand(cmdRenameMapJson);
  }
}
