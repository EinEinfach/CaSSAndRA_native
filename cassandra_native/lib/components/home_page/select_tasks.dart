import 'package:flutter/material.dart';
import 'package:multi_dropdown/multi_dropdown.dart';

import 'package:cassandra_native/components/common/customized_elevated_button.dart';
import 'package:cassandra_native/models/server.dart';

class SelectTasks extends StatefulWidget {
  final Server server;
  const SelectTasks({super.key, required this.server});

  @override
  State<SelectTasks> createState() => _SelectTasksState();
}

class _SelectTasksState extends State<SelectTasks> {
  final _formKey = GlobalKey<FormState>();
  final controller = MultiSelectController<String>();

  @override
  Widget build(BuildContext context) {
    List<DropdownItem<String>> items = [];
    for (var item in widget.server.currentMap.tasks.available) {
      if (widget.server.currentMap.tasks.selected.contains(item)) {
        items.add(DropdownItem(label: item, value: item, selected: true));
      }
      else {
        items.add(DropdownItem(label: item, value: item));
      }
    }
    return SizedBox(
      width: 300,
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 4,
              ),
              MultiDropdown<String>(
                items: items,
                controller: controller,
                enabled: true,
                searchEnabled: false, 
                // searchDecoration: SearchFieldDecoration(
                //   border: OutlineInputBorder(
                //     borderRadius: BorderRadius.circular(8),
                //     borderSide: BorderSide(
                //         color: Theme.of(context).colorScheme.primary),
                //   ),
                //   focusedBorder: OutlineInputBorder(
                //     borderRadius: BorderRadius.circular(8),
                //     borderSide: BorderSide(
                //         color: Theme.of(context).colorScheme.primary),
                //   ),
                // ),
                chipDecoration: ChipDecoration(
                  borderRadius: BorderRadius.circular(6),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  wrap: true,
                  runSpacing: 2,
                  spacing: 2,
                ),
                fieldDecoration: FieldDecoration(
                  hintText: 'No selection',
                  hintStyle: Theme.of(context).textTheme.bodyMedium,
                  showClearIcon: false,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary),
                  ),
                ),
                dropdownDecoration: DropdownDecoration(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  marginTop: 2,
                  maxHeight: 300,
                ),
                dropdownItemDecoration: DropdownItemDecoration(
                  selectedBackgroundColor:
                      Theme.of(context).colorScheme.primary,
                  //selectedIcon: null,
                ),
                onSelectionChange: (selectedItems) {
                  widget.server.serverInterface
                      .commandSelectTasks(selectedItems);
                  widget.server.serverInterface.commandResetRoute();
                  widget.server.currentMap.resetPreviewCoords();
                  widget.server.currentMap.resetMowPathCoords();
                },
              ),
              const SizedBox(height: 5),
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomizedElevatedButton(
                      text: 'cancel',
                      onPressed: () {
                        Navigator.pop(context);
                        widget.server.serverInterface.commandSelectTasks([]);
                      },
                    ),
                    const SizedBox(
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
