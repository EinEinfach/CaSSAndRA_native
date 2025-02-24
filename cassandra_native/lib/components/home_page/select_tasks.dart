import 'package:flutter/material.dart';

import 'package:cassandra_native/models/server.dart';
import 'package:multiselect_dropdown_flutter/multiselect_dropdown_flutter.dart';
import 'package:cassandra_native/components/common/buttons/customized_elevated_button.dart';

class SelectTasks extends StatelessWidget {
  final Server server;
  final void Function(List<String> selectedTasks) onSelectionChange;
  const SelectTasks(
      {super.key, required this.server, required this.onSelectionChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      width: 300,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MultiSelectDropdown.simpleList(
            checkboxFillColor: Theme.of(context).colorScheme.onPrimary,
            textStyle: Theme.of(context).textTheme.bodyMedium!,
            boxDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            list: server.currentMap.tasks.available,
            initiallySelected: server.currentMap.tasks.selected,
            onChange: (newList) {
              onSelectionChange(newList.cast<String>());
            },
            numberOfItemsLabelToShow: 5,
            whenEmpty: 'select task',
          ),
          SizedBox(
            height: 8,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CustomizedElevatedButton(
                text: 'cancel',
                onPressed: () {
                  Navigator.of(context).pop();
                  server.serverInterface.commandSelectTasks([]);
                },
              ),
              SizedBox(
                width: 10,
              ),
              CustomizedElevatedButton(
                text: 'ok',
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
