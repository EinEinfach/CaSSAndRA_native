import 'package:cassandra_native/components/common/buttons/nav_button.dart';
import 'package:flutter/material.dart';

import 'package:cassandra_native/comm/mqtt_manager.dart';
import 'package:cassandra_native/data/app_data.dart';
import 'package:cassandra_native/components/common/drawers/nav_drawer.dart';
import 'package:cassandra_native/models/server.dart';
import 'package:cassandra_native/components/settings_page/accordion_tile.dart';
import 'package:cassandra_native/components/settings_page/content_app_tile.dart';
import 'package:cassandra_native/components/settings_page/content_robot_tile.dart';
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
        .unregisterCallback(widget.server.id, _onMessageReceived);
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
          .create(widget.server.serverInterface, _onMessageReceived);
    } else {
      MqttManager.instance
          .registerCallback(widget.server.id, _onMessageReceived);
    }
  }

  void _onMessageReceived(String clientId, String topic, String message) {
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
            drawer: NavDrawer(
              server: widget.server,
            ),
            body: Builder(
              builder: (context) {
                return SafeArea(
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: NavButton(
                          icon: Icons.menu,
                          onPressed: () {
                            Scaffold.of(context).openDrawer();
                          },
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          children: [
                            AccordionTile(
                              title: 'App',
                              content: [
                                ContentAppTile(
                                  currentServer: widget.server,
                                ),
                              ],
                            ),
                            AccordionTile(
                              title: 'Robot',
                              content: [
                                ContentRobotTile(
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
                                ContentMessageServiceTile(
                                    currentServer: widget.server),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
          //+++++++++++++++++++++++++++++++++++++++++++++++tablet page++++++++++++++++++++++++++++++++++++++++++++++++++++
        } else if (constrains.maxWidth < largeWidth) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            drawer: NavDrawer(
              server: widget.server,
            ),
            body: Builder(
              builder: (context) {
                return SafeArea(
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: NavButton(
                          icon: Icons.menu,
                          onPressed: () {
                            Scaffold.of(context).openDrawer();
                          },
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          children: [
                            AccordionTile(
                              title: 'App',
                              content: [
                                ContentAppTile(
                                  currentServer: widget.server,
                                ),
                              ],
                            ),
                            AccordionTile(
                              title: 'Robot',
                              content: [
                                ContentRobotTile(
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
                                ContentMessageServiceTile(
                                    currentServer: widget.server),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
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
