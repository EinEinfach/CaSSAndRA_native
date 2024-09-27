import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:cassandra_native/cassandra_native.dart';
import 'package:cassandra_native/utils/ui_state_storage.dart';
import 'package:cassandra_native/utils/server_storage.dart';

import 'package:cassandra_native/data/app_data.dart';

import 'package:cassandra_native/comm/mqtt_manager.dart';

import 'package:cassandra_native/pages/mobile/servers_page_mobile.dart';
import 'package:cassandra_native/pages/tablet/servers_page_tablet.dart';
import 'package:cassandra_native/pages/desktop/servers_page_desktop.dart';

import 'package:cassandra_native/components/customized_elevated_button.dart';

import 'package:cassandra_native/components/servers_page/new_server.dart';
import 'package:cassandra_native/components/servers_page/server_item.dart';
import 'package:cassandra_native/components/servers_page/server_item_v_2.dart';
import 'package:cassandra_native/components/servers_page/dismiss_item.dart';
import 'package:cassandra_native/components/servers_page/info_item.dart';

import 'package:cassandra_native/models/server.dart';

// globals
import 'package:cassandra_native/data/user_data.dart' as user;

class ServersPage extends StatefulWidget {
  const ServersPage({super.key});

  @override
  State<ServersPage> createState() => _ServersPageState();
}

class _ServersPageState extends State<ServersPage> {
  late IconData listViewIcon;
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;

  @override
  void dispose() {
    super.dispose();
    for (var server in user.registredServers.servers) {
      MqttManager.instance.unregisterCallback(server.id, onMessageReceived);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadStoragedUiState();
    _loadServers();
  }

  void _handleAppLifecycleState(AppLifecycleState oldState, AppLifecycleState newState) {
    if (newState == AppLifecycleState.resumed && oldState != AppLifecycleState.resumed) {
      _connectToServers();
    }
  }

  Future<void> _loadServers() async {
    final List<Server> loadedServers;
    if (user.registredServers.servers.isEmpty) {
      loadedServers = await ServerStorage.loadServers();
      for (var server in loadedServers) {
        user.registredServers.addServer(server);
      }
    }
    _connectToServers();
    setState(() {});
  }

  void _connectToServers() {
    for (var server in user.registredServers.servers) {
      if (MqttManager.instance.isNotConnected(server.id)) {
        _connectToServer(server);
      } else {
        MqttManager.instance.registerCallback(server.id, onMessageReceived);
      }
    }
  }

  Future<void> _connectToServer(Server server) async {
    await MqttManager.instance
        .create(server.serverInterface, onMessageReceived);
  }

  Future<void> _loadStoragedUiState() async {
    user.storedUiState = await UiStateStorage.loadUiState();
    setState(() {});
  }

  void onMessageReceived(String clientId, String topic, String message) {
    var server =
        user.registredServers.servers.firstWhere((s) => s.id == clientId);
    server.onMessageReceived(clientId, topic, message);
    setState(() {
    });
  }

  void removeServer(BuildContext context, Server server) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: Theme.of(context).colorScheme.secondary,
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

  void _onDismissedServer(BuildContext context, Server server) {
    String name = server.serverNamePrefix;
    setState(() {
      MqttManager.instance.disconnect(server.id);
      user.registredServers.removeServer(server);
      ServerStorage.saveServers(user.registredServers.servers);
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: Theme.of(context).colorScheme.secondary,
      content: Text(
        '$name removed',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      ),
      duration: const Duration(seconds: 5),
    ));
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        title: const Text(
          'Add new server instance',
          style: TextStyle(fontSize: 14),
        ),
        content: NewServer(onAddServer: addServer),
      ),
    );
  }

  void openEditServerOverlay(BuildContext context, Server server) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        title: const Text(
          'Edit server instance',
          style: TextStyle(fontSize: 14),
        ),
        content: NewServer(onAddServer: editServer, server: server),
      ),
    );
  }

  void onListViewChange() {
    if (user.storedUiState.serversListViewOrientation == 'vertical') {
      user.storedUiState.serversListViewOrientation = 'horizontal';
    } else {
      user.storedUiState.serversListViewOrientation = 'vertical';
    }
    UiStateStorage.saveUiState(user.storedUiState);
    setState(() {});
  }

  void openInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        title: const Text(
          'CaSSAndRA native',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          CustomizedElevatedButton(
            text: 'ok',
            onPressed: () => Navigator.pop(context),
          ),
        ],
        content: const InfoItem(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    _handleAppLifecycleState(_appLifecycleState, Provider.of<CassandraNative>(context).appLifecycleState);
    _appLifecycleState = Provider.of<CassandraNative>(context).appLifecycleState;

    Widget mainContent = Center(
      child: const Text('No Server found. Start with add button')
          .animate()
          .shake(),
    );
    if (user.registredServers.servers.isNotEmpty &&
        user.storedUiState.serversListViewOrientation == 'vertical') {
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
                serverItemColor: server.setStateColor(context),
                onRemoveServer: () => removeServer(context, server),
                openEditServer: () => openEditServerOverlay(context, server),
              ).animate().fadeIn().scale();
            },
          ),
        ),
      );
    } else if (user.registredServers.servers.isNotEmpty &&
        user.storedUiState.serversListViewOrientation == 'horizontal') {
      mainContent = SingleChildScrollView(
        child: SizedBox(
          height: 500,
          child: ListView.builder(
            scrollDirection: Axis.vertical,
            itemCount: user.registredServers.servers.length,
            itemBuilder: (context, index) {
              final server = user.registredServers.servers[index];
              return Dismissible(
                key: Key(server.id),
                background: const DismissItem(),
                onDismissed: (direction) => _onDismissedServer(context, server),
                child: ServerItemV2(
                  server: server,
                  serverItemColor: server.setStateColor(context),
                  openEditServer: () => openEditServerOverlay(context, server),
                ).animate().fadeIn().scale(),
              );
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

    listViewIcon = user.storedUiState.serversListViewOrientation == 'horizontal'
        ? Icons.view_column
        : Icons.list;

    return LayoutBuilder(builder: (context, constrains) {
      //+++++++++++++++++++++++++++++++++++++++++++++++mobile page++++++++++++++++++++++++++++++++++++++++++++++++++++
      if (constrains.maxWidth < smallWidth) {
        return ServersPageMobile(
          mainContent: mainContent,
          listViewIcon: listViewIcon,
          onListViewChange: onListViewChange,
          onInfoButtonPressed: openInfoDialog,
        );
        //+++++++++++++++++++++++++++++++++++++++++++++++tablet page++++++++++++++++++++++++++++++++++++++++++++++++++++
      } else if (constrains.maxWidth < largeWidth) {
        return ServersPageTablet(
          mainContent: mainContent,
          listViewIcon: listViewIcon,
          onListViewChange: onListViewChange,
          onInfoButtonPressed: openInfoDialog,
        );
        //+++++++++++++++++++++++++++++++++++++++++++++++desktop page++++++++++++++++++++++++++++++++++++++++++++++++++++
      } else {
        return ServersPageDesktop(
          mainContent: mainContent,
          listViewIcon: listViewIcon,
          onListViewChange: onListViewChange,
          onInfoButtonPressed: openInfoDialog,
        );
      }
    });
  }
}
