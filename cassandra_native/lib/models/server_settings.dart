import 'dart:convert';
import 'package:flutter/foundation.dart';

enum ConnectionType {
  http,
  mqtt,
  uart,
}

enum ApiType {
  deactivated,
  mqtt,
}

class ServerSettings {
  ConnectionType robotConnectionType = ConnectionType.http;
  // http
  String? httpRobotIpAdress;
  String? httpRobotPassword;
  // mqtt
  String? mqttClientId;
  String? mqttUser;
  String? mqttPassword;
  String? mqttServer;
  int? mqttPort;
  String? mqttMowerNameWithPrefix;
  // uart
  String? uartPort;
  int? uartBaudrate;
  // api
  ApiType apiType = ApiType.deactivated;
  String? apiMqttClientId;
  String? apiMqttUser;
  String? apiMqttPassword;
  String? apiMqttServer;
  int? apiMqttPort;
  String? apiMqttCassandraServerName;

  void settingsJsonToClassData(String message) {
    var decodedMessage = jsonDecode(message) as Map<String, dynamic>;
    try {
      robotConnectionType = ConnectionType.values
          .byName(decodedMessage['robotConnectionType'].toLowerCase());
      // _getConnectionTypeFromString(decodedMessage['robotConnectionType']) ??
      //     ConnectionType.http;
      httpRobotIpAdress = decodedMessage['httpRobotIpAdress'];
      httpRobotPassword = decodedMessage['httpRobotPassword'];
      mqttClientId = decodedMessage['mqttClientId'];
      mqttUser = decodedMessage['mqttUser'];
      mqttPassword = decodedMessage['mqttPassword'];
      mqttServer = decodedMessage['mqttServer'];
      mqttPort = decodedMessage['mqttPort'];
      mqttMowerNameWithPrefix = decodedMessage['mqttMowerNameWithPrefix'];
      uartPort = decodedMessage['uartPort'];
      uartBaudrate = decodedMessage['uartBaudrate'];
      apiType = ApiType.values.byName(decodedMessage['apiType'].toLowerCase());
      apiMqttClientId = decodedMessage['apiMqttClientId'];
      apiMqttUser = decodedMessage['apiMqttUser'];
      apiMqttPassword = decodedMessage['apiMqttPassword'];
      apiMqttServer = decodedMessage['apiMqttServer'];
      apiMqttCassandraServerName = decodedMessage['apiMqttCassandraServerName'];
      apiMqttPort = decodedMessage['apiMqttPort'];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Invalid settings JSON: $e');
      }
    }
  }

  // ConnectionType? _getConnectionTypeFromString(String connectionTypeString) {
  //   switch (connectionTypeString) {
  //     case 'HTTP':
  //       return ConnectionType.http;
  //     case 'MQTT':
  //       return ConnectionType.mqtt;
  //     case 'UART':
  //       return ConnectionType.uart;
  //     default:
  //       if (kDebugMode) {
  //         debugPrint('Invalid value for robotConnectionType in settings JSON');
  //       }
  //       return null;
  //   }
  // }

  Map<String, dynamic> toJson() => {
        'robotConnectionType': robotConnectionType.name.toUpperCase(),
        'httpRobotIpAdress': httpRobotIpAdress,
        'httpRobotPassword': httpRobotPassword,
        'mqttClientId': mqttClientId,
        'mqttUser': mqttUser,
        'mqttPassword': mqttPassword,
        'mqttServer': mqttServer,
        'mqttPort': mqttPort,
        'mqttMowerNameWithPrefix': mqttMowerNameWithPrefix,
        'uartPort': uartPort,
        'uartBaudrate': uartBaudrate,
        'apiType': apiType == ApiType.mqtt ? 'MQTT' : '',
        'apiMqttClientId': apiMqttClientId,
        'apiMqttUser': apiMqttUser,
        'apiMqttPassword': apiMqttPassword,
        'apiMqttServer': apiMqttServer,
        'apiMqttCassandraServerName': apiMqttCassandraServerName,
        'apiMqttPort': apiMqttPort,
      };
}
