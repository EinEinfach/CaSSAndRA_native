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
  // robot position mode
  late PositionMode selectedRobotPositionMode;
  final TextEditingController _robotLonController = TextEditingController();
  final TextEditingController _robotLatController = TextEditingController();

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
    _robotLonController.dispose();
    _robotLatController.dispose();
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
    selectedRobotPositionMode = widget.currentServer.settings.robotPositionMode;
    _robotLonController.text = widget.currentServer.settings.longtitude == null
        ? ''
        : widget.currentServer.settings.longtitude.toString();
    _robotLatController.text = widget.currentServer.settings.latitude == null
        ? ''
        : widget.currentServer.settings.latitude.toString();
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

    inputInvalid = false;

    widget.currentServer.settings.robotPositionMode = selectedRobotPositionMode;
    widget.currentServer.settings.longtitude =
        double.tryParse(_robotLonController.text);
    widget.currentServer.settings.latitude =
        double.tryParse(_robotLatController.text);

    if (selectedRobotPositionMode == PositionMode.absolute &&
        double.tryParse(_robotLonController.text) == null &&
        double.tryParse(_robotLatController.text) == null) {
      inputInvalid = true;
    }

    if (inputInvalid) {
      showDialog(
        context: context,
        builder: (context) => CustomizedDialogOk(
          title: 'Invalid input',
          content:
              'Please make sure valid values for position mode was entered',
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

    widget.currentServer.serverInterface.commandSetSettings(
        'setRover', widget.currentServer.settings.roverCfgToJson());

    // check if restart neccasary
    if (widget.currentServer.settings.robotConnectionType !=
            selectedRobotConnectionType ||
        widget.currentServer.settings.httpRobotIpAdress !=
            _robotIpAdressController.text ||
        widget.currentServer.settings.httpRobotPassword !=
            _robotPasswordController.text ||
        widget.currentServer.settings.mqttClientId !=
            _robotMqttClientIdController.text ||
        widget.currentServer.settings.mqttMowerNameWithPrefix !=
            _robotMqttMowerNameWithPrefixController.text ||
        widget.currentServer.settings.mqttServer !=
            _robotMqttServerController.text ||
        widget.currentServer.settings.mqttUser !=
            _robotMqttUserController.text ||
        widget.currentServer.settings.mqttPassword !=
            _robotMqttPasswordController.text ||
        widget.currentServer.settings.mqttPort !=
            int.tryParse(_robotMqttPortController.text) ||
        widget.currentServer.settings.uartPort !=
            _robotUartPortController.text ||
        widget.currentServer.settings.uartBaudrate !=
            int.tryParse(_robotUartBaudrateController.text)) {
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
      widget.currentServer.settings.mqttServer =
          _robotMqttServerController.text;
      widget.currentServer.settings.mqttUser = _robotMqttUserController.text;
      widget.currentServer.settings.mqttPassword =
          _robotMqttPasswordController.text;
      widget.currentServer.settings.mqttPort =
          int.tryParse(_robotMqttPortController.text);
      widget.currentServer.settings.uartPort = _robotUartPortController.text;
      widget.currentServer.settings.uartBaudrate =
          int.tryParse(_robotUartBaudrateController.text);
      widget.currentServer.serverInterface.commandSetSettings(
          'setComm', widget.currentServer.settings.commCfgToJson());

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
    }
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

  Widget _getRobotSettingsContent() {
    if (selectedRobotPositionMode == PositionMode.absolute) {
      return Row(
        children: [
          Expanded(
            flex: 1,
            child: SizedBox(
              height: 50,
              child: TextField(
                controller: _robotLonController,
                decoration: InputDecoration(
                  label: Text(
                    'lon',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: SizedBox(
              width: 150,
              height: 50,
              child: TextField(
                controller: _robotLatController,
                decoration: InputDecoration(
                  label: Text(
                    'lat',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ),
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
              height: 25,
            ),
            const Text('Position mode'),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  height: 50,
                  child: RadioListTile(
                    contentPadding: const EdgeInsets.all(0),
                    fillColor: WidgetStateProperty.resolveWith<Color>(
                      (states) {
                        return Theme.of(context).colorScheme.primary;
                      },
                    ),
                    title: Text(
                      'absolute',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    value: PositionMode.absolute,
                    groupValue: selectedRobotPositionMode,
                    onChanged: (PositionMode? value) {
                      setState(() {
                        selectedRobotPositionMode = value!;
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: 120,
                  height: 50,
                  child: RadioListTile(
                    contentPadding: const EdgeInsets.all(0),
                    fillColor: WidgetStateProperty.resolveWith<Color>(
                      (states) {
                        return Theme.of(context).colorScheme.primary;
                      },
                    ),
                    title: Text(
                      'relative',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    value: PositionMode.relative,
                    groupValue: selectedRobotPositionMode,
                    onChanged: (PositionMode? value) {
                      setState(() {
                        selectedRobotPositionMode = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            _getRobotSettingsContent(),
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
