import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:cassandra_native/comm/mqtt_manager.dart';
import 'package:cassandra_native/comm/server_interface.dart';
import 'package:cassandra_native/models/robot.dart';
import 'package:cassandra_native/models/landscape.dart';
import 'package:cassandra_native/models/maps.dart';
import 'package:cassandra_native/models/server_settings.dart';

const uuid = Uuid();

enum Category { ardumower, alfred, landrumower, other }

final categoryImages = {
  Category.ardumower: [
    'lib/images/ardumower.png',
    'lib/images/ardumower/rover0grad.png'
  ],
  Category.alfred: [
    'lib/images/alfred.png',
    'lib/images/alfred/rover0grad.png'
  ],
  Category.landrumower: [
    'lib/images/landrumower.png',
    'lib/images/landrumower/rover0grad.png'
  ],
  Category.other: [
    'lib/images/in_app_icon.png',
    'lib/images/other/rover0grad.png'
  ]
};

class Server {
  Server({
    required this.id,
    required this.category,
    required this.alias,
    required this.mqttServer,
    required this.serverNamePrefix,
    required this.port,
    required this.user,
    required this.password,
    this.rtspUrl,
  }) : serverInterface = ServerInterface(
          id: id,
          mqttServer: mqttServer,
          port: port,
          serverNamePrefix: serverNamePrefix,
          user: user,
          password: password,
        );
  String software = '';
  String version = '';
  final String id;
  final Category category;
  final String alias;
  final String mqttServer;
  final String serverNamePrefix;
  final int port;
  final String user;
  final String password;

  ServerInterface serverInterface;
  String status = "offline";
  String? _lastStatus;
  String? rtspUrl;

  Robot robot = Robot();
  Landscape currentMap = Landscape();
  Maps maps = Maps();

  ServerSettings settings = ServerSettings();

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category.name,
        'alias': alias,
        'mqttServer': mqttServer,
        'serverNamePrefix': serverNamePrefix,
        'port': port,
        'user': user,
        'password': password,
        'rtspUrl': rtspUrl,
      };

  factory Server.fromJson(Map<String, dynamic> json) {
    return Server(
      id: json['id'],
      category: Category.values.byName(json['category']),
      alias: json['alias'],
      mqttServer: json['mqttServer'],
      serverNamePrefix: json['serverNamePrefix'],
      port: json['port'],
      user: json['user'],
      password: json['password'],
      rtspUrl: json['rtspUrl'],
    );
  }

  Future<void> connect() async {
    if (MqttManager.instance.isNotConnected(id)) {
      await MqttManager.instance.create(serverInterface, onMessageReceived);
    }
  }

  void disconnect() {
    MqttManager.instance.disconnect(id);
  }

  void onMessageReceived(String clientId, String topic, String message) {
    if (topic.contains('/status')) {
      status = message;
      if (status == 'offline') {
        robot.status = 'offline';
      }
    } else if (topic.contains('/robot')) {
      robot.jsonToClassData(message);
    } else if (topic.contains('/server')) {
      _jsonToClassData(message);
    } else if (topic.contains('/coords')) {
      currentMap.coordsJsonToClassData(message);
    } else if (topic.contains('/tasks')) {
      currentMap.tasks.jsonToClassData(message);
    } else if (topic.contains('/mapsCoords')) {
      maps.mapsCoordsJsonToClassData(message);
    } else if (topic.contains('/maps')) {
      maps.mapsJsonToClassData(message);
    } else if (topic.contains('/map')) {
      currentMap.mapJsonToClassData(message);
      if (currentMap.receivedMapId != currentMap.mapId) {
        serverInterface.commandUpdateCoords('currentMap');
      } else if (currentMap.receivedPreviewId != currentMap.previewId) {
        serverInterface.commandUpdateCoords('preview');
      } else if (currentMap.receivedMowPathId != currentMap.mowPathId) {
        serverInterface.commandUpdateCoords('mowPath');
      } else if (currentMap.receivedObstaclesId != currentMap.obstaclesId) {
        serverInterface.commandUpdateCoords('obstacles');
      }
    } else if (topic.contains('/settings')) {
      settings.settingsJsonToClassData(message);
    }
  }

  void _jsonToClassData(String message) {
    final decodedMessage = jsonDecode(message) as Map<String, dynamic>;
    try {
      software = decodedMessage['software'];
      version = decodedMessage['version'];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Invalid server json data: $e');
      }
    }
  }

  void storeStatus() {
    _lastStatus = status;
    robot.lastStatus = robot.status;
  }

  void restoreStatus() {
    if (_lastStatus != null) {
      status = _lastStatus!;
      robot.status = robot.lastStatus!;
    }
  }

  Color setStateColor(BuildContext context) {
    if (status != 'offline') {
      return Theme.of(context).colorScheme.primary;
    } else {
      return Theme.of(context).colorScheme.errorContainer;
    }
  }
}

class Servers {
  final List<Server> _servers = [];

  List<Server> get servers => _servers;

  // add server
  void addServer(Server server) {
    _servers.add(server);
  }

  //remove server
  void removeServer(Server server) {
    _servers.remove(server);
  }

  void editServer(Server editedServer) {
    final index = _servers.indexWhere((server) => server.id == editedServer.id);
    _servers[index] = editedServer;
  }
}
