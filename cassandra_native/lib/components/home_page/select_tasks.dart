import 'package:flutter/material.dart';
import 'package:multi_dropdown/multi_dropdown.dart';

import 'package:cassandra_native/components/customized_elevated_button.dart';
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
    for (var item in widget.server.tasks.available) {
      items.add(DropdownItem(label: item, value: item));
    }
    return SizedBox(
      width: double.infinity,
      height: 150,
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
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
                    borderRadius: BorderRadius.circular(12),
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
                  selectedIcon:
                      const Icon(Icons.check_box, color: Colors.green),
                  disabledIcon: Icon(Icons.lock, color: Colors.grey.shade300),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select at least one task';
                  }
                  return null;
                },
                onSelectionChange: (selectedItems) {
                  widget.server.serverInterface
                      .commandSelectTasks(selectedItems);
                },
              ),
              // const SizedBox(height: 12),
              // Wrap(
              //   spacing: 8,
              //   children: [
              //     ElevatedButton(
              //       onPressed: () {
              //         if (_formKey.currentState?.validate() ?? false) {
              //           final selectedItems = controller.selectedItems;

              //           debugPrint(selectedItems.toString());
              //         }
              //       },
              //       child: const Text('Submit'),
              //     ),
              //     ElevatedButton(
              //       onPressed: () {
              //         controller.selectAll();
              //       },
              //       child: const Text('Select All'),
              //     ),
              //     ElevatedButton(
              //       onPressed: () {
              //         controller.clearAll();
              //       },
              //       child: const Text('Unselect All'),
              //     ),
              //     ElevatedButton(
              //       onPressed: () {
              //         controller.addItems([
              //           DropdownItem(
              //               label: 'France',
              //               value: User(name: 'France', id: 8)),
              //         ]);
              //       },
              //       child: const Text('Add Items'),
              //     ),
              //     ElevatedButton(
              //       onPressed: () {
              //         controller.selectWhere((element) =>
              //             element.value.id == 1 ||
              //             element.value.id == 2 ||
              //             element.value.id == 3);
              //       },
              //       child: const Text('Select Where'),
              //     ),
              //     ElevatedButton(
              //       onPressed: () {
              //         controller.selectAtIndex(0);
              //       },
              //       child: const Text('Select At Index'),
              //     ),
              //     ElevatedButton(
              //       onPressed: () {
              //         controller.openDropdown();
              //       },
              //       child: const Text('Open/Close dropdown'),
              //     ),
              //   ],
              // )
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
