import 'package:cassandra_native/pages/servers_page.dart';
import 'package:cassandra_native/utils/server_storage.dart';
import 'package:flutter/material.dart';

import 'package:cassandra_native/models/server.dart';
import 'package:cassandra_native/models/server_settings.dart';
import 'package:cassandra_native/components/common/customized_elevated_button.dart';
import 'package:cassandra_native/components/common/customized_dialog_ok.dart';
import 'package:cassandra_native/components/common/customized_dialog_ok_cancel.dart';

// globals
import 'package:cassandra_native/data/user_data.dart' as user;

class ContentApiTile extends StatefulWidget {
  final Server currentServer;
  const ContentApiTile({super.key, required this.currentServer});

  @override
  State<ContentApiTile> createState() => _ContentApiTileState();
}

class _ContentApiTileState extends State<ContentApiTile> {
  //late Server currentServer;
  // api type
  late ApiType selectedApiType;
  // mqtt
  final TextEditingController _apiMqttClientIdController =
      TextEditingController();
  final TextEditingController _apiMqttUserController = TextEditingController();
  final TextEditingController _apiMqttPasswordController =
      TextEditingController();
  final TextEditingController _apiMqttServerController =
      TextEditingController();
  final TextEditingController _apiMqttPortController = TextEditingController();
  final TextEditingController _apiMqttCassandraServerNameController =
      TextEditingController();

  @override
  void dispose() {
    _apiMqttClientIdController.dispose();
    _apiMqttUserController.dispose();
    _apiMqttPasswordController.dispose();
    _apiMqttServerController.dispose();
    _apiMqttPortController.dispose();
    _apiMqttCassandraServerNameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    selectedApiType = widget.currentServer.settings.apiType;
    _apiMqttClientIdController.text =
        widget.currentServer.settings.apiMqttClientId ?? '';
    _apiMqttUserController.text =
        widget.currentServer.settings.apiMqttUser ?? '';
    _apiMqttPasswordController.text =
        widget.currentServer.settings.apiMqttPassword ?? '';
    _apiMqttServerController.text =
        widget.currentServer.settings.apiMqttServer ?? '';
    _apiMqttCassandraServerNameController.text =
        widget.currentServer.settings.apiMqttCassandraServerName ?? '';
    _apiMqttPortController.text =
        widget.currentServer.settings.apiMqttPort != null
            ? widget.currentServer.settings.mqttPort.toString()
            : '';
    super.initState();
  }

  // @override
  // void didUpdateWidget(covariant ContentApiTile oldWidget) {
  //   if (widget.currentServer != oldWidget.currentServer) {
  //     setState(() {
  //       currentServer = widget.currentServer;
  //     });
  //   }
  //   super.didUpdateWidget(oldWidget);
  // }

