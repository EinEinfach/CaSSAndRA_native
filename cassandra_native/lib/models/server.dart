import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();

enum Category { ardumower, alfred, landrumower, other }

final categoryImages = {
  Category.ardumower: Image.asset('lib/images/artic_hare.png'),
  Category.alfred: Image.asset('lib/images/artic_hare.png'),
  Category.landrumower: Image.asset('lib/images/artic_hare.png'),
  Category.other: Image.asset('lib/images/artic_hare.png'),
};

class Server {
  Server({
    required this.category,
    required this.mqttServer,
    required this.clientId,
    required this.port,
    required this.user,
    required this.password,
  }) : id = uuid.v4();

  final String id;
  final Category category;
  final String mqttServer;
  final String clientId;
  final int port;
  final String user;
  final String password;
}

class Servers extends ChangeNotifier {
  final List<Server> _servers = [
    Server(
      category: Category.alfred,
      clientId: "dummy server 1",
      mqttServer: "192.168.2.21",
      password: "123456",
      user: "test",
      port: 1831,
    ),
    Server(
      category: Category.alfred,
      clientId: "dummy server 2",
      mqttServer: "192.168.2.21",
      password: "123456",
      user: "test",
      port: 1831,
    ),
  ];

  List<Server> get servers => _servers;

  // add server
  void addServer(Server server){
    _servers.add(server);
    notifyListeners();
  }

  //remove server
  void removeServer(Server server){
    _servers.remove(server);
    notifyListeners();
  }
}
