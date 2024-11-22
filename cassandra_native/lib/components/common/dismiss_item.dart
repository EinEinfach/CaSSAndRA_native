import 'package:flutter/material.dart';
class DismissItem extends StatelessWidget {
  const DismissItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(25, 0, 25, 0),
      decoration: BoxDecoration(
          color: Colors.red, borderRadius: BorderRadius.circular(8)),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(Icons.delete_forever),
          Icon(Icons.delete_forever),
        ],
      ),
    );
  }
}
