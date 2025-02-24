import 'package:flutter/material.dart';
import 'package:multiselect_dropdown_flutter/multiselect_dropdown_flutter.dart';

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
  String _doubleToTime(double time) {
    int hours = time.floor();
    int minutes = ((time - hours) * 60).round();
    String hoursStr = hours.toString().padLeft(2, '0');
    String minutesStr = minutes.toString().padLeft(2, '0');
    return '$hoursStr:$minutesStr';
  }

  @override
  Widget build(BuildContext context) {
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
        SizedBox(
          width: double.maxFinite,
          height: 45,
          child: widget.active
              ? MultiSelectDropdown.simpleList(
                  checkboxFillColor: Theme.of(context).colorScheme.onPrimary,
                  textStyle: Theme.of(context).textTheme.bodyMedium!,
                  boxDecoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  whenEmpty: 'select task',
                  numberOfItemsLabelToShow: 5,
                  list: widget.server.currentMap.tasks.available,
                  initiallySelected: widget.timeTableCopy[widget.day]['tasks'],
                  onChange: (selectedItems) {
                    widget.taskChanged(
                        widget.day, selectedItems.cast<String>());
                  })
              : Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
        ),
      ],
    );
  }
}
