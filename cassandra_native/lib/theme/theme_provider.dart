import 'package:flutter/material.dart';

import 'package:cassandra_native/theme/theme.dart';
import 'package:cassandra_native/utils/ui_state_storage.dart';

// globals
import 'package:cassandra_native/data/user_data.dart' as user;

class ThemeProvider with ChangeNotifier {
  // initially, theme is light mode
  ThemeData _themeData = lightMode;

  // getter method to access the theme from other parts of the code
  ThemeData get themeData => _themeData;

  // getter method to see if wie are in dark mode or not
  bool get isDarkMode => _themeData == darkMode;

  // setter method to set the new theme
  set themeData(ThemeData themeData){
    _themeData = themeData;
    UiStateStorage.saveUiState(user.storedUiState);
    notifyListeners();
  }

  // we will use this toggle in a switch later on..
  void toggleTheme() {
    if (_themeData == lightMode) {
      themeData = darkMode;
      user.storedUiState.theme = 'dark';
    } else {
      themeData = lightMode;
      user.storedUiState.theme = 'light';
    }
  }

  void darkTheme() {
    themeData = darkMode;
  }

  void lightTheme() {
    themeData = lightMode;
  }

  void initTheme() {
    _themeData = user.storedUiState.theme == 'light' ? lightMode : darkMode;
  }
}