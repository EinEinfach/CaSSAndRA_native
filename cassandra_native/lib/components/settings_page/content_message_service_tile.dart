import 'package:flutter/material.dart';

import 'package:cassandra_native/models/server.dart';
import 'package:cassandra_native/models/server_settings.dart';
import 'package:cassandra_native/components/common/customized_elevated_button.dart';
import 'package:cassandra_native/components/common/customized_dialog_ok.dart';
import 'package:cassandra_native/components/common/customized_dialog_ok_cancel.dart';

class ContentMessageServiceTile extends StatefulWidget {
  final Server currentServer;
  const ContentMessageServiceTile({
    super.key,
    required this.currentServer,
  });

  @override
  State<ContentMessageServiceTile> createState() =>
      _ContentMessageServiceTileState();
}

class _ContentMessageServiceTileState extends State<ContentMessageServiceTile> {
  // message service type
  late MessageServiceType selectedMessageServiceType;
  // telegram
  final TextEditingController _telegramApiTokenController =
      TextEditingController();
  final TextEditingController _telegramChatIdController =
      TextEditingController();
  // pushover
  final TextEditingController _pushoverApiTokenController =
      TextEditingController();
  final TextEditingController _pushoverAppNameController =
      TextEditingController();

  final TextEditingController _testMessageController = TextEditingController();

  @override
  void dispose() {
    _telegramApiTokenController.dispose();
    _telegramChatIdController.dispose();
    _pushoverApiTokenController.dispose();
    _pushoverAppNameController.dispose();
    _testMessageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    selectedMessageServiceType =
        widget.currentServer.settings.messageServiceType;
    _telegramApiTokenController.text =
        widget.currentServer.settings.telegramApiToken ?? '';
    _telegramChatIdController.text =
        widget.currentServer.settings.telegramChatId ?? '';
    _pushoverApiTokenController.text =
        widget.currentServer.settings.pushoverApiToken ?? '';
    _pushoverAppNameController.text =
        widget.currentServer.settings.pushoverAppName ?? '';
    _testMessageController.text = '';
    super.initState();
  }

  void _submitCommCfgData() {
    bool inputInvalid = false;

    if (selectedMessageServiceType == MessageServiceType.telegram) {
      inputInvalid = _telegramApiTokenController.text.isEmpty;
    } else if (selectedMessageServiceType == MessageServiceType.pushover) {
      inputInvalid = _pushoverApiTokenController.text.isEmpty ||
          _pushoverAppNameController.text.isEmpty;
    }

    if (inputInvalid) {
      showDialog(
        context: context,
        builder: (context) => CustomizedDialogOk(
          title: 'Invalid input',
          content:
              'Please make sure valid values for message service was entered',
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

    widget.currentServer.settings.messageServiceType =
        selectedMessageServiceType;
    widget.currentServer.settings.telegramApiToken =
        _telegramApiTokenController.text;
    widget.currentServer.settings.telegramChatId =
        _telegramChatIdController.text;
    widget.currentServer.settings.pushoverApiToken =
        _pushoverApiTokenController.text;
    widget.currentServer.settings.pushoverAppName =
        _pushoverAppNameController.text;
    widget.currentServer.serverInterface
        .commandSetSettings('setComm', widget.currentServer.settings.commCfgToJson());

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
    selectedMessageServiceType =
        widget.currentServer.settings.messageServiceType;
    _telegramApiTokenController.text =
        widget.currentServer.settings.telegramApiToken ?? '';
    _telegramChatIdController.text =
        widget.currentServer.settings.telegramChatId ?? '';
    _pushoverApiTokenController.text =
        widget.currentServer.settings.pushoverApiToken ?? '';
    _pushoverAppNameController.text =
        widget.currentServer.settings.pushoverAppName ?? '';
  }

  void _onTestMessageSend() {
    widget.currentServer.serverInterface
        .commandSendMessage(_testMessageController.text);
    _testMessageController.text = '';
  }

  Widget _getMessageBox() {
    return Column(
      children: [
        const SizedBox(
          height: 8,
        ),
        Container(
          padding: const EdgeInsets.all(8),
          child: const Align(
            alignment: Alignment.centerLeft,
            child: Text('test message'),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: Theme.of(context).colorScheme.primary),
                ),
                height: 80,
                child: TextField(
                  style: Theme.of(context).textTheme.bodyMedium,
                  controller: _testMessageController,
                  maxLines: null,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            IconButton(
              color: Theme.of(context).colorScheme.primary,
              onPressed: () {
                _onTestMessageSend();
              },
              icon: Icon(
                size: 35,
                Icons.send_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _getMessageServiceContent() {
    if (selectedMessageServiceType == MessageServiceType.telegram) {
      return Column(
        children: [
          SizedBox(
            height: 50,
            child: TextField(
              controller: _telegramApiTokenController,
              decoration: InputDecoration(
                label: Text(
                  'API token',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 50,
            child: TextField(
              controller: _telegramChatIdController,
              decoration: InputDecoration(
                label: Text(
                  'chat ID',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ),
          _getMessageBox(),
        ],
      );
    } else if (selectedMessageServiceType == MessageServiceType.pushover) {
      return Column(
        children: [
          SizedBox(
            height: 50,
            child: TextField(
              controller: _pushoverApiTokenController,
              decoration: InputDecoration(
                label: Text(
                  'API token',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 50,
            child: TextField(
              controller: _pushoverAppNameController,
              decoration: InputDecoration(
                label: Text(
                  'app name',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ),
          _getMessageBox(),
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
            const Text('Message service connection type'),
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
                      'deactivated',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    value: MessageServiceType.deactivated,
                    groupValue: selectedMessageServiceType,
                    onChanged: (MessageServiceType? value) {
                      setState(() {
                        selectedMessageServiceType = value!;
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: 110,
                  height: 50,
                  child: RadioListTile(
                    contentPadding: const EdgeInsets.all(0),
                    fillColor: WidgetStateProperty.resolveWith<Color>(
                      (states) {
                        return Theme.of(context).colorScheme.primary;
                      },
                    ),
                    title: Text(
                      'telegram',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    value: MessageServiceType.telegram,
                    groupValue: selectedMessageServiceType,
                    onChanged: (MessageServiceType? value) {
                      setState(() {
                        selectedMessageServiceType = value!;
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: 110,
                  height: 50,
                  child: RadioListTile(
                    contentPadding: const EdgeInsets.all(0),
                    fillColor: WidgetStateProperty.resolveWith<Color>(
                      (states) {
                        return Theme.of(context).colorScheme.primary;
                      },
                    ),
                    title: Text(
                      'pushover',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    value: MessageServiceType.pushover,
                    groupValue: selectedMessageServiceType,
                    onChanged: (MessageServiceType? value) {
                      setState(() {
                        selectedMessageServiceType = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            _getMessageServiceContent(),
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
