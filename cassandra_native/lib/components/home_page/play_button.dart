import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PlayButton extends StatelessWidget {
  final IconData icon;
  const PlayButton({super.key, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      alignment: const Alignment(1, 1),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              Theme.of(context).colorScheme.surface.withOpacity(0.90),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          minimumSize: const Size(80, 80),
        ),
        onPressed: () {
          HapticFeedback.lightImpact();
        },
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}