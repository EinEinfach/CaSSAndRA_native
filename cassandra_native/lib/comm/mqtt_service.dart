import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  final Map<String, MqttServerClient> _clients = {};
  final Function(String, String)? onMessageReceived;

  MqttService(this.onMessageReceived);

  Future<void> connect(String broker, String clientId) async {
    var client = MqttServerClient(broker, clientId);
    client.logging(on: false);
    client.onConnected = () => onConnected(clientId);
    client.onDisconnected = () => onDisconnected(clientId);
    client.onSubscribed = (topic) => onSubscribed(clientId, topic);
    client.onSubscribeFail = (topic) => onSubscribeFail(clientId, topic);

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    client.connectionMessage = connMessage;

    try {
      await client.connect();
    } catch (e) {
      print('Exception: $e');
      client.disconnect();
    }

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print('MQTT connected for client $clientId');
      _clients[clientId] = client;
      client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
        final String message =
            MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
        final String topic = c[0].topic;

        if (onMessageReceived != null) {
          onMessageReceived!(topic, message);
        }
      });
    } else {
      print(
          'ERROR: MQTT connection failed for client $clientId - ${client.connectionStatus}');
    }
  }

  void subscribe(String clientId, String topic) {
    var client = _clients[clientId];
    if (client != null) {
      client.subscribe(topic, MqttQos.atLeastOnce);
    }
  }

  void publish(String clientId, String topic, String message){
    var client = _clients[clientId];
    if (client != null){
      final builder = MqttClientPayloadBuilder();
      builder.addString(message);
      client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
    }
  }

  void onConnected(String clientId) {
    print('Connected $clientId');
  }

  void onDisconnected(String clientId) {
    print('Disconnected $clientId');
  }

  void onSubscribed(String clientId, String topic) {
    print('Subscribed to $topic for client $clientId');
  }

  void onSubscribeFail(String clientId, String topic) {
    print('Failed to subscribe $topic for client $clientId');
  }

  void pong() {
    print('Ping response client callback invoked');
  }

  void disconnect(String clientId) {
    var client = _clients[clientId];
    client?.disconnect();
    _clients.remove(clientId);
  }

  void disconnectAll() {
    for (var client in _clients.values) {
      client.disconnect();
    }
    _clients.clear();
  }
}
