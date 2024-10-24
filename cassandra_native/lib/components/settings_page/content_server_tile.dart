import 'package:flutter/material.dart';

import 'package:cassandra_native/models/server.dart';
import 'package:cassandra_native/models/server_settings.dart';
import 'package:cassandra_native/components/customized_elevated_button.dart';
import 'package:cassandra_native/components/customized_dialog_ok.dart';
import 'package:cassandra_native/components/customized_dialog_ok_cancel.dart';

class ContentServerTile extends StatefulWidget {
  final Server currentServer;

  const ContentServerTile({
    super.key,
    required this.currentServer,
  });

  @override
  State<ContentServerTile> createState() => _ContentServerTileState();
}

class _ContentServerTileState extends State<ContentServerTile> {
  // robot connection type
  late ConnectionType selectedRobotConnectionType;
  // http
  final TextEditingController _robotIpAdressController =
      TextEditingController();
  final TextEditingController _robotPasswordController =
      TextEditingController();
  // mqtt
  final TextEditingController _robotMqttClientIdController =
      TextEditingController();
  final TextEditingController _robotMqttUserController =
      TextEditingController();
  final TextEditingController _robotMqttPasswordController =
      TextEditingController();
  final TextEditingController _robotMqttServerController =
      TextEditingController();
  final TextEditingController _robotMqttPortController =
      TextEditingController();
  final TextEditingController _robotMqttMowerNameWithPrefixController =
      TextEditingController();
  final TextEditingController _robotUartPortController =
      TextEditingController();
  final TextEditingController _robotUartBaudrateController =
      TextEditingController();

  @override
  void dispose() {
    _robotIpAdressController.dispose();
    _robotPasswordController.dispose();
    _robotMqttClientIdController.dispose();
    _robotMqttUserController.dispose();
    _robotMqttPasswordController.dispose();
    _robotMqttServerController.dispose();
    _robotMqttPortController.dispose();
    _robotMqttMowerNameWithPrefixController.dispose();
    _robotUartPortController.dispose();
    _robotUartBaudrateController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    selectedRobotConnectionType =
        widget.currentServer.settings.robotConnectionType;
    _robotIpAdressController.text =
        widget.currentServer.settings.httpRobotIpAdress ?? '';
    _robotPasswordController.text =
        widget.currentServer.settings.httpRobotPassword ?? '';
    _robotMqttClientIdController.text =
        widget.currentServer.settings.mqttClientId ?? '';
    _robotMqttUserController.text =
        widget.currentServer.settings.mqttUser ?? '';
    _robotMqttPasswordController.text =
        widget.currentServer.settings.mqttPassword ?? '';
    _robotMqttServerController.text =
        widget.currentServer.settings.mqttServer ?? '';
    _robotMqttMowerNameWithPrefixController.text =
        widget.currentServer.settings.mqttMowerNameWithPrefix ?? '';
    _robotMqttPortController.text =
        widget.currentServer.settings.mqttPort != null
            ? widget.currentServer.settings.mqttPort.toString()
            : '';
    _robotUartPortController.text =
        widget.currentServer.settings.uartPort ?? '';
    _robotUartBaudrateController.text =
        widget.currentServer.settings.uartBaudrate != null
            ? widget.currentServer.settings.uartBaudrate.toString()
            : '';

    super.initState();
  }

