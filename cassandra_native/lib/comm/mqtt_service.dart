import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  final MqttServerClient client;

  MqttService(String mqttServer, String clientId)
      : client = MqttServerClient(mqttServer, clientId);

  Future<void> connect() async {
    client.logging(on: true);
    client.setProtocolV31();
    client.keepAlivePeriod = 20;
    client.onDisconnected = onDisconnected;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier('flutter_client')
        .startClean()
        .withWillQos(MqttQos.atMostOnce);
    client.connectionMessage = connMessage;
  
    try {
      await client.connect();
    } on Exception catch (e) {
      print('EXAMPLE::client exception - $e');
      disconnect();
    }

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print('EXAMPLE::MQTT client connected');
    } else {
      print('EXAMPLE::ERROR MQTT client connection failed - disconnecting state is ${client.connectionStatus!.state}');
      disconnect();
    }
  }
  
  void onDisconnected(){
    print('EXAMPLE::OnDisconnected client callback - Client disconnection');
  }

  void disconnect() {
    print('Disconnecting');
    client.disconnect();
  }

  void subscribe(String topic) {
    client.subscribe(topic, MqttQos.atMostOnce);
  }

  Stream<List<MqttReceivedMessage<MqttMessage>>>? getUpdates() {
      return client.updates;
    }
}
