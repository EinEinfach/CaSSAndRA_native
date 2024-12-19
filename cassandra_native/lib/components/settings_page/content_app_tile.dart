import 'package:cassandra_native/utils/server_storage.dart';
import 'package:flutter/material.dart';

import 'package:cassandra_native/models/server.dart';
import 'package:cassandra_native/components/common/buttons/customized_elevated_button.dart';

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

  @override
  void initState() {
    _rtspUrlController.text = widget.currentServer.rtspUrl ?? '';
    super.initState();
  }

  @override
  void dispose() {
    _rtspUrlController.dispose();
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
      serverNamePrefix:
          widget.currentServer.serverNamePrefix,
      port: widget.currentServer.port,
      user: widget.currentServer.user,
      password: widget.currentServer.password,
      rtspUrl: widget.currentServer.rtspUrl,
    );
    user.registredServers.editServer(editedServer);
    ServerStorage.saveServers(user.registredServers.servers);
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
