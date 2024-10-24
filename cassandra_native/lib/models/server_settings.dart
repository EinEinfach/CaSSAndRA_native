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

enum MessageServiceType { deactivated, telegram, pushover }

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
  // message service type
  MessageServiceType messageServiceType = MessageServiceType.deactivated;
  String? telegramApiToken;
  String? telegramChatId;
  String? pushoverApiToken;
  String? pushoverAppName;

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
      apiType = decodedMessage['apiType'] != null
          ? ApiType.values.byName(decodedMessage['apiType'].toString().toLowerCase())
          : ApiType.deactivated;
      apiMqttClientId = decodedMessage['apiMqttClientId'];
      apiMqttUser = decodedMessage['apiMqttUser'];
      apiMqttPassword = decodedMessage['apiMqttPassword'];
      apiMqttServer = decodedMessage['apiMqttServer'];
      apiMqttCassandraServerName = decodedMessage['apiMqttCassandraServerName'];
      apiMqttPort = decodedMessage['apiMqttPort'];
      messageServiceType = decodedMessage['messageServiceType'] != null
          ? MessageServiceType.values
              .byName(decodedMessage['messageServiceType'].toString().toLowerCase())
          : MessageServiceType.deactivated;
      telegramApiToken = decodedMessage['telegramApiToken'].toString();
      telegramChatId = decodedMessage['telegramChatId'].toString();
      pushoverApiToken = decodedMessage['pushoverApiToken'].toString();
      pushoverAppName = decodedMessage['pushoverAppName'].toString();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Invalid settings JSON: $e');
      }
    }
  }

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
        'apiType': apiType == ApiType.mqtt ? 'MQTT' : null,
        'apiMqttClientId': apiMqttClientId,
        'apiMqttUser': apiMqttUser,
        'apiMqttPassword': apiMqttPassword,
        'apiMqttServer': apiMqttServer,
        'apiMqttCassandraServerName': apiMqttCassandraServerName,
        'apiMqttPort': apiMqttPort,
        'messageServiceType':
            messageServiceType == MessageServiceType.deactivated
                ? null
                : messageServiceType.name,
        'telegramApiToken': telegramApiToken,
        'telegramChatId': telegramChatId,
        'pushoverApiToken': pushoverApiToken,
        'pushoverAppName': pushoverAppName,
      };
}
