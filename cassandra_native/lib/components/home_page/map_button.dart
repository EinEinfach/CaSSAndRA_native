import 'package:flutter/material.dart';

class MapButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final void Function()? onPressed;
  

  const MapButton({
    super.key,
    required this.icon,
    required this.isActive,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = isActive? Theme.of(context).colorScheme.onPrimary.withOpacity(0.9): Theme.of(context).colorScheme.surface.withOpacity(0.9);
    return SizedBox(
      width: 50,
      height: 50,
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
            backgroundColor: backgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: onPressed,
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
      ),
    );
  }
}
