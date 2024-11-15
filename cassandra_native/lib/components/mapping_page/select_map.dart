import 'package:flutter/material.dart';
import 'package:multi_dropdown/multi_dropdown.dart';

import 'package:cassandra_native/components/common/customized_elevated_button.dart';
import 'package:cassandra_native/models/server.dart';

class SelectMap extends StatefulWidget {
  final Server server;
  const SelectMap({super.key, required this.server});

  @override
  State<SelectMap> createState() => _SelectMapState();
}

class _SelectMapState extends State<SelectMap> {
  final _formKey = GlobalKey<FormState>();
  final controller = MultiSelectController<String>();

  @override
  Widget build(BuildContext context) {
    List<DropdownItem<String>> items = [];
    for (var item in widget.server.maps.available) {
      if (item == widget.server.maps.selected) {
        items.add(DropdownItem(label: item, value: item, selected: true));
      } else {
        items.add(DropdownItem(label: item, value: item));
      }
    }
    return SizedBox(
      width: 300,
      height: 130,
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
                singleSelect: true,
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
                  widget.server.maps.selected = selectedItems.isEmpty ? '' : selectedItems[0];
                  widget.server.serverInterface.commandSelectMap(selectedItems);
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
                        // widget.server.serverInterface.commandSelectMap([]);
                        Navigator.pop(context);
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
