import 'package:flutter/material.dart';

import 'package:cassandra_native/models/server.dart';
import 'package:cassandra_native/components/customized_elevated_button.dart';

class NewServer extends StatefulWidget {
  const NewServer({super.key, required this.onAddServer});

  final void Function(Server server) onAddServer;

  @override
  State<NewServer> createState() => _NewServerState();
}

class _NewServerState extends State<NewServer> {
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
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
      child: Column(
        children: [
          TextField(
            controller: _serverNamePrefixController,
            decoration: const InputDecoration(label: Text('CaSSAndRA API name with prefix')),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _mqttServerController,
                  decoration: const InputDecoration(label: Text('MQTT-Server')),
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: TextField(
                  controller: _portController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(label: Text('Port')),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _userController,
                  decoration: const InputDecoration(label: Text('User')),
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(label: Text('Password')),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton(
              value: _selectedCategory,
              items: Category.values
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(
                        category.name.toUpperCase(),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              CustomizedElevatedButton(
                text: 'save',
                onPressed: _submitServerData,
              ),
              CustomizedElevatedButton(
                text: 'cancel',
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
