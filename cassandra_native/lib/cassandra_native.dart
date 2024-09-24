import 'package:flutter/material.dart';

import 'package:cassandra_native/comm/mqtt_manager.dart';

// globals
import 'package:cassandra_native/data/user_data.dart' as user;

class CassandraNative extends ChangeNotifier with WidgetsBindingObserver {
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;

  AppLifecycleState get appLifecycleState => _appLifecycleState;

  CassandraNative() {
    WidgetsBinding.instance.addObserver(this);
  }

  void _handleAppLifecycleState(AppLifecycleState oldState, AppLifecycleState newState) {
    if (newState == AppLifecycleState.inactive && oldState == AppLifecycleState.resumed) {
      for (var server in user.registredServers.servers) {
        server.storeStatus();
      }
      MqttManager.instance.startAppLifecycleStateTimer();
      //MqttManager.instance.disconnectAll();
    } else if (newState == AppLifecycleState.resumed) {
      MqttManager.instance.cancelAppLifecycleStateTimer();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _handleAppLifecycleState(_appLifecycleState, state);
    _appLifecycleState = state;
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
