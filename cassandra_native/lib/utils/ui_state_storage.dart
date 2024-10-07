import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cassandra_native/models/ui_state.dart';

class UiStateStorage {
  static const _uiStateKey = 'uiState';

  static Future<void> saveUiState(UiState uiState) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_uiStateKey, jsonEncode(uiState.toJson()));
  }

  static Future<UiState> loadUiState() async {
    final prefs = await SharedPreferences.getInstance();
    final uiStateString = prefs.getString(_uiStateKey);
    if (uiStateString != null) {
      final dynamic uiStateJson = jsonDecode(uiStateString);
      return UiState.fromJson(uiStateJson);
    }
    return UiState(serversListViewOrientation: 'vertical', theme: 'light');
  }
}