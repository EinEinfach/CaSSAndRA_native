import 'package:flutter/material.dart';

class BottomCmdBar extends StatelessWidget {
  const BottomCmdBar({super.key});

  @override
  Widget build(BuildContext context) {
    return 
    BottomAppBar(
      shape: CircularNotchedRectangle(),
      notchMargin: 8.0,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          IconButton(
            icon: Icon(
              Icons.home_filled,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(
              Icons.map_outlined,
            ),
            onPressed: () {},
          ),
          SizedBox(width: 48.0),
          IconButton(
            icon: Icon(
              Icons.filter_list,
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
