import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:cassandra_native/models/robot.dart';
import 'package:cassandra_native/models/landscape.dart';
import 'package:cassandra_native/comm/server_interface.dart';

const uuid = Uuid();

enum Category { ardumower, alfred, landrumower, other }

final categoryImages = {
  Category.ardumower: ['lib/images/artic_hare.png', 'lib/images/ardumower/rover0grad.png'],
  Category.alfred: ['lib/images/artic_hare.png', 'lib/images/alfred/rover0grad.png'],
  Category.landrumower: ['lib/images/landrumower.png', 'lib/images/landrumower/rover0grad.png'],
  Category.other: ['lib/images/in_app_icon.png', 'lib/images/other/rover0grad.png']
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
  }) : serverInterface = ServerInterface(
          id: id,
          mqttServer: mqttServer,
          port: port,
          serverNamePrefix: serverNamePrefix,
          user: user,
          password: password,
        );

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

  String preparedCmd = "home";

  Robot robot = Robot();
  Landscape currentMap = Landscape();

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category.name,
        'alias': alias,
        'mqttServer': mqttServer,
        'serverNamePrefix': serverNamePrefix,
        'port': port,
        'user': user,
        'password': password,
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
    );
  }

  void onMessageReceived(String clientId, String topic, String message) {
    if (topic.contains('/status')) {
      status = message;
      if (status == 'offline') {
        robot.status = 'offline';
      } 
    } else if (topic.contains('/robot')) {
      robot.jsonToClassData(message);
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
    } else if (topic.contains('/coords')) {
      currentMap.coordsJsonToClassData(message);
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
    if (status != 'offline'){
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
