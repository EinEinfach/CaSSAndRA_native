import 'package:flutter/material.dart';

import 'package:cassandra_native/models/server.dart';
import 'package:cassandra_native/components/common/dismiss_item.dart';
import 'package:cassandra_native/components/common/buttons/customized_elevated_button.dart';
import 'package:cassandra_native/components/tasks_page/task_item.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TasksOverview extends StatefulWidget {
  final Server server;
  final VoidCallback onCopyTaskPressed;

  const TasksOverview({
    super.key,
    required this.server,
    required this.onCopyTaskPressed,
  });

  @override
  State<TasksOverview> createState() => _TasksOverviewState();
}

class _TasksOverviewState extends State<TasksOverview> {
  List<String> sortedTaskNames = [];

  @override
  void initState() {
    _sortTasks();
    super.initState();
  }

  void _sortTasks() {
    sortedTaskNames = widget.server.currentMap.tasks.available
        .map((item) => item.toString())
        .toList();
    sortedTaskNames.sort((a, b) => a.compareTo(b));
  }

  void onNewTaskSelected() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    int dialogHeight = 50;
    if (sortedTaskNames.length > 1 && sortedTaskNames.length < 6) {
      dialogHeight = sortedTaskNames.length * 45;
    } else if (sortedTaskNames.length >= 6) {
      dialogHeight = 6 * 45;
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.maxFinite,
          height: dialogHeight.toDouble(),
          child: ListView.builder(
            scrollDirection: Axis.vertical,
            itemCount: sortedTaskNames.length,
            itemBuilder: (context, index) {
              final task = sortedTaskNames[index];
              return Dismissible(
                key: Key(task),
                background: const DismissItem(),
                onDismissed: (direction) {
                  widget.server.currentMap.tasks.resetTaskCoords(task);
                  widget.server.serverInterface.commandRemoveTask([task]);
                  if (widget.server.currentMap.tasks.selected.contains(task)) {
                    widget.server.serverInterface.commandSelectTasks([]);
                  }
                },
                child: TaskItem(
                  taskName: task,
                  server: widget.server,
                  onNewTaskSelected: onNewTaskSelected,
                  onCopyTaskPressed: () {
                    widget.server.serverInterface.commandCopyTask([task]);
                    final newName = '${task}_copy';
                    widget.server.currentMap.tasks.available.add(newName);
                    widget.onCopyTaskPressed();
                  },
                ).animate().fadeIn().scale(),
              );
            },
          ),
        ),
        SizedBox(
          height: 8,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            CustomizedElevatedButton(
              text: 'upload',
              onPressed: () {
                if (widget.server.currentMap.tasks.selected.isNotEmpty) {
                  widget.server.serverInterface.commandLoadTasks(
                      widget.server.currentMap.tasks.selected);
                }
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
        )
      ],
    );
  }
}
