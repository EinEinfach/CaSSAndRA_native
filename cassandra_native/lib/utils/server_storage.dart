import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cassandra_native/models/server.dart';

class ServerStorage {
  static const _serversKey = 'servers';

  static Future<void> saveServers(List<Server> servers) async {
    final prefs = await SharedPreferences.getInstance();
    final serverList = servers.map((server) => server.toJson()).toList();
    prefs.setString(_serversKey, jsonEncode(serverList));
  }

  static Future<List<Server>> loadServers() async {
    final prefs = await SharedPreferences.getInstance();
    final serverListString = prefs.getString(_serversKey);
    if (serverListString != null) {
      final List<dynamic> serverListJson = jsonDecode(serverListString);
      return serverListJson.map((json) => Server.fromJson(json)).toList();
    }
    return [];
  }
}