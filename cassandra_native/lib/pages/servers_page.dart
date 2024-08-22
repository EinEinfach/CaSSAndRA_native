import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:convert';

import 'package:cassandra_native/data/ui_state.dart';
import 'package:cassandra_native/utils/server_storage.dart';
import 'package:cassandra_native/comm/mqtt_manager.dart';
import 'package:cassandra_native/pages/mobile/servers_page_mobile.dart';
import 'package:cassandra_native/pages/tablet/servers_page_tablet.dart';
import 'package:cassandra_native/pages/desktop/servers_page_desktop.dart';
import 'package:cassandra_native/components/servers_page/new_server.dart';
import 'package:cassandra_native/components/servers_page/server_item.dart';
import 'package:cassandra_native/components/servers_page/server_item_v_2.dart';
import 'package:cassandra_native/components/customized_elevated_button.dart';
import 'package:cassandra_native/models/server.dart';

// globals
import 'package:cassandra_native/data/user_data.dart' as user;

class ServersPage extends StatefulWidget {
  const ServersPage({super.key});

  @override
  State<ServersPage> createState() => _ServersPageState();
}

class _ServersPageState extends State<ServersPage> {

  @override
  void dispose() {
    MqttManager.instance.disconnectAll();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadServers();
  }

  Future<void> _connectToServer(Server server) async {
    await MqttManager.instance
        .create(server, onMessageReceived);
    // MqttManager.instance
    //     .subscribe(server.id, '${server.serverNamePrefix}/status');
    // MqttManager.instance
    //     .subscribe(server.id, '${server.serverNamePrefix}/robot');
    // MqttManager.instance
    //     .subscribe(server.id, '${server.serverNamePrefix}/map');
    // MqttManager.instance
    //     .subscribe(server.id, '${server.serverNamePrefix}/coords');
  }

  Future<void> _loadServers() async {
    final List<Server> loadedServers;
    if (user.registredServers.servers.isEmpty) {
      loadedServers = await ServerStorage.loadServers();
      for (var server in loadedServers) {
        user.registredServers.addServer(server);
      }
    }
    setState(() {});
    for (var server in user.registredServers.servers) {
      _connectToServer(server);
    }
  }

  void onMessageReceived(String clientId, String topic, String message) {
    setState(() {
      if (topic.contains('/status')) {
        var server = user.registredServers.servers
            .firstWhere((s) => s.id == clientId);
        server.status = message;
        server.stateColor = Theme.of(context).colorScheme.primary;
        if (server.status == 'offline') {
          server.robot.status = 'offline';
          server.stateColor = Theme.of(context).colorScheme.errorContainer;
        }
      } else if (topic.contains('/robot')) {
        var server = user.registredServers.servers
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
                MqttManager.instance.disconnect(server.id);
                user.registredServers.removeServer(server);
                ServerStorage.saveServers(user.registredServers.servers);
              });
            },
          ),
        ],
      ),
    );
  }

  void addServer(Server server) {
    setState(() {
      user.registredServers.addServer(server);
      _connectToServer(server);
      ServerStorage.saveServers(user.registredServers.servers);
    });
  }

  void editServer(Server server) {
    setState(() {
      MqttManager.instance.disconnect(server.id);
      user.registredServers.editServer(server);
      _connectToServer(server);
      ServerStorage.saveServers(user.registredServers.servers);
    });
  }

  void openAddServerOverlay() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => NewServer(onAddServer: addServer),
    );
  }

  void openEditServerOverlay(BuildContext context, Server server) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => NewServer(onAddServer: editServer, server: server),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget mainContent = Center(
      child: const Text('No Server found. Start with add button')
          .animate()
          .shake(),
    );
    if (user.registredServers.servers.isNotEmpty && serverListViewOrientation == 'horizontal') {
      mainContent = SingleChildScrollView(
        child: SizedBox(
          height: 500,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: user.registredServers.servers.length,
            itemBuilder: (context, index) {
              final server = user.registredServers.servers[index];
              return ServerItem(
                server: server,
                serverItemColor: server.stateColor,
                onRemoveServer: () => removeServer(context, server),
                openEditServer: () => openEditServerOverlay(context, server),
              ).animate().fadeIn().scale();
            },
          ),
        ),
      );
    } else if (user.registredServers.servers.isNotEmpty && serverListViewOrientation == 'vertical') {
      mainContent = SingleChildScrollView(
        child: SizedBox(
          height: 500,
          child: ListView.builder(
            scrollDirection: Axis.vertical,
            itemCount: user.registredServers.servers.length,
            itemBuilder: (context, index) {
              final server = user.registredServers.servers[index];
              return ServerItemV2(
                server: server,
                serverItemColor: server.stateColor,
                onRemoveServer: () => removeServer(context, server),
                openEditServer: () => openEditServerOverlay(context, server),
              ).animate().fadeIn().scale();
            },
          ),
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
