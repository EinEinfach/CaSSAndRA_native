import 'dart:async';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

//import 'package:cassandra_native/models/server.dart';
import 'package:cassandra_native/comm/server_interface.dart';

class MqttManager {
  MqttManager._privateConstructor();

  static final MqttManager instance = MqttManager._privateConstructor();

  final Map<String, MqttServerClient> _clients = {};
  final Map<String, List<Function(String, String, String)>> _messageCallbacks =
      {};
  final Map<String, Timer?> _reconnectTimers = {};
  final Map<String, Timer?> _offlineTimers = {};
  Timer? appLifecycleStateTimer;
  final Duration offlineDuration = const Duration(seconds: 20);
  final Duration offlineDurationAppLifecycle = const Duration(seconds: 20);

  Future<void> create(
      ServerInterface server, Function(String, String, String) onMessageReceived) async {
    if (_clients.containsKey(server.id)) {
      _addCallback(server.id, onMessageReceived);
      return;
    }

    String clientId = server.id;
    var client = MqttServerClient(server.mqttServer, clientId);

    client.logging(on: false);
    client.onConnected = () => _subscribeTopics(server);
    client.onDisconnected = () => _handleDisconnection(clientId);
    // client.onSubscribed =
    //     (topic) => print('Subscribed to $topic for client $clientId');
    // client.onSubscribeFail =
    //     (topic) => print('Failed to subscribe $topic for client $clientId');
    //client.pongCallback = () => print('Ping response client callback invoked');

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .authenticateAs(server.user, server.password)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    client.connectionMessage = connMessage;
    _clients[clientId] = client;
    _messageCallbacks[clientId] = [onMessageReceived];
    await connect(clientId);
  }

  Future<void> connect(String clientId) async {
    MqttServerClient? client = _clients[clientId];
    try {
      await client?.connect();
      if (client?.connectionStatus!.state == MqttConnectionState.connected) {
        //print('MQTT connected for client $clientId');
        _cancelReconnectTimer(clientId);
        _startOfflineTimer(clientId);

        client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
          final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
          final String message =
              MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
          final String topic = c[0].topic;
          //print('Received message: $message from topic: $topic');
          _messageCallbacks[clientId]?.forEach((callback) {
            callback.call(clientId, topic, message);
            _resetOfflineTimer(clientId);
          });
        });
      } else {
        //print('ERROR: MQTT connection failed for client $clientId - ${client.connectionStatus}');
        _startReconnectTimer(clientId);
      }
    } catch (e) {
      //print('Exception: $e');
      client?.disconnect();
      _startReconnectTimer(clientId);
    }
  }

  void _addCallback(
      String clientId, Function(String, String, String) onMessageReceived) {
    if (_messageCallbacks.containsKey(clientId)) {
      if (!_messageCallbacks[clientId]!.contains(onMessageReceived)) {
        _messageCallbacks[clientId]!.add(onMessageReceived);  
      }
    } else {
      _messageCallbacks[clientId] = [onMessageReceived];
    }
  }

  void registerCallback(
      String clientId, Function(String, String, String) onMessageReceived) {
    _addCallback(clientId, onMessageReceived);
  }

  void unregisterCallback(
      String clientId, Function(String, String, String) onMessageReceived) {
    if (_messageCallbacks.containsKey(clientId)) {
      _messageCallbacks[clientId]!.remove(onMessageReceived);
      if (_messageCallbacks[clientId]!.isEmpty) {
        _messageCallbacks.remove(clientId);
      }
    }
  }

  void _subscribeTopics(ServerInterface server) {
    subscribe(server.id, '${server.serverNamePrefix}/status');
    subscribe(server.id, '${server.serverNamePrefix}/server');
    subscribe(server.id, '${server.serverNamePrefix}/robot');
    subscribe(server.id, '${server.serverNamePrefix}/map');
    subscribe(server.id, '${server.serverNamePrefix}/coords');
    subscribe(server.id, '${server.serverNamePrefix}/tasks');
    subscribe(server.id, '${server.serverNamePrefix}/maps');
    subscribe(server.id, '${server.serverNamePrefix}/mapsCoords');
    subscribe(server.id, '${server.serverNamePrefix}/settings');
  }

  void subscribe(String clientId, String topic) {
    _resetOfflineTimer(clientId);
    var client = _clients[clientId];
    if (client != null) {
      client.subscribe(topic, MqttQos.atLeastOnce);
      //print('Client $clientId subscribed to $topic');
    } else {
      //print('Client $clientId is not connected');
    }
  }

  void publish(String clientId, String topic, String message) {
    var client = _clients[clientId];
    if (client != null) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(message);
      client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
      //print('Client $clientId published message $message to $topic');
    } else {
      //print('Client $clientId is not connected');
    }
  }

  void disconnect(String clientId) {
    var client = _clients[clientId];
    client?.disconnect();
    _cancelReconnectTimer(clientId);
    _cancelOfflineTimer(clientId);
    _clients.remove(clientId);
    _messageCallbacks.remove(clientId);
    //print('Client $clientId disconnected');
  }

  void disconnectAll() {
    var clients = Map.from(_clients);
    for (var clientId in clients.keys) {
      disconnect(clientId);
      _cancelReconnectTimer(clientId);
    }
    _clients.clear();
    _messageCallbacks.clear();
  }

  void _handleDisconnection(String clientId) {
    _messageCallbacks[clientId]?.forEach((callback) {
      callback.call(clientId, '/status', 'offline');
    });
    _startReconnectTimer(clientId);
    _cancelOfflineTimer(clientId);
  }

  void _startReconnectTimer(String clientId) {
    _cancelReconnectTimer(clientId);
    _reconnectTimers[clientId] =
        Timer.periodic(const Duration(seconds: 5), (timer) {
      connect(clientId);
    });
  }

  void _cancelReconnectTimer(String clientId) {
    _reconnectTimers[clientId]?.cancel();
    _reconnectTimers.remove(clientId);
  }

  void _startOfflineTimer(String clientId) {
    _cancelOfflineTimer(clientId);
    _offlineTimers[clientId] = Timer(offlineDuration, () {
      _handleDisconnection(clientId);
    });
  }

  void _resetOfflineTimer(String clientId) {
    _startOfflineTimer(clientId);
  }

  void _cancelOfflineTimer(String clientId) {
    _offlineTimers[clientId]?.cancel();
    _offlineTimers.remove(clientId);
  }

  // void startAppLifecycleStateTimer() {
  //   appLifecycleStateTimer = Timer(offlineDurationAppLifecycle, () {
  //     disconnectAll();
  //   });
  // }

  // void cancelAppLifecycleStateTimer() {
  //   if (appLifecycleStateTimer != null) {
  //     appLifecycleStateTimer!.cancel();
  //   }
  // }

  bool isNotConnected(String clientId) {
    if (_clients.containsKey(clientId)) {
      final client = _clients[clientId];
      return !(client?.connectionStatus?.state ==
          MqttConnectionState.connected);
    }
    return true;
  }
}
