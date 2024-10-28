import 'package:flutter/material.dart';

class InfoButton extends StatelessWidget {
  final void Function() onInfoButtonPressed;
  const InfoButton({
    super.key,
    required this.onInfoButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton(
        onPressed: onInfoButtonPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Icon(
          Icons.info_outline,
          color: Theme.of(context).colorScheme.inversePrimary,
        ),
      ),
    );
  }
}
