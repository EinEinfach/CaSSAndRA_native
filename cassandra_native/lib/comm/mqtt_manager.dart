import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttManager {
  MqttManager._privateConstructor();

  static final MqttManager instance = MqttManager._privateConstructor();

  final Map<String, MqttServerClient> _clients = {};
  final Map<String, Function(String, String)> _messageCallbacks = {};

  Future<void> connect(String mqttServer, String clientId, Function(String, String) onMessageReceived) async {
    if (_clients.containsKey(clientId)) {
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
      _clients[clientId] = client;
      _messageCallbacks[clientId] = onMessageReceived;
      client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
        final String message =
            MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
        final String topic = c[0].topic;
        _messageCallbacks[clientId]?.call(topic, message);
      });
    } catch (e) {
      print('Exception: $e');
      client.disconnect();
    }
  }

  void subscribe(String clientId, String topic) {
    var client = _clients[clientId];
    client?.subscribe(topic, MqttQos.atLeastOnce);
  }

  void publish(String clientId, String topic, String message) {
    var client = _clients[clientId];
    if (client != null) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(message);
      client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
    }
  }

  void disconnect(String clientId) {
    var client = _clients[clientId];
    client?.disconnect();
    _clients.remove(clientId);
    _messageCallbacks.remove(clientId);
  }

  void disconnectAll() {
    for (var client in _clients.values) {
      client.disconnect();
    }
    _clients.clear();
    _messageCallbacks.clear();
  }
}