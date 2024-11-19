import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CommandButtonSmall extends StatelessWidget {
  final IconData icon;
  final void Function() onPressed;
  final void Function() onLongPressed;
  const CommandButtonSmall({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.onLongPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor:
            Theme.of(context).colorScheme.surface.withOpacity(0.90),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        fixedSize: const Size(80, 35),
        //minimumSize: const Size(80, 80),
      ),
      onPressed: () {
        onPressed();
        HapticFeedback.lightImpact();
      },
      onLongPress: () {
        onLongPressed();
        HapticFeedback.mediumImpact();
      },
      child: Icon(
        icon,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
