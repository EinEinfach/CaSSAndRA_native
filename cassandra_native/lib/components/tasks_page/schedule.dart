import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:cassandra_native/models/server.dart';
import 'package:cassandra_native/components/common/buttons/customized_elevated_button.dart';
import 'package:cassandra_native/components/tasks_page/schedule_item.dart';

class Schedule extends StatefulWidget {
  final Server server;
  const Schedule({
    super.key,
    required this.server,
  });

  @override
  State<Schedule> createState() => _ScheduleState();
}

class _ScheduleState extends State<Schedule> {
  late bool userChangesScheduleActive;
  late Map<String, dynamic> userChangesTimeTable;

  @override
  void initState() {
    userChangesScheduleActive = widget.server.currentMap.schedule.active;
    userChangesTimeTable =
        _deepCopy(widget.server.currentMap.schedule.timeTable);
    super.initState();
  }

  void _timeRangeChanged(String day, double start, double end) {
    userChangesTimeTable[day]['timeRange'] = [start, end];
    setState(() {});
  }

  void _taskChanged(String day, List<String> tasks) {
    userChangesTimeTable[day]['tasks'] = tasks;
    setState(() {});
  }

  Map<String, dynamic> _createScheduleData() {
    Map<String, dynamic> scheduleData = {};
    scheduleData['scheduleActive'] = userChangesScheduleActive;
    scheduleData['timeRange'] = [];
    scheduleData['timeRange']
        .add({'monday': userChangesTimeTable['monday']['timeRange']});
    scheduleData['timeRange']
        .add({'tuesday': userChangesTimeTable['tuesday']['timeRange']});
    scheduleData['timeRange']
        .add({'wednesday': userChangesTimeTable['wednesday']['timeRange']});
    scheduleData['timeRange']
        .add({'thursday': userChangesTimeTable['thursday']['timeRange']});
    scheduleData['timeRange']
        .add({'friday': userChangesTimeTable['friday']['timeRange']});
    scheduleData['timeRange']
        .add({'saturday': userChangesTimeTable['saturday']['timeRange']});
    scheduleData['timeRange']
        .add({'sunday': userChangesTimeTable['sunday']['timeRange']});
    scheduleData['tasks'] = [];
    scheduleData['tasks']
        .add({'monday': userChangesTimeTable['monday']['tasks']});
    scheduleData['tasks']
        .add({'tuesday': userChangesTimeTable['tuesday']['tasks']});
    scheduleData['tasks']
        .add({'wednesday': userChangesTimeTable['wednesday']['tasks']});
    scheduleData['tasks']
        .add({'thursday': userChangesTimeTable['thursday']['tasks']});
    scheduleData['tasks']
        .add({'friday': userChangesTimeTable['friday']['tasks']});
    scheduleData['tasks']
        .add({'saturday': userChangesTimeTable['saturday']['tasks']});
    scheduleData['tasks']
        .add({'sunday': userChangesTimeTable['sunday']['tasks']});
    return scheduleData;
  }

  Map<String, dynamic> _deepCopy(Map<String, dynamic> original) {
    Map<String, dynamic> copy = {};
    original.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        copy[key] = _deepCopy(value);
      } else if (value is List) {
        copy[key] = List.from(value);
      } else {
        copy[key] = value;
      }
    });
    return copy;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(
          width: double.maxFinite,
        ),
        CupertinoSwitch(
          value: userChangesScheduleActive,
          onChanged: (value) {
            userChangesScheduleActive = value;
            setState(() {});
          },
        ),
        for (String day in userChangesTimeTable.keys)
          Column(
            children: [
              Text(
                day,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              ScheduleItem(
                active: userChangesScheduleActive,
                day: day,
                server: widget.server,
                timeTableCopy: userChangesTimeTable,
                timeRangeChaged: _timeRangeChanged,
                taskChanged: _taskChanged,
              ),
              SizedBox(
                height: 8,
              ),
            ],
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            CustomizedElevatedButton(
              text: 'cancel',
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            SizedBox(
              width: 10,
            ),
            CustomizedElevatedButton(
              text: 'ok',
              onPressed: () {
                Navigator.pop(context);
                widget.server.serverInterface
                    .commandSaveSchedule(_createScheduleData());
              },
            ),
          ],
        ),
      ],
    );
  }
}
