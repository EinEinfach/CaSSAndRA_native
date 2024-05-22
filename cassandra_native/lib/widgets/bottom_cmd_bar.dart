import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class BottomCmdBar extends StatelessWidget {
  const BottomCmdBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: GNav(
        mainAxisAlignment: MainAxisAlignment.center,
        iconSize: 18,
        color: Colors.grey[400],
        activeColor: Colors.grey[700],
        tabActiveBorder: Border.all(color: Colors.white),
        tabBackgroundColor: Colors.grey.shade100,
        tabBorderRadius: 16,
        
        tabs: [
          GButton(
            icon: Icons.home_rounded,
            text: 'home',
            onPressed: () {},
            iconColor: Theme.of(context).colorScheme.onBackground,
          ),
          GButton(
            icon: Icons.map_outlined,
            text: 'calc',
            onPressed: () {},
            iconColor: Theme.of(context).colorScheme.onBackground
          ),
          GButton(
            icon: Icons.place_outlined,
            text: 'go to',
            onPressed: (){},
            iconColor: Theme.of(context).colorScheme.onBackground
          ),
        ],
      ),
    );
  }
}
