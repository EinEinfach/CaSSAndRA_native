import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class DismissItem extends StatelessWidget {
  const DismissItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
          color: Colors.red, borderRadius: BorderRadius.circular(12)),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(Icons.delete_forever),
          Icon(Icons.delete_forever),
        ],
      ),
    );
  }
}
