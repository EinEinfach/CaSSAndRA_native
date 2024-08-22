import 'package:flutter/material.dart';

import 'package:cassandra_native/data/ui_state.dart';

class ListButton extends StatefulWidget {
  const ListButton({super.key});

  @override
  State<ListButton> createState() => _ListButtonState();
}

class _ListButtonState extends State<ListButton> {
  IconData listViewIcon = Icons.list;

  void _switchListView() {
    setState(() {
      if (serverListViewOrientation == 'vertical') {
        serverListViewOrientation = 'horizontal';
        listViewIcon = Icons.view_column;
      } else {
        serverListViewOrientation = 'vertical';
        listViewIcon = Icons.list;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      if (serverListViewOrientation == 'vertical') {
        listViewIcon = Icons.list;
      } else {
        listViewIcon = Icons.view_column;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton(
        onPressed: _switchListView,
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
