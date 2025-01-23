import 'package:flutter/material.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';

import 'package:cassandra_native/components/common/buttons/customized_elevated_icon_button.dart';

class TaskInformation extends StatelessWidget {
  final String taskName;
  final int subtaskNrUi;
  final void Function(String, int) onRemoveTaskPressed;
  final void Function(String, int) onEditTaskMowParametersPressed;
  const TaskInformation({
    super.key,
    required this.taskName,
    required this.subtaskNrUi,
    required this.onRemoveTaskPressed,
    required this.onEditTaskMowParametersPressed,
  });

  @override
  Widget build(BuildContext context) {
    int subtaskNr = subtaskNrUi - 1;
    return Column(
      children: [
        Text(
          '$taskName ($subtaskNrUi)',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Row(
          children: [
            CustomizedElevatedIconButton(
              icon: Icons.settings,
              isActive: false,
              onPressed: () => onEditTaskMowParametersPressed(taskName, subtaskNr), 
            ),
            CustomizedElevatedIconButton(
              icon: BootstrapIcons.trash,
              isActive: false,
              onPressed: () => onRemoveTaskPressed(taskName, subtaskNr),
            )
          ],
        ),
      ],
    );
  }
}
