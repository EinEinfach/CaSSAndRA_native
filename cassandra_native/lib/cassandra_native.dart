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

  void _handleAppLifecycleState(AppLifecycleState newState) {
    if (newState == AppLifecycleState.paused || newState == AppLifecycleState.detached) {
      for (var server in user.registredServers.servers) {
        server.storeStatus();
      }
      //MqttManager.instance.startAppLifecycleStateTimer();
      MqttManager.instance.disconnectAll();
      for (var server in user.registredServers.servers) {
        server.restoreStatus();
      }
    } 
    // } else if (newState == AppLifecycleState.resumed) {
    //   MqttManager.instance.cancelAppLifecycleStateTimer();
    // }
    // } else if (newState == AppLifecycleState.detached) {
    //   MqttManager.instance.disconnectAll();
    // }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appLifecycleState = state;
    _handleAppLifecycleState(_appLifecycleState);
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
