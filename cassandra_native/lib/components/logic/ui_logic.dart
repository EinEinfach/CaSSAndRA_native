import 'package:flutter/material.dart';

import 'package:cassandra_native/models/server.dart';
import 'package:cassandra_native/models/landscape.dart';
import 'package:cassandra_native/models/robot.dart';

class PlayButtonLogic {
  List<String> statePlayPlayButton = [
    'idle',
    'charging',
    'docked',
    'stop',
    'move',
    'offline'
  ];
  bool jobActive = false;
  IconData playButtonIcon = Icons.play_arrow;

  void onRobotStatusCheck(Robot robot) {
    if (statePlayPlayButton.contains(robot.status)) {
      jobActive = false;
      playButtonIcon = Icons.play_arrow;
    } else {
      jobActive = true;
      playButtonIcon = Icons.pause;
    }
  }
}
class StatusWindowLogic {
  StatusWindowLogic({required this.currentServer});

  Server currentServer;

  String get uiEstimationTime => _calcEstimationTime();
  String get duration => _calcDurataion();
  String get totalSqm => _calcTotalSqm();
  String get mapName => _getMapName();
  String get distanceData => _getDistanceData();
  String get idxData => _getIdxData();
  String get speedData => _getSpeedData();

  String _calcEstimationTime() {
    Robot robot = currentServer.robot;
    Landscape currentMap = currentServer.currentMap;

    // based on average speed
    if (robot.status == 'mow') {
      final int leftDistance =
          currentMap.totalDistance - currentMap.finishedDistance;
      final double secondsLeft = leftDistance /
          (robot.averageSpeed != 0.0 ? robot.averageSpeed : 0.00001);
      final int estimatedMilliseconds =
          (DateTime.now().millisecondsSinceEpoch + secondsLeft * 1000).toInt();
      DateTime estimatedDateTime =
          DateTime.fromMillisecondsSinceEpoch(estimatedMilliseconds);

      // round to the next 5min
      final int minutesToAdd = 10 - (estimatedDateTime.minute % 10);
      estimatedDateTime = estimatedDateTime.add(
        Duration(minutes: minutesToAdd),
      );
      return '${estimatedDateTime.hour.toString().padLeft(2, '0')}:${estimatedDateTime.minute.toString().padLeft(2, '0')}';
    }
    return '--:--';
  }

  String _calcDurataion() {
    final Robot robot = currentServer.robot;
    final Landscape currentMap = currentServer.currentMap;
    if (robot.status == 'mow') {
      final double seconds = currentMap.totalDistance / robot.averageSpeed;
      return (seconds / 3600).toStringAsFixed(1);
    }
    return '-.-';
  }

  String _calcTotalSqm() {
    final Robot robot = currentServer.robot;
    final Landscape currentMap = currentServer.currentMap;
    if (robot.status == 'mow') {
      return '${currentMap.areaTotal.toString()}m\u00B2';
    }
    return '--';
  }

  String _getMapName() {
    if (currentServer.maps.loaded == null) {
      return '---';
    } else {
      return currentServer.maps.loaded!;
    }
  }

  String _getDistanceData() {
    final Robot robot = currentServer.robot;
    final Landscape currentMap = currentServer.currentMap;
    if (robot.status == 'mow') {
      return '${currentMap.finishedDistance}/${currentMap.totalDistance}m (${currentMap.distancePercent}%)';
    }
    return '--/--m (--%)';
  }

  String _getIdxData() {
    final Robot robot = currentServer.robot;
    final Landscape currentMap = currentServer.currentMap;
    if (robot.status == 'mow') {
      return '${robot.mowPointIdx}/${currentMap.mowPath.length} (${currentMap.idxPercent}%)';
    }
    return '--/-- (--%)';
  }

  String _getSpeedData() {
    final Robot robot = currentServer.robot;
    if (robot.status == 'mow' && robot.secondsPerIdx != null) {
      return '${robot.speed.toStringAsFixed(2)}m/s ${robot.secondsPerIdx!.toStringAsFixed(2)}s/idx';
    }
    return '${robot.speed.toStringAsFixed(2)}m/s --s/idx';
  }
}