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

enum PositionMode {
  absolute,
  relative,
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
  // robot position mode
  PositionMode robotPositionMode = PositionMode.relative;
  double? longtitude;
  double? latitude;
  // robot speed set points
  double transitSpeedSetPoint = 0.3;
  double mowSpeedSetPoint = 0.3;
  // robot fix timeout
  int fixTimeout = 60;
  // app settings
  double? minVoltage;
  double? maxVoltage;
  double? chargeCurrentThd;
  int? dataMaxAge;
  int? offlineTimeout;

  void settingsJsonToClassData(String message) {
    var decodedMessage = jsonDecode(message) as Map<String, dynamic>;
    try {
      robotConnectionType = ConnectionType.values
          .byName(decodedMessage['robotConnectionType'].toString().toLowerCase());
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
          ? ApiType.values
              .byName(decodedMessage['apiType'].toString().toLowerCase())
          : ApiType.deactivated;
      apiMqttClientId = decodedMessage['apiMqttClientId'];
      apiMqttUser = decodedMessage['apiMqttUser'];
      apiMqttPassword = decodedMessage['apiMqttPassword'];
      apiMqttServer = decodedMessage['apiMqttServer'];
      apiMqttCassandraServerName = decodedMessage['apiMqttCassandraServerName'];
      apiMqttPort = decodedMessage['apiMqttPort'];
      messageServiceType = decodedMessage['messageServiceType'] != null
          ? MessageServiceType.values.byName(
              decodedMessage['messageServiceType'].toString().toLowerCase())
          : MessageServiceType.deactivated;
      telegramApiToken = decodedMessage['telegramApiToken'] == null
          ? ''
          : decodedMessage['telegramApiToken'].toString();
      telegramChatId = decodedMessage['telegramChatId'] == null
          ? ''
          : decodedMessage['telegramChatId'].toString();
      pushoverApiToken = decodedMessage['pushoverApiToken'] == null
          ? ''
          : decodedMessage['pushoverApiToken'].toString();
      pushoverAppName = decodedMessage['pushoverAppName'] == null
          ? ''
          : decodedMessage['pushoverAppName'].toString();
      robotPositionMode = PositionMode.values.byName(decodedMessage['robotPositionMode'],);
      longtitude = double.tryParse(decodedMessage['longtitude'].toString());
      latitude = double.tryParse(decodedMessage['latitude'].toString());
      transitSpeedSetPoint = double.tryParse(decodedMessage['transitSpeedSetPoint'].toString())!;
      mowSpeedSetPoint = double.tryParse(decodedMessage['mowSpeedSetPoint'].toString())!;
      fixTimeout = decodedMessage['fixTimeout'];
      minVoltage = decodedMessage['minVoltage'] != null
          ? double.tryParse(decodedMessage['minVoltage'].toString())
          : null;
      maxVoltage = decodedMessage['maxVoltage'] != null
          ? double.tryParse(decodedMessage['maxVoltage'].toString())
          : null;
      chargeCurrentThd = decodedMessage['chargeCurrentThd'] != null
          ? double.tryParse(decodedMessage['chargeCurrentThd'].toString())
          : null;
      dataMaxAge = decodedMessage['dataMaxAge'] != null
          ? int.tryParse(decodedMessage['dataMaxAge'].toString())
          : null;
      offlineTimeout = decodedMessage['offlineTimeout'] != null
          ? int.tryParse(decodedMessage['offlineTimeout'].toString())
          : null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Invalid settings JSON: $e');
      }
    }
  }

  Map<String, dynamic> commCfgToJson() => {
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
  
  Map<String, dynamic> roverCfgToJson() => {
    'robotPositionMode': robotPositionMode.name,
    'longtitude': longtitude ?? 0.0,
    'latitude': latitude ?? 0.0,
  };

  Map<String, dynamic> appCfgToJson() => {
    'minVoltage': minVoltage ?? 0.0,
    'maxVoltage': maxVoltage ?? 0.0,
    'chargeCurrentThd': chargeCurrentThd ?? 0.0,
    'dataMaxAge': dataMaxAge ?? 0,
    'offlineTimeout': offlineTimeout ?? 0,
  };
}
