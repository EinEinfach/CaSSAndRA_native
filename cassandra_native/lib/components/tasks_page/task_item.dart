import 'package:flutter/material.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';

import 'package:cassandra_native/models/server.dart';
import 'package:cassandra_native/components/common/buttons/customized_elevated_icon_button.dart';

class TaskItem extends StatefulWidget {
  final String taskName;
  final Server server;
  final VoidCallback onNewTaskSelected;
  final VoidCallback onCopyTaskPressed;

  const TaskItem({
    super.key,
    required this.taskName,
    required this.server,
    required this.onNewTaskSelected,
    required this.onCopyTaskPressed,
  });

  @override
  State<TaskItem> createState() => _TaskItemState();
}

class _TaskItemState extends State<TaskItem> {
  final TextEditingController _taskRenameController = TextEditingController();
  bool _taskRename = false;
  late String _taskName;

  @override
  void initState() {
    _taskName = widget.taskName;
    _taskRenameController.text = widget.taskName;
    super.initState();
  }

  @override
  void dispose() {
    _taskRenameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!widget.server.currentMap.tasks.selected.contains(_taskName)) {
          widget.server.currentMap.tasks.selected.add(_taskName);
          widget.server.serverInterface
              .commandSelectTasks(widget.server.currentMap.tasks.selected);
        } else {
          widget.server.currentMap.tasks.resetTaskCoords(_taskName);
          widget.server.serverInterface
              .commandSelectTasks(widget.server.currentMap.tasks.selected);
        }
        setState(() {});
      },
      child: Container(
        decoration: BoxDecoration(
          color: widget.server.currentMap.tasks.selected.contains(_taskName)
              ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
              : Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        height: 40,
        margin: const EdgeInsets.all(2),
        //padding: const EdgeInsets.fromLTRB(20, 5, 5, 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: _taskRename
                  ? Container(
                      padding: EdgeInsets.all(2),
                      child: TextField(
                        controller: _taskRenameController,
                        style: Theme.of(context).textTheme.bodyMedium,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.secondary,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none),
                        ),
                      ),
                    )
                  : Container(
                      padding: EdgeInsets.fromLTRB(9, 0, 0, 0),
                      child: Text(
                        style: Theme.of(context).textTheme.bodyMedium,
                        _taskName,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
            ),
            Row(
              children: [
                SizedBox(
                  width: 8,
                ),
                CustomizedElevatedIconButton(
                  icon: BootstrapIcons.copy,
                  isActive: false,
                  onPressed: () {
                    widget.onCopyTaskPressed();
                  },
                ),
                CustomizedElevatedIconButton(
                    icon: BootstrapIcons.pencil_square,
                    isActive: _taskRename,
                    onPressed: () {
                      if (_taskRename &&
                          _taskName != _taskRenameController.text) {
                        widget.server.serverInterface.commandRenameTask(
                            [_taskName, _taskRenameController.text]);
                        _taskName = _taskRenameController.text;
                      }
                      _taskRename = !_taskRename;
                      setState(() {});
                    }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
