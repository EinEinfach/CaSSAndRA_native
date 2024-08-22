import 'package:flutter/material.dart';

class ListButton extends StatelessWidget {
  final IconData listViewIcon;
  final void Function() onListViewChange;
  const ListButton({
    super.key,
    required this.listViewIcon,
    required this.onListViewChange,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton(
        onPressed: () => onListViewChange(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Icon(
          listViewIcon,
          color: Theme.of(context).colorScheme.inversePrimary,
        ),
      ),
    );
  }
}
