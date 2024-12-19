import 'package:flutter/material.dart';

class NavButton extends StatelessWidget {
  final IconData icon;
  final void Function() onPressed;

  const NavButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
        child: Icon(
          icon,
          size: 30,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