  void _submitCommCfgData() {
    final enteredMqttPort = int.tryParse(_robotMqttPortController.text);
    final enteredUartBaudrate = int.tryParse(_robotUartBaudrateController.text);

    bool inputInvalid = false;

    if (selectedRobotConnectionType == ConnectionType.http) {
      inputInvalid = _robotIpAdressController.text.isEmpty;
    } else if (selectedRobotConnectionType == ConnectionType.mqtt) {
      inputInvalid = _robotMqttClientIdController.text.isEmpty ||
          _robotMqttMowerNameWithPrefixController.text.isEmpty ||
          _robotMqttServerController.text.isEmpty ||
          enteredMqttPort == null;
    } else if (selectedRobotConnectionType == ConnectionType.uart) {
      inputInvalid =
          _robotUartPortController.text.isEmpty || enteredUartBaudrate == null;
    }

    if (inputInvalid) {
      showDialog(
        context: context,
        builder: (context) => CustomizedDialogOk(
          title: 'Invalid input',
          content:
              'Please make sure valid values for robot communication was entered',
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

    widget.currentServer.settings.robotConnectionType =
        selectedRobotConnectionType;
    widget.currentServer.settings.httpRobotIpAdress =
        _robotIpAdressController.text;
    widget.currentServer.settings.httpRobotPassword =
        _robotPasswordController.text;
    widget.currentServer.settings.mqttClientId =
        _robotMqttClientIdController.text;
    widget.currentServer.settings.mqttMowerNameWithPrefix =
        _robotMqttMowerNameWithPrefixController.text;
    widget.currentServer.settings.mqttServer = _robotMqttServerController.text;
    widget.currentServer.settings.mqttUser = _robotMqttUserController.text;
    widget.currentServer.settings.mqttPassword =
        _robotMqttPasswordController.text;
    widget.currentServer.settings.mqttPort =
        int.tryParse(_robotMqttPortController.text);
    widget.currentServer.settings.uartPort = _robotUartPortController.text;
    widget.currentServer.settings.uartBaudrate =
        int.tryParse(_robotUartBaudrateController.text);
    widget.currentServer.serverInterface
        .commandSetSettings('setComm', widget.currentServer.settings.toJson());

    showDialog(
      context: context,
      builder: (context) => CustomizedDialogOkCancel(
        title: 'Server restart is neccessary',
        content:
            'Press ok to restart the server now, or cancel to perform the restart later yourself',
        onCancelPressed: () {
          Navigator.pop(context);
        },
        onOkPressed: () {
          widget.currentServer.serverInterface.commandRestartServer();
          Navigator.pop(context);
        },
      ),
    );
    return;
  }

  void _onCancelButtonPressed() {
    selectedRobotConnectionType =
        widget.currentServer.settings.robotConnectionType;
    _robotIpAdressController.text =
        widget.currentServer.settings.httpRobotIpAdress ?? '';
    _robotPasswordController.text =
        widget.currentServer.settings.httpRobotPassword ?? '';
    _robotMqttClientIdController.text =
        widget.currentServer.settings.mqttClientId ?? '';
    _robotMqttUserController.text =
        widget.currentServer.settings.mqttUser ?? '';
    _robotMqttPasswordController.text =
        widget.currentServer.settings.mqttPassword ?? '';
    _robotMqttServerController.text =
        widget.currentServer.settings.mqttServer ?? '';
    _robotMqttPortController.text =
        widget.currentServer.settings.mqttPort != null
            ? widget.currentServer.settings.mqttPort.toString()
            : '';
    _robotUartPortController.text =
        widget.currentServer.settings.uartPort ?? '';
    _robotUartBaudrateController.text =
        widget.currentServer.settings.uartBaudrate != null
            ? widget.currentServer.settings.uartBaudrate.toString()
            : '';
  }

  Widget _getRobotConnectionContent() {
    // http
    if (selectedRobotConnectionType == ConnectionType.http) {
      return Row(
        children: [
          Expanded(
            child: SizedBox(
              width: 150,
              height: 50,
              child: TextField(
                controller: _robotIpAdressController,
                decoration: InputDecoration(
                  // hintText: 'robot ip-adress in "http://xxxxxx" style',
                  // hintStyle: Theme.of(context).textTheme.bodyMedium,
                  label: Text(
                    'robot ip-adress',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 150,
            height: 50,
            child: TextField(
              controller: _robotPasswordController,
              decoration: InputDecoration(
                // hintText: 'robot ip-adress in "http://xxxxxx" style',
                // hintStyle: Theme.of(context).textTheme.bodyMedium,
                label: Text(
                  'password',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ),
        ],
      );
      // mqtt
    } else if (selectedRobotConnectionType == ConnectionType.mqtt) {
      return Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 150,
                height: 50,
                child: TextField(
                  controller: _robotMqttClientIdController,
                  decoration: InputDecoration(
                    label: Text(
                      'client id',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SizedBox(
                  width: 150,
                  height: 50,
                  child: TextField(
                    controller: _robotMqttMowerNameWithPrefixController,
                    decoration: InputDecoration(
                      label: Text(
                        'mower name with prefix',
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
              SizedBox(
                width: 150,
                height: 50,
                child: TextField(
                  controller: _robotMqttUserController,
                  decoration: InputDecoration(
                    label: Text(
                      'user',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SizedBox(
                  width: 150,
                  height: 50,
                  child: TextField(
                    controller: _robotMqttPasswordController,
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
                child: SizedBox(
                  width: 150,
                  height: 50,
                  child: TextField(
                    controller: _robotMqttServerController,
                    decoration: InputDecoration(
                      label: Text(
                        'mqtt server',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 150,
                height: 50,
                child: TextField(
                  controller: _robotMqttPortController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    label: Text(
                      'port',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
      // uart
    } else {
      return Row(
        children: [
          Expanded(
            child: SizedBox(
              width: 150,
              height: 50,
              child: TextField(
                controller: _robotUartPortController,
                decoration: InputDecoration(
                  label: Text(
                    'serial port',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 150,
            height: 50,
            child: TextField(
              controller: _robotUartBaudrateController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                label: Text(
                  'baudrate',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ),
        ],
      );
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
            const Text('Rover connection'),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
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
                      'http',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    value: ConnectionType.http,
                    groupValue: selectedRobotConnectionType,
                    onChanged: (ConnectionType? value) {
                      setState(() {
                        selectedRobotConnectionType = value!;
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
                    value: ConnectionType.mqtt,
                    groupValue: selectedRobotConnectionType,
                    onChanged: (ConnectionType? value) {
                      setState(() {
                        selectedRobotConnectionType = value!;
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
                      'uart',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    value: ConnectionType.uart,
                    groupValue: selectedRobotConnectionType,
                    onChanged: (ConnectionType? value) {
                      setState(() {
                        selectedRobotConnectionType = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            _getRobotConnectionContent(),
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
