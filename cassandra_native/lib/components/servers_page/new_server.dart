import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:cassandra_native/models/server.dart';
import 'package:cassandra_native/components/customized_elevated_button.dart';

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
  final _mqttServerController = TextEditingController();
  final _serverNamePrefixController = TextEditingController();
  final _portController = TextEditingController();
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();
  Category _selectedCategory = Category.alfred;

  void _submitServerData() {
    final enteredPort = int.tryParse(_portController.text);
    final enteredPortIsInvalid = enteredPort == null || enteredPort <= 0;
    if (_mqttServerController.text.trim().isEmpty ||
        _serverNamePrefixController.text.trim().isEmpty ||
        enteredPortIsInvalid) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Invalid input'),
          content: const Text(
              'Please make sure a valid MQTT server adress, port and client ID was entered'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('okay'),
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
          mqttServer: _mqttServerController.text,
          serverNamePrefix: _serverNamePrefixController.text,
          port: enteredPort,
          user: _userController.text,
          password: _passwordController.text),
    );
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _mqttServerController.dispose();
    _serverNamePrefixController.dispose();
    _portController.dispose();
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.server != null) {
      id = widget.server!.id;
      _mqttServerController.text = widget.server!.mqttServer;
      _serverNamePrefixController.text = widget.server!.serverNamePrefix;
      _portController.text = widget.server!.port.toString();
      _userController.text = widget.server!.user;
      _passwordController.text = widget.server!.password;
      _selectedCategory = widget.server!.category;
    } else {
      id = uuid.v4();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 290,
      child: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: _serverNamePrefixController,
              decoration: const InputDecoration(
                label: Text(
                  'CaSSAndRA API name with prefix',
                  style: TextStyle(fontSize: 10),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mqttServerController,
                    decoration: const InputDecoration(
                      label: Text(
                        'MQTT Server',
                        style: TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _portController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      label: Text(
                        'Port',
                        style: TextStyle(fontSize: 10),
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
                    decoration: const InputDecoration(
                      label: Text(
                        'User',
                        style: TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      label: Text(
                        'Password',
                        style: TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                )
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 10, 8, 5),
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
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
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
