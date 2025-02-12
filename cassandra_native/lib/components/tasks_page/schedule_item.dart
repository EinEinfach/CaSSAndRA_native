import 'package:flutter/material.dart';
import 'package:multi_dropdown/multi_dropdown.dart';

import 'package:cassandra_native/models/server.dart';

class ScheduleItem extends StatefulWidget {
  final bool active;
  final String day;
  final Server server;
  final Map<String, dynamic> timeTableCopy;
  final void Function(String, double, double) timeRangeChaged;
  final void Function(String, List<String>) taskChanged;

  const ScheduleItem({
    super.key,
    required this.active,
    required this.day,
    required this.server,
    required this.timeTableCopy,
    required this.timeRangeChaged,
    required this.taskChanged,
  });

  @override
  State<ScheduleItem> createState() => _ScheduleItemState();
}

class _ScheduleItemState extends State<ScheduleItem> {
  final controller = MultiSelectController<String>();

  String _doubleToTime(double time) {
    int hours = time.floor();
    int minutes = ((time - hours) * 60).round();
    String hoursStr = hours.toString().padLeft(2, '0');
    String minutesStr = minutes.toString().padLeft(2, '0');
    return '$hoursStr:$minutesStr';
  }

  @override
  Widget build(BuildContext context) {
    List<DropdownItem<String>> items = [];
    for (var item in widget.server.currentMap.tasks.available) {
      if (widget.timeTableCopy[widget.day]['tasks'].contains(item)) {
        items.add(DropdownItem(label: item, value: item, selected: true));
      } else {
        items.add(DropdownItem(label: item, value: item));
      }
    }
    RangeLabels rangeLabels = RangeLabels(
        _doubleToTime(
            widget.timeTableCopy[widget.day]['timeRange'][0].toDouble()),
        _doubleToTime(
            widget.timeTableCopy[widget.day]['timeRange'][1].toDouble()));
    return Column(
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(30, 8, 30, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '     ',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                '     ',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                '06:00',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                '09:00',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                '12:00',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                '15:00',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                '18:00',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                '     ',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                '     ',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        RangeSlider(
          values: RangeValues(
              widget.timeTableCopy[widget.day]['timeRange'][0].toDouble(),
              widget.timeTableCopy[widget.day]['timeRange'][1].toDouble()),
          labels: rangeLabels,
          min: 0,
          max: 24,
          divisions: 48,
          onChanged: widget.active
              ? (RangeValues newValues) {
                  widget.timeRangeChaged(
                      widget.day, newValues.start, newValues.end);
                }
              : null,
        ),
        MultiDropdown<String>(
          items: items,
          controller: controller,
          enabled: widget.active,
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
              borderSide:
                  BorderSide(color: Theme.of(context).colorScheme.primary),
            ),
          ),
          dropdownDecoration: DropdownDecoration(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            marginTop: 2,
            maxHeight: 300,
          ),
          dropdownItemDecoration: DropdownItemDecoration(
            selectedBackgroundColor: Theme.of(context).colorScheme.primary,
            //selectedIcon: null,
          ),
          onSelectionChange: (selectedItems) {
            widget.taskChanged(widget.day, selectedItems);
          },
        ),
      ],
    );
  }
}
