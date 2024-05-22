import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:cassandra_native/theme/theme_provider.dart';
import 'package:cassandra_native/data/ui_state.dart';

class DarkModeSwitch extends StatefulWidget{
  const DarkModeSwitch({super.key});

  @override
  State<DarkModeSwitch> createState() => _DarkModeSwitchState();

}

class _DarkModeSwitchState extends State<DarkModeSwitch>{
  bool isSwitched = darkMode;

  void _switchTheme(bool value){
    if (value) {
      Provider.of<ThemeProvider>(context, listen: false).darkTheme();
    } else {
      Provider.of<ThemeProvider>(context, listen: false).lightTheme();
    }
    darkMode = value;
    setState(() {
      isSwitched = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Switch.adaptive(
      value: isSwitched, 
      onChanged: _switchTheme,
      activeTrackColor: Theme.of(context).colorScheme.onBackground,
      
    );
  }
}