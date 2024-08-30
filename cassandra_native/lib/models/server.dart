import 'package:cassandra_native/models/landscape.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:cassandra_native/models/robot.dart';

const uuid = Uuid();

enum Category { ardumower, alfred, landrumower, other }

final categoryImages = {
  Category.ardumower: Image.asset('lib/images/artic_hare.png'),
  Category.alfred: Image.asset('lib/images/artic_hare.png'),
  Category.landrumower: Image.asset('lib/images/landrumower.png'),
  Category.other: Image.asset('lib/images/in_app_icon.png'),
};

class Server {
  Server({
    required this.id,
    required this.category,
    required this.mqttServer,
    required this.serverNamePrefix,
    required this.port,
    required this.user,
    required this.password,
  });

  final String id;
  final Category category;
  final String mqttServer;
  final String serverNamePrefix;
  final int port;
  final String user;
  final String password;
  String status = "offline";
  Color stateColor = Colors.deepOrange;

  String preparedCmd = "home";

  Robot robot = Robot();
  Landscape currentMap = Landscape();

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category.name,
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
      mqttServer: json['mqttServer'],
      serverNamePrefix: json['serverNamePrefix'],
      port: json['port'],
      user: json['user'],
      password: json['password'],
    );
  }
}

class Servers {
  final List<Server> _servers = [];

  List<Server> get servers => _servers;

  // add server
  void addServer(Server server){
    _servers.add(server);
  }

  //remove server
  void removeServer(Server server){
    _servers.remove(server);
  }

  void editServer(Server editedServer){
    final index = _servers.indexWhere((server) => server.id == editedServer.id);
    _servers[index] = editedServer;
  }
}