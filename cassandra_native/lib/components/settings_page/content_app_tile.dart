import 'package:cassandra_native/utils/server_storage.dart';
import 'package:flutter/material.dart';

import 'package:cassandra_native/models/server.dart';
import 'package:cassandra_native/components/common/buttons/customized_elevated_button.dart';
import 'package:cassandra_native/components/common/dialogs/customized_dialog_ok.dart';

// globals
import 'package:cassandra_native/data/user_data.dart' as user;

class ContentAppTile extends StatefulWidget {
  final Server currentServer;
  const ContentAppTile({
    super.key,
    required this.currentServer,
  });

  @override
  State<ContentAppTile> createState() => _ContentAppTileState();
}

class _ContentAppTileState extends State<ContentAppTile> {
  final TextEditingController _rtspUrlController = TextEditingController();
  final TextEditingController _minPercentController = TextEditingController();
  final TextEditingController _maxPercentController = TextEditingController();
  final TextEditingController _chargeCurrentThdController = TextEditingController();
  final TextEditingController _dataMaxAgeController = TextEditingController();
  final TextEditingController _offlineTimeoutController = TextEditingController();

  @override
  void initState() {
    _rtspUrlController.text = widget.currentServer.rtspUrl ?? '';
    _minPercentController.text = widget.currentServer.settings.minVoltage?.toString() ?? '';
    _maxPercentController.text = widget.currentServer.settings.maxVoltage?.toString() ?? '';
    _chargeCurrentThdController.text = widget.currentServer.settings.chargeCurrentThd?.toString() ?? '';
    _dataMaxAgeController.text = widget.currentServer.settings.dataMaxAge?.toString() ?? '';
    _offlineTimeoutController.text = widget.currentServer.settings.offlineTimeout?.toString() ?? '';
    super.initState();
  }

  @override
  void dispose() {
    _rtspUrlController.dispose();
    _minPercentController.dispose();
    _maxPercentController.dispose();
    _chargeCurrentThdController.dispose();
    _dataMaxAgeController.dispose();
    _offlineTimeoutController.dispose();
    super.dispose();
  }

  void _submitCommCfgData() {
    widget.currentServer.rtspUrl =
        _rtspUrlController.text.isEmpty ? null : _rtspUrlController.text;
    final Server editedServer = Server(
      id: widget.currentServer.id,
      category: widget.currentServer.category,
      alias: widget.currentServer.alias,
      mqttServer: widget.currentServer.mqttServer,
      serverNamePrefix: widget.currentServer.serverNamePrefix,
      port: widget.currentServer.port,
      user: widget.currentServer.user,
      password: widget.currentServer.password,
      rtspUrl: widget.currentServer.rtspUrl,
    );
    user.registredServers.editServer(editedServer);
    ServerStorage.saveServers(user.registredServers.servers);

    bool inputInvalid = false;

    double? minVoltage = double.tryParse(_minPercentController.text);
    double? maxVoltage = double.tryParse(_maxPercentController.text);
    double? chargeCurrentThd = double.tryParse(_chargeCurrentThdController.text);
    int? dataMaxAge = int.tryParse(_dataMaxAgeController.text);
    int? offlineTimeout = int.tryParse(_offlineTimeoutController.text);

    inputInvalid = minVoltage == null || maxVoltage == null || chargeCurrentThd == null ||
        maxVoltage <= minVoltage || dataMaxAge == null || offlineTimeout == null;
    if (inputInvalid) {
      showDialog(
        context: context,
        builder: (context) => CustomizedDialogOk(
          title: 'Invalid input',
          content:
              'Please make sure valid values was entered',
          onOkPressed: () {
            Navigator.pop(context);
          },
        ),
      );
      return;
    } else {
      widget.currentServer.settings.minVoltage = minVoltage;
      widget.currentServer.settings.maxVoltage = maxVoltage;
      widget.currentServer.settings.chargeCurrentThd = chargeCurrentThd;
      widget.currentServer.settings.dataMaxAge = dataMaxAge;
      widget.currentServer.settings.offlineTimeout = offlineTimeout;
      widget.currentServer.serverInterface.commandSetSettings(
        'setApp', widget.currentServer.settings.appCfgToJson());
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
            TextField(
              controller: _rtspUrlController,
              decoration: InputDecoration(
                label: Text(
                  'url RTSP stream',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    width: 100,
                    height: 50,
                    child: TextField(
                      controller: _minPercentController,
                      decoration: InputDecoration(
                        label: Text(
                          '0% voltage [V]',
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
                      controller: _maxPercentController,
                      decoration: InputDecoration(
                        label: Text(
                          '100% voltage [V]',
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
                      controller: _chargeCurrentThdController,
                      decoration: InputDecoration(
                        label: Text(
                          'charge current thd [A]',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 8,
            ),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    width: 100,
                    height: 50,
                    child: TextField(
                      controller: _dataMaxAgeController,
                      decoration: InputDecoration(
                        label: Text(
                          'data max age [days]',
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
                      controller: _offlineTimeoutController,
                      decoration: InputDecoration(
                        label: Text(
                          'offline timeout [s]',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 8,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CustomizedElevatedButton(
                  text: 'cancel',
                  onPressed: () {
                    // _onCancelButtonPressed();
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
