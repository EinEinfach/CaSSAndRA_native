import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:convert';

import 'package:cassandra_native/data/ui_state.dart';
import 'package:cassandra_native/utils/server_storage.dart';
import 'package:cassandra_native/comm/mqtt_service.dart';
import 'package:cassandra_native/pages/mobile/servers_page_mobile.dart';
import 'package:cassandra_native/pages/tablet/servers_page_tablet.dart';
import 'package:cassandra_native/pages/desktop/servers_page_desktop.dart';
import 'package:cassandra_native/components/servers_page/new_server.dart';
import 'package:cassandra_native/components/servers_page/server_item.dart';
import 'package:cassandra_native/components/customized_elevated_button.dart';
import 'package:cassandra_native/models/server.dart';

// globals


class ServersPage extends StatefulWidget {
  const ServersPage({super.key});

  @override
  State<ServersPage> createState() => _ServersPageState();
}

class _ServersPageState extends State<ServersPage> {
  Servers registredServers = Servers();
  late MqttService mqttService;

  @override
  void dispose() {
    mqttService.disconnectAll();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    mqttService = MqttService(onMessageReceived);
    _loadServers();
  }

  Future<void> _connectToServer(Server server) async {
    await mqttService.connect(server.mqttServer, server.id);
    mqttService.subscribe(server.id, '${server.serverNamePrefix}/status');
    mqttService.subscribe(server.id, '${server.serverNamePrefix}/robot');
  }

  Future<void> _loadServers() async {
    final List<Server> loadedServers;
    if (registredServers.servers.isEmpty) {
      loadedServers = await ServerStorage.loadServers();
      for (var server in loadedServers) {
        registredServers.addServer(server);
      }
    }
    setState(() {});
    for (var server in registredServers.servers) {
      _connectToServer(server);
    }
  }

  void onMessageReceived(String topic, String message) {
    setState(() {
      if (topic.contains('/status')) {
        var server = registredServers.servers
            .firstWhere((s) => '${s.serverNamePrefix}/status' == topic);
        server.status = message;
      } else if (topic.contains('/robot')) {
        var server = registredServers.servers
            .firstWhere((s) => '${s.serverNamePrefix}/robot' == topic);
        var decodedMessage = jsonDecode(message) as Map<String, dynamic>;
        server.robot.status = decodedMessage['status'];
      }
    });
  }

  void removeServer(BuildContext context, Server server) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: const Text('Remove this server?'),
        actions: [
          CustomizedElevatedButton(
            text: 'cancel',
            onPressed: () => Navigator.pop(context),
          ),
          CustomizedElevatedButton(
            text: 'yes',
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                mqttService.disconnect(server.serverNamePrefix);
                registredServers.removeServer(server);
                ServerStorage.saveServers(registredServers.servers);
              });
            },
          ),
        ],
      ),
    );
  }

  void addServer(Server server) {
    setState(() {
      registredServers.addServer(server);
      _connectToServer(server);
      ServerStorage.saveServers(registredServers.servers);
    });
  }

  void openAddServerOverlay() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => NewServer(onAddServer: addServer),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget mainContent = Center(
      child: const Text('No Server found. Start with add button')
          .animate()
          .shake(),
    );
    if (registredServers.servers.isNotEmpty) {
      mainContent = SizedBox(
        height: 500,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: registredServers.servers.length,
          itemBuilder: (context, index) {
            final server = registredServers.servers[index];
            return ServerItem(
              server: server,
              onRemoveServer: () => removeServer(context, server),
            ).animate().fadeIn().scale();
          },
        ),
      );
    }

    mainContent = Stack(
      children: [
        Container(
          child: mainContent,
        ),
        Container(
          alignment: const Alignment(0.9, 0.9),
          child: Container(
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              onPressed: openAddServerOverlay,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Icon(
                Icons.add,
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
            ),
          ),
        ),
      ],
    );

    return LayoutBuilder(builder: (context, constrains) {
      //+++++++++++++++++++++++++++++++++++++++++++++++mobile page++++++++++++++++++++++++++++++++++++++++++++++++++++
      if (constrains.maxWidth < smallWidth) {
        return ServersPageMobile(mainContent: mainContent);
        //+++++++++++++++++++++++++++++++++++++++++++++++tablet page++++++++++++++++++++++++++++++++++++++++++++++++++++
      } else if (constrains.maxWidth < largeWidth) {
        return ServersPageTablet(mainContent: mainContent);
        //+++++++++++++++++++++++++++++++++++++++++++++++desktop page++++++++++++++++++++++++++++++++++++++++++++++++++++
      } else {
        return ServersPageDesktop(mainContent: mainContent);
      }
    });
  }
}
