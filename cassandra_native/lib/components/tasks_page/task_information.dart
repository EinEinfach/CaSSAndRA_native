import 'package:flutter/material.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';

import 'package:cassandra_native/components/common/buttons/customized_elevated_icon_button.dart';

class TaskInformation extends StatelessWidget {
  final String taskName;
  final int subtaskNr;
  const TaskInformation({
    super.key,
    required this.taskName,
    required this.subtaskNr,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$taskName ($subtaskNr)',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Row(
          children: [
            CustomizedElevatedIconButton(
              icon: Icons.settings,
              isActive: false,
              onPressed: () {},
            ),
            CustomizedElevatedIconButton(
              icon: BootstrapIcons.trash,
              isActive: false,
              onPressed: () {},
            )
          ],
        ),
      ],
    );
  }
}