  void _submitCommCfgData() {
    final enteredMqttPort = int.tryParse(_apiMqttPortController.text);

    bool inputInvalid = false;

    if (selectedApiType == ApiType.mqtt) {
      inputInvalid = _apiMqttClientIdController.text.isEmpty ||
          _apiMqttCassandraServerNameController.text.isEmpty ||
          _apiMqttServerController.text.isEmpty ||
          enteredMqttPort == null;
    }

    if (inputInvalid) {
      showDialog(
        context: context,
        builder: (context) => CustomizedDialogOk(
          title: 'Invalid input',
          content:
              'Please make sure valid values for api communication was entered',
          onOkPressed: () {
            Navigator.pop(context);
          },
        ),
      );
      return;
    }

    if (widget.currentServer.status == 'offline') {
      showDialog(
        context: context,
        builder: (context) => CustomizedDialogOk(
          title: 'Server offline',
          content: 'Server is offline. Data could not be set',
          onOkPressed: () {
            Navigator.pop(context);
          },
        ),
      );
      return;
    }

    widget.currentServer.settings.apiType = selectedApiType;
    widget.currentServer.settings.apiMqttClientId =
        _apiMqttClientIdController.text;
    widget.currentServer.settings.apiMqttCassandraServerName =
        _apiMqttCassandraServerNameController.text;
    widget.currentServer.settings.apiMqttServer = _apiMqttServerController.text;
    widget.currentServer.settings.apiMqttUser = _apiMqttUserController.text;
    widget.currentServer.settings.apiMqttPassword =
        _apiMqttPasswordController.text;
    widget.currentServer.settings.apiMqttPort =
        int.tryParse(_apiMqttPortController.text);
    widget.currentServer.serverInterface
        .commandSetSettings('setComm', widget.currentServer.settings.commCfgToJson());

    showDialog(
      context: context,
      builder: (context) => CustomizedDialogOkCancel(
        title: 'Server restart is necessary',
        content:
            'You have made changes to the API settings. Should these settings also be applied within the app, and the server to be restarted?\n\nPress ok to restart the server now, or cancel to perform the restart later yourself',
        onCancelPressed: () {
          Navigator.pop(context);
        },
        onOkPressed: () {
          widget.currentServer.serverInterface.commandRestartServer();
          widget.currentServer.disconnect();
          final Server editedServer = Server(
            id: widget.currentServer.id,
            category: widget.currentServer.category,
            alias: widget.currentServer.alias,
            mqttServer: widget.currentServer.settings.apiMqttServer ?? '',
            serverNamePrefix:
                widget.currentServer.settings.apiMqttCassandraServerName ?? '',
            port: widget.currentServer.settings.apiMqttPort ?? 1883,
            user: widget.currentServer.settings.apiMqttUser ?? '',
            password: widget.currentServer.settings.apiMqttPassword ?? '',
          );
          user.registredServers.editServer(editedServer);
          ServerStorage.saveServers(user.registredServers.servers);
          Navigator.pop(context);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const ServersPage(),
            ),
          );
        },
      ),
    );
    return;
  }

  void _onCancelButtonPressed() {
    selectedApiType = widget.currentServer.settings.apiType;
    _apiMqttClientIdController.text =
        widget.currentServer.settings.apiMqttClientId ?? '';
    _apiMqttUserController.text =
        widget.currentServer.settings.apiMqttUser ?? '';
    _apiMqttPasswordController.text =
        widget.currentServer.settings.apiMqttPassword ?? '';
    _apiMqttServerController.text =
        widget.currentServer.settings.apiMqttServer ?? '';
    _apiMqttPortController.text =
        widget.currentServer.settings.apiMqttPort != null
            ? widget.currentServer.settings.mqttPort.toString()
            : '';
    _apiMqttCassandraServerNameController.text =
        widget.currentServer.settings.apiMqttCassandraServerName ?? '';
  }

  Widget _getApiConnectionContent() {
    if (selectedApiType == ApiType.mqtt) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 1,
                child: SizedBox(
                  width: 100,
                  height: 50,
                  child: TextField(
                    controller: _apiMqttClientIdController,
                    decoration: InputDecoration(
                      label: Text(
                        'client id',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: SizedBox(
                  width: 100,
                  height: 50,
                  child: TextField(
                    controller: _apiMqttCassandraServerNameController,
                    decoration: InputDecoration(
                      label: Text(
                        'server name with prefix',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: SizedBox(
                  width: 100,
                  height: 50,
                  child: TextField(
                    controller: _apiMqttUserController,
                    decoration: InputDecoration(
                      label: Text(
                        'user',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: SizedBox(
                  width: 100,
                  height: 50,
                  child: TextField(
                    controller: _apiMqttPasswordController,
                    decoration: InputDecoration(
                      label: Text(
                        'password',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: SizedBox(
                  width: 100,
                  height: 50,
                  child: TextField(
                    controller: _apiMqttServerController,
                    decoration: InputDecoration(
                      label: Text(
                        'mqtt server',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: SizedBox(
                  width: 100,
                  height: 50,
                  child: TextField(
                    controller: _apiMqttPortController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      label: Text(
                        'port',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Api connection'),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  width: 130,
                  height: 50,
                  child: RadioListTile(
                    contentPadding: const EdgeInsets.all(0),
                    fillColor: WidgetStateProperty.resolveWith<Color>(
                      (states) {
                        return Theme.of(context).colorScheme.primary;
                      },
                    ),
                    title: Text(
                      'deactivated',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    value: ApiType.deactivated,
                    groupValue: selectedApiType,
                    onChanged: (ApiType? value) {
                      setState(() {
                        selectedApiType = value!;
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: 90,
                  height: 50,
                  child: RadioListTile(
                    contentPadding: const EdgeInsets.all(0),
                    fillColor: WidgetStateProperty.resolveWith<Color>(
                      (states) {
                        return Theme.of(context).colorScheme.primary;
                      },
                    ),
                    title: Text(
                      'mqtt',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    value: ApiType.mqtt,
                    groupValue: selectedApiType,
                    onChanged: (ApiType? value) {
                      setState(() {
                        selectedApiType = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            _getApiConnectionContent(),
            const SizedBox(
              height: 8,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CustomizedElevatedButton(
                  text: 'cancel',
                  onPressed: () {
                    _onCancelButtonPressed();
                    setState(() {});
                  },
                ),
                const SizedBox(
                  width: 8,
                ),
                CustomizedElevatedButton(
                    text: 'save',
                    onPressed: () {
                      _submitCommCfgData();
                    }),
                const SizedBox(
                  width: 8,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
