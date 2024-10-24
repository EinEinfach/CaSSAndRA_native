import 'package:flutter/material.dart';

import 'package:cassandra_native/comm/mqtt_manager.dart';
import 'package:cassandra_native/data/app_data.dart';
import 'package:cassandra_native/components/nav_drawer.dart';
import 'package:cassandra_native/models/server.dart';
import 'package:cassandra_native/components/settings_page/accordion_tile.dart';
import 'package:cassandra_native/components/settings_page/content_server_tile.dart';
import 'package:cassandra_native/components/settings_page/content_api_tile.dart';
import 'package:cassandra_native/components/settings_page/content_message_service_tile.dart';

class SettingsPage extends StatefulWidget {
  final Server server;
  const SettingsPage({
    super.key,
    required this.server,
  });

  @override
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void dispose() {
    MqttManager.instance
        .unregisterCallback(widget.server.id, onMessageReceived);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _connectToServer();
    if (!MqttManager.instance.isNotConnected(widget.server.id)) {
      widget.server.serverInterface.commandUpdateSettings();
    }
  }

  Future<void> _connectToServer() async {
    if (MqttManager.instance.isNotConnected(widget.server.id)) {
      await MqttManager.instance
          .create(widget.server.serverInterface, onMessageReceived);
    } else {
      MqttManager.instance
          .registerCallback(widget.server.id, onMessageReceived);
    }
  }

  void onMessageReceived(String clientId, String topic, String message) {
    widget.server.onMessageReceived(clientId, topic, message);
    if (topic.contains('/settings')) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constrains) {
        //+++++++++++++++++++++++++++++++++++++++++++++++mobile page++++++++++++++++++++++++++++++++++++++++++++++++++++
        if (constrains.maxWidth < smallWidth) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: Builder(builder: (context) {
                return IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                );
              }),
            ),
            drawer: NavDrawer(
              server: widget.server,
            ),
            body: SafeArea(
              child: ListView(
                children: [
                  AccordionTile(
                    title: 'Server',
                    content: [
                      ContentServerTile(
                        currentServer: widget.server,
                      ),
                    ],
                  ),
                  AccordionTile(
                    title: 'API',
                    content: [
                      ContentApiTile(currentServer: widget.server),
                    ],
                  ),
                  AccordionTile(
                    title: 'Messsage service',
                    content: [
                      ContentMessageServiceTile(currentServer: widget.server),
                    ],
                  ),
                ],
              ),
            ),
          );
          //+++++++++++++++++++++++++++++++++++++++++++++++tablet page++++++++++++++++++++++++++++++++++++++++++++++++++++
        } else if (constrains.maxWidth < largeWidth) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: Builder(builder: (context) {
                return IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                );
              }),
            ),
            drawer: NavDrawer(
              server: widget.server,
            ),
          );
          //+++++++++++++++++++++++++++++++++++++++++++++++desktop page++++++++++++++++++++++++++++++++++++++++++++++++++++
        } else {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
            ),
            body: Row(
              children: [
                NavDrawer(
                  server: widget.server,
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
