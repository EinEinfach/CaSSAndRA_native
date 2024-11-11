import 'package:flutter/material.dart';

class MapProvider extends ChangeNotifier {
  bool? _changeMap;

  bool? get changeMap => _changeMap;

  set changeMap(bool? value) {
    _changeMap = value;
    notifyListeners();
  }
}
