import 'package:flutter/material.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';

import 'package:cassandra_native/components/common/buttons/customized_elevated_icon_button.dart';

class ServerItemHiddenButtons extends StatelessWidget {
  const ServerItemHiddenButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.transparent,
        // color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomizedElevatedIconButton(
            icon: BootstrapIcons.power,
            isActive: false,
            onPressed: () {},
          ),
          CustomizedElevatedIconButton(
            icon: BootstrapIcons.bootstrap_reboot,
            isActive: false,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
