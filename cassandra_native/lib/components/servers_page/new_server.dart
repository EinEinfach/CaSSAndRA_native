import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:cassandra_native/models/server.dart';
import 'package:cassandra_native/components/common/buttons/customized_elevated_button.dart';

const uuid = Uuid();

class NewServer extends StatefulWidget {
  final Server? server;
  const NewServer({super.key, required this.onAddServer, this.server});

  final void Function(Server server) onAddServer;

  @override
  State<NewServer> createState() => _NewServerState();
}

class _NewServerState extends State<NewServer> {
  String id = "";
  final _aliasController = TextEditingController();
  final _mqttServerController = TextEditingController();
  final _serverNamePrefixController = TextEditingController();
  final _portController = TextEditingController();
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _rtspUrl;
  //final _rtspUrlController = TextEditingController();
  Category _selectedCategory = Category.alfred;

  void _submitServerData() {
    final enteredPort = int.tryParse(_portController.text);
    final enteredPortIsInvalid = enteredPort == null || enteredPort <= 0;
    if (_aliasController.text.trim().isEmpty ||
        _mqttServerController.text.trim().isEmpty ||
        _serverNamePrefixController.text.trim().isEmpty ||
        enteredPortIsInvalid) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          title: const Text(
            'Invalid input',
            style: TextStyle(fontSize: 14),
          ),
          content: const Text(
              'Please make sure a valid MQTT server adress, port and client ID was entered'),
          actions: [
            CustomizedElevatedButton(
              text: 'ok',
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      );
      return;
    }
    widget.onAddServer(
      Server(
        id: id,
        category: _selectedCategory,
        alias: _aliasController.text,
        mqttServer: _mqttServerController.text,
        serverNamePrefix: _serverNamePrefixController.text,
        port: enteredPort,
        user: _userController.text,
        password: _passwordController.text,
        rtspUrl: _rtspUrl,
        // rtspUrl:
        //     _rtspUrlController.text.isEmpty ? null : _rtspUrlController.text,
      ),
    );
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _aliasController.dispose();
    _mqttServerController.dispose();
    _serverNamePrefixController.dispose();
    _portController.dispose();
    _userController.dispose();
    _passwordController.dispose();
    // _rtspUrlController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.server != null) {
      id = widget.server!.id;
      _aliasController.text = widget.server!.alias;
      _mqttServerController.text = widget.server!.mqttServer;
      _serverNamePrefixController.text = widget.server!.serverNamePrefix;
      _portController.text = widget.server!.port.toString();
      _userController.text = widget.server!.user;
      _passwordController.text = widget.server!.password;
      _selectedCategory = widget.server!.category;
      _rtspUrl = widget.server!.rtspUrl;
      // _rtspUrlController.text = widget.server!.rtspUrl ?? '';
    } else {
      id = uuid.v4();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _aliasController,
              decoration: InputDecoration(
                label: Text(
                  'Alias',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            TextField(
              controller: _serverNamePrefixController,
              decoration: InputDecoration(
                label: Text(
                  'CaSSAndRA API name with prefix',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mqttServerController,
                    decoration: InputDecoration(
                      label: Text(
                        'MQTT Server',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _portController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      label: Text(
                        'Port',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                )
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _userController,
                    decoration: InputDecoration(
                      label: Text(
                        'User',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _passwordController,
                    keyboardType: TextInputType.visiblePassword,
                    decoration: InputDecoration(
                      label: Text(
                        'Password',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                )
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 10, 8, 0),
              child: DropdownButtonHideUnderline(
                child: DropdownButton(
                  isExpanded: true,
                  dropdownColor: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(8),
                  value: _selectedCategory,
                  items: Category.values
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Center(
                            child: Text(
                              category.name.toUpperCase(),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                ),
              ),
            ),
            // TextField(
            //   controller: _rtspUrlController,
            //   decoration: InputDecoration(
            //     label: Text(
            //       'stream url',
            //       style: Theme.of(context).textTheme.bodyMedium,
            //     ),
            //   ),
            // ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CustomizedElevatedButton(
                    text: 'cancel',
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  CustomizedElevatedButton(
                      text: 'save', onPressed: _submitServerData),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
