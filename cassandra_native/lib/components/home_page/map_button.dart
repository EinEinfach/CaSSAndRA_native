import 'package:flutter/material.dart';

class MapButton extends StatelessWidget {
  final IconData icon;
  final double verticalAligment;
  final double horizontalAlignment;
  final void Function()? onPressed;

  const MapButton({
    super.key,
    required this.icon,
    required this.verticalAligment,
    required this.horizontalAlignment,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      alignment: Alignment(horizontalAlignment, verticalAligment),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          backgroundColor:
              Theme.of(context).colorScheme.surface.withOpacity(0.90),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: onPressed,
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
      ),
    );
  }
}
