import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cassandra_native/models/mow_parameters.dart';

class MowParametersStorage {
  static const _mowParametersKey = 'mowParameters';

  static Future<void> saveMowParameters(MowParameters mowParameters) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_mowParametersKey, jsonEncode(mowParameters.toJson()));
  }

  static Future<MowParameters> loadMowParameters() async {
    final prefs = await SharedPreferences.getInstance();
    final mowParametersString = prefs.getString(_mowParametersKey);
    if (mowParametersString != null) {
      final dynamic mowParametersJson = jsonDecode(mowParametersString);
      return MowParameters.fromJson(mowParametersJson);
    }
    return MowParameters(
      mowPattern: Pattern.lines,
      width: 0.18,
      angle: 0,
      distanceToBorder: 0,
      borderLaps: 0,
      mowArea: true,
      mowExclusionBorder: true,
      mowBorderCcw: false,
    );
  }
}
