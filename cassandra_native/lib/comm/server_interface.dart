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
    final Map<String, dynamic> cmd =
        _addTopicAndCommandToValue('robot', 'move', movementValue);
    final String cmdJson = jsonEncode(cmd);
    if (kDebugMode) {
      debugPrint(cmdJson);
    }
    _sendCommand(cmdJson);
  }

  void commandSendMessage(String message) {
    final Map<String, dynamic> cmd =
        _addTopicAndCommandToValue('server', 'sendMessage', [message]);
    final String cmdJson = jsonEncode(cmd);
    if (kDebugMode) {
      debugPrint(cmdJson);
    }
    _sendCommand(cmdJson);
  }

  void commandRestartServer() {
    final Map<String, dynamic> cmd =
        _addTopicAndCommandToValue('server', 'restart', []);
    final String cmdJson = jsonEncode(cmd);
    if (kDebugMode) {
      debugPrint(cmdJson);
    }
    _sendCommand(cmdJson);
  }

  void commandShutdownServer() {
    final Map<String, dynamic> cmd =
        _addTopicAndCommandToValue('server', 'shutdown', []);
    final String cmdJson = jsonEncode(cmd);
    if (kDebugMode) {
      debugPrint(cmdJson);
    }
    _sendCommand(cmdJson);
  }

  void commandUpdateCoords(String value) {
    final Map<String, dynamic> cmd =
        _addTopicAndCommandToValue('coords', 'update', [value]);
    final String cmdJson = jsonEncode(cmd);
    if (kDebugMode) {
      debugPrint(cmdJson);
    }
    _sendCommand(cmdJson);
  }

  void commandUpdateSettings() {
    final Map<String, dynamic> cmd =
        _addTopicAndCommandToValue('settings', 'update', []);
    final String cmdJson = jsonEncode(cmd);
    if (kDebugMode) {
      debugPrint(cmdJson);
    }
    _sendCommand(cmdJson);
  }

  void commandSaveSchedule(Map<String, dynamic> scheduleData) {
    final Map<String, dynamic> cmd =
        _addTopicAndCommandToValue('schedule', 'save', scheduleData);
    final cmdJson = jsonEncode(cmd);
    if (kDebugMode) {
      debugPrint(cmdJson);
    }
    _sendCommand(cmdJson);
  }

  void commandSetSettings(String command, Map<String, dynamic> settings) {
    final Map<String, dynamic> cmd =
        _addTopicAndCommandToValue('settings', command, settings);
    final String cmdJson = jsonEncode(cmd);
    if (kDebugMode) {
      debugPrint(cmdJson);
    }
    _sendCommand(cmdJson);
  }

  void commandSetSelection(List<Offset> selection) {
    final Map<String, List<double>> selectionCoords = _coordsToMap(selection);
    final Map<String, dynamic> cmd =
        _addTopicAndCommandToValue('map', 'setSelection', selectionCoords);
    final String cmdJson = jsonEncode(cmd);
    if (kDebugMode) {
      debugPrint(cmdJson);
    }
    _sendCommand(cmdJson);
  }

  void commandSetMowParameters(Map<String, dynamic> mowParameters) {
    final Map<String, dynamic> cmd =
        _addTopicAndCommandToValue('map', 'setMowParameters', mowParameters);
    final String cmdJson = jsonEncode(cmd);
    if (kDebugMode) {
      debugPrint(cmdJson);
    }
    _sendCommand(cmdJson);
  }

  void commandMow(String value) {
    final Map<String, dynamic> cmd =
        _addTopicAndCommandToValue('robot', 'mow', [value]);
    final String cmdJson = jsonEncode(cmd);
    if (kDebugMode) {
      debugPrint(cmdJson);
    }
    _sendCommand(cmdJson);
  }

  void commandStop() {
    final Map<String, dynamic> cmd =
        _addTopicAndCommandToValue('robot', 'stop', []);
    final String cmdJson = jsonEncode(cmd);
    if (kDebugMode) {
      debugPrint(cmdJson);
    }
    _sendCommand(cmdJson);
  }

  void commandDock() {
    final Map<String, dynamic> cmd =
        _addTopicAndCommandToValue('robot', 'dock', []);
    final String cmdJson = jsonEncode(cmd);
    if (kDebugMode) {
      debugPrint(cmdJson);
    }
    _sendCommand(cmdJson);
  }

  void commandGoto(Offset gotoPoint) {
    final Map<String, List<double>> gotoCoords = _coordsToMap([gotoPoint]);
    final Map<String, dynamic> cmd =
        _addTopicAndCommandToValue('robot', 'goTo', gotoCoords);
    final String cmdJson = jsonEncode(cmd);
    if (kDebugMode) {
      debugPrint(cmdJson);
    }
    _sendCommand(cmdJson);
  }

  void commandShutdown() {
    final Map<String, dynamic> cmd =
        _addTopicAndCommandToValue('robot', 'shutdown', []);
    final String cmdJson = jsonEncode(cmd);
    if (kDebugMode) {
      debugPrint(cmdJson);
    }
    _sendCommand(cmdJson);
  }

  void commandReboot() {
    final Map<String, dynamic> cmd =
        _addTopicAndCommandToValue('robot', 'reboot', []);
    final String cmdJson = jsonEncode(cmd);
    if (kDebugMode) {
      debugPrint(cmdJson);
    }
    _sendCommand(cmdJson);
  }

  void commandRebootGps() {
    final Map<String, dynamic> cmd =
        _addTopicAndCommandToValue('robot', 'rebootGps', []);
    final String cmdJson = jsonEncode(cmd);
    if (kDebugMode) {
      debugPrint(cmdJson);
    }
    _sendCommand(cmdJson);
  }

  void commandResetObstacles() {
    final Map<String, dynamic> cmd =
        _addTopicAndCommandToValue('map', 'resetObstacles', []);
    final String cmdJson = jsonEncode(cmd);
    if (kDebugMode) {
      debugPrint(cmdJson);
    }
    _sendCommand(cmdJson);
  }

  void commandResetRoute() {
    final Map<String, dynamic> cmd =
        _addTopicAndCommandToValue('map', 'resetRoute', []);
    final String cmdJson = jsonEncode(cmd);
    if (kDebugMode) {
      debugPrint(cmdJson);
    }
    _sendCommand(cmdJson);
  }

  void commandSelectTasks(List<String> tasks) {
    final Map<String, dynamic> cmd =
        _addTopicAndCommandToValue('tasks', 'select', tasks);
    final String cmdJson = jsonEncode(cmd);
    if (kDebugMode) {
      debugPrint(cmdJson);
    }
    _sendCommand(cmdJson);
  }

  void commandLoadTasks(List<String> tasks) {
    final Map<String, dynamic> cmd =
        _addTopicAndCommandToValue('tasks', 'load', tasks);
    final String cmdJson = jsonEncode(cmd);
    if (kDebugMode) {
      debugPrint(cmdJson);
    }
    _sendCommand(cmdJson);
  }

  void commandSaveTask(Map<String, dynamic> taskData) {
    final Map<String, dynamic> cmd =
        _addTopicAndCommandToValue('tasks', 'save', taskData);
    final String cmdJson = jsonEncode(cmd);
    if (kDebugMode) {
      debugPrint(cmdJson);
    }
    _sendCommand(cmdJson);
  }

  void commandRemoveTask(List<String> task) {
    final Map<String, dynamic> cmd =
        _addTopicAndCommandToValue('tasks', 'remove', task);
    final String cmdJson = jsonEncode(cmd);
    if (kDebugMode) {
      debugPrint(cmdJson);
    }
    _sendCommand(cmdJson);
  }

  void commandRenameTask(List<String> task) {
    final Map<String, dynamic> cmd =
        _addTopicAndCommandToValue('tasks', 'rename', task);
    final String cmdJson = jsonEncode(cmd);
    if (kDebugMode) {
      debugPrint(cmdJson);
    }
    _sendCommand(cmdJson);
  }

  void commandCopyTask(List<String> task) {
    final Map<String, dynamic> cmd =
        _addTopicAndCommandToValue('tasks', 'copy', task);
    final String cmdJson = jsonEncode(cmd);
    if (kDebugMode) {
      debugPrint(cmdJson);
    }
    _sendCommand(cmdJson);
  }

  void commandSelectMap(List<String> map) {
    final Map<String, dynamic> cmd =
        _addTopicAndCommandToValue('maps', 'select', map);
    final String cmdJson = jsonEncode(cmd);
    if (kDebugMode) {
      debugPrint(cmdJson);
    }
    _sendCommand(cmdJson);
  }

  void commandLoadMap(List<String> map) {
    final Map<String, dynamic> cmd =
        _addTopicAndCommandToValue('maps', 'load', map);
    final String cmdJson = jsonEncode(cmd);
    if (kDebugMode) {
      debugPrint(cmdJson);
    }
    _sendCommand(cmdJson);
  }

  void commandSaveMap(Map<String, dynamic> mapData) {
    final Map<String, dynamic> cmd =
        _addTopicAndCommandToValue('maps', 'save', mapData);
    final String cmdJson = jsonEncode(cmd);
    if (kDebugMode) {
      debugPrint(cmdJson);
    }
    _sendCommand(cmdJson);
  }

  void commandRemoveMap(List<String> map) {
    final Map<String, dynamic> cmd =
        _addTopicAndCommandToValue('maps', 'remove', map);
    final String cmdJson = jsonEncode(cmd);
    if (kDebugMode) {
      debugPrint(cmdJson);
    }
    _sendCommand(cmdJson);
  }

  void commandRenameMap(List<String> names) {
    final Map<String, dynamic> cmd =
        _addTopicAndCommandToValue('maps', 'rename', names);
    final String cmdJson = jsonEncode(cmd);
    if (kDebugMode) {
      debugPrint(cmdJson);
    }
    _sendCommand(cmdJson);
  }

  void commandCopyMap(List<String> map) {
    final Map<String, dynamic> cmd =
        _addTopicAndCommandToValue('maps', 'copy', map);
    final String cmdJson = jsonEncode(cmd);
    if (kDebugMode) {
      debugPrint(cmdJson);
    }
    _sendCommand(cmdJson);
  }

  void commandToggleMowMotor() {
    final Map<String, dynamic> cmd =
        _addTopicAndCommandToValue('robot', 'toggleMowMotor', []);
    final String cmdJson = jsonEncode(cmd);
    if (kDebugMode) {
      debugPrint(cmdJson);
    }
    _sendCommand(cmdJson);
  }

  void commandSkipNextPoint() {
    final Map<String, dynamic> cmd =
        _addTopicAndCommandToValue('robot', 'skipNextPoint', []);
    final String cmdJson = jsonEncode(cmd);
    if (kDebugMode) {
      debugPrint(cmdJson);
    }
    _sendCommand(cmdJson);
  }

  void commandSetMowProgress(double value) {
    final Map<String, dynamic> cmd =
        _addTopicAndCommandToValue('robot', 'setMowProgress', [value]);
    final String cmdJson = jsonEncode(cmd);
    if (kDebugMode) {
      debugPrint(cmdJson);
    }
    _sendCommand(cmdJson);
  }

  void commandCalculateSubtask(Map<String, dynamic> subtaskData) {
    final Map<String, dynamic> cmd =
        _addTopicAndCommandToValue('tasks', 'calculate', subtaskData);
    final String cmdJson = jsonEncode(cmd);
    if (kDebugMode) {
      debugPrint(cmdJson);
    }
    _sendCommand(cmdJson);
  }
}
