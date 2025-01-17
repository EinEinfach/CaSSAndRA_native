import 'package:cassandra_native/components/logic/map_logic.dart';
import 'package:flutter/material.dart';

import 'package:cassandra_native/models/landscape.dart';
import 'package:cassandra_native/models/tasks.dart';
import 'package:cassandra_native/utils/custom_shape_calcs.dart';

class TaskHistory {
  List<Task> progress = [];
  int? currentIdx;

  void reset() {
    progress = [];
    currentIdx = null;
  }

  void addNewProgress(Task task) {
    if (progress.isNotEmpty) {
      currentIdx = currentIdx! + 1;
      progress = progress.sublist(0, currentIdx!);
      progress.add(task.copy());
    } else {
      progress.add(task.copy());
      currentIdx = 0;
    }
  }

  Task prevProgress() {
    if (currentIdx! > 0) {
      currentIdx = currentIdx! - 1;
    }
    return progress[currentIdx!];
  }

  Task nextProgress() {
    if (currentIdx! < progress.length - 1) {
      currentIdx = currentIdx! + 1;
    }
    return progress[currentIdx!];
  }
}

class Task {
  Task({
    this.active = false,
    Map<String, List<List<Offset>>>? previews,
    Map<String, List<List<Offset>>>? selections,
    Map<String, List<List<Offset>>>? previewsCartesian,
    Map<String, List<List<Offset>>>? selectionsCartesian,
    Map<String, List<Offset>>? centroids,
  })  : previews = previews ?? {},
        selections = selections ?? {},
        previewsCartesian = previewsCartesian ?? {},
        selectionsCartesian = selectionsCartesian ?? {},
        centroids = centroids ?? {};

  bool active;
  Map<String, List<List<Offset>>> previews;
  Map<String, List<List<Offset>>> selections;
  Map<String, List<List<Offset>>> previewsCartesian;
  Map<String, List<List<Offset>>> selectionsCartesian;
  Map<String, List<Offset>> centroids;
  String? selectedTask;
  int? selectedSubtask;
  int? selectedPointIndex;

  Task copy() {
    return Task(
      active: active,
      previews: _deepCopy(previews),
      selections: _deepCopy(selections),
      previewsCartesian: _deepCopy(previewsCartesian),
      selectionsCartesian: _deepCopy(selectionsCartesian),
      centroids: centroids
          .map((key, value) => MapEntry(key, List<Offset>.from(value))),
    );
  }

  Map<String, List<List<Offset>>> _deepCopy(
      Map<String, List<List<Offset>>> original) {
    return original.map(
      (key, value) => MapEntry(
        key,
        value.map((list) => List<Offset>.from(list)).toList(),
      ),
    );
  }

  void reset() {
    active = false;
    previews = {};
    selections = {};
    centroids = {};
    selectedTask = null;
    selectedSubtask = null;
    selectedPointIndex = null;
  }

  void fromMap(Tasks tasks) {
    previews = _deepCopy(tasks.scaledPreviews);
    selections = _deepCopy(tasks.scaledSelections);
    previewsCartesian = _deepCopy(tasks.previews);
    selectionsCartesian = _deepCopy(tasks.selections);
    centroids = _getCentroids();
  }

  void selectPoint(LongPressStartDetails details, ZoomPanLogic zoomPan) {
    double minDistance = 20 / zoomPan.scale;
    double currentDistance = double.infinity;
    final Offset scaledAndMovedCoords =
        (details.localPosition - zoomPan.offset) / zoomPan.scale;
    for (var taskName in selections.keys) {
      int subTaskNr = 0;
      for (var selection in selections[taskName]!) {
        for (var i = 0; i < selection.length; i++) {
          if ((selection[i] - scaledAndMovedCoords).distance < minDistance &&
              (selection[i] - scaledAndMovedCoords).distance <
                  currentDistance) {
            currentDistance = (selection[i] - scaledAndMovedCoords).distance;
            selectedTask = taskName;
            selectedSubtask = subTaskNr;
            selectedPointIndex = i;
          }
        }
        subTaskNr++;
      }
    }
    if (selectedPointIndex == null) {
      selectSelection(details, zoomPan);
    }
  }

  void selectSelection(LongPressStartDetails details, ZoomPanLogic zoomPan) {
    final Offset scaledAndMovedCoords =
        (details.localPosition - zoomPan.offset) / zoomPan.scale;
    for (var taskName in selections.keys) {
      for (var selection in selections[taskName]!) {
        if (isPointInsidePolygon(scaledAndMovedCoords, selection)) {
          selectedTask = taskName;
          selectedSubtask = selections[taskName]!.indexOf(selection);
          selectedPointIndex = null;
        }
      }
    }
  }

  void unselectAll(){
    selectedTask = null;
    selectedSubtask = null;
    selectedPointIndex = null;
  }

  void scale(Size screenSize, Landscape currentMap) {
    for (var taskName in previewsCartesian.keys) {
      previews[taskName] = previewsCartesian[taskName]!
          .map((shape) => shape
              .map((p) => Offset(
                  (p.dx - currentMap.minX) * currentMap.mapScale +
                      currentMap.offsetX,
                  -(p.dy - currentMap.minY) * currentMap.mapScale +
                      currentMap.offsetY))
              .toList())
          .toList();
    }
    for (var taskName in selectionsCartesian.keys) {
      selections[taskName] = selectionsCartesian[taskName]!
          .map((shape) => shape
              .map((p) => Offset(
                  (p.dx - currentMap.minX) * currentMap.mapScale +
                      currentMap.offsetX,
                  -(p.dy - currentMap.minY) * currentMap.mapScale +
                      currentMap.offsetY))
              .toList())
          .toList();
    }
  }

  Map<String, List<Offset>> _getCentroids() {
    for (var taskName in selections.keys) {
      List<Offset> currentCentroids = [];
      for (var selection in selections[taskName]!) {
        currentCentroids.add(calculateCentroid(selection));
      }
      centroids[taskName] = currentCentroids;
    }
    return centroids;
  }
}
