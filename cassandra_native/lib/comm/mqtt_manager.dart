import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttManager {
  MqttManager._privateConstructor();

  static final MqttManager instance = MqttManager._privateConstructor();

  final Map<String, MqttServerClient> _clients = {};
  final Map<String, List<Function(String, String)>> _messageCallbacks = {};

  Future<void> connect(String mqttServer, String clientId, Function(String, String) onMessageReceived) async {
    if (_clients.containsKey(clientId)) {
      _addCallback(clientId, onMessageReceived);
      return;
    }

    var client = MqttServerClient(mqttServer, clientId);
    client.logging(on: false); 
    client.onConnected = () => print('Connected $clientId');
    client.onDisconnected = () => print('Disconnected $clientId');
    client.onSubscribed = (topic) => print('Subscribed to $topic for client $clientId');
    client.onSubscribeFail = (topic) => print('Failed to subscribe $topic for client $clientId');
    client.pongCallback = () => print('Ping response client callback invoked');

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    client.connectionMessage = connMessage;

    try {
      await client.connect();
      if (client.connectionStatus!.state == MqttConnectionState.connected) {
        //print('MQTT connected for client $clientId');
        _clients[clientId] = client;
        _messageCallbacks[clientId] = [onMessageReceived]; 
        client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
          final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
          final String message = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
          final String topic = c[0].topic;
          //print('Received message: $message from topic: $topic');
          _messageCallbacks[clientId]?.forEach((callback) {
            callback.call(topic, message);
          });
        });
      } else {
        //print('ERROR: MQTT connection failed for client $clientId - ${client.connectionStatus}');
      }
    } catch (e) {
      //print('Exception: $e');
      client.disconnect();
    }
  }

  void _addCallback(String clientId, Function(String, String) onMessageReceived) {
    _messageCallbacks[clientId]?.add(onMessageReceived);
  }

  void subscribe(String clientId, String topic) {
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
    _clients.remove(clientId);
    _messageCallbacks.remove(clientId);
    //print('Client $clientId disconnected');
  }

  void disconnectAll() {
    for (var client in _clients.values) {
      client.disconnect();
    }
    _clients.clear();
    _messageCallbacks.clear();
    //print('All clients disconnected');
  }
}