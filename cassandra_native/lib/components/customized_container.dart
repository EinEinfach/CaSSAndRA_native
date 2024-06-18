import 'package:flutter/material.dart';

class CustomizedContainer extends StatelessWidget {
  final double width;
  final double height;
  final EdgeInsetsGeometry padding;
  final Widget child;

  const CustomizedContainer({
    super.key,
    this.width = double.infinity,
    this.height = double.infinity,
    required this.padding,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Theme.of(context).colorScheme.primary,
                offset: const Offset(4, 4),
                blurRadius: 15,
                spreadRadius: 1),
            BoxShadow(
                color: Theme.of(context).colorScheme.onSurface,
                offset: const Offset(-4, -4),
                blurRadius: 15,
                spreadRadius: 1),
          ]),
        child: child,
    );
  }
}
