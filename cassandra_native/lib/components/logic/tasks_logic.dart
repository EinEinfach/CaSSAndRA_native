import 'package:cassandra_native/components/logic/map_logic.dart';
import 'package:cassandra_native/models/mow_parameters.dart';
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
    Map<String, List<Offset>>? centroidsUserOffset,
    Map<String, List<MowParameters>>? mowParameters,
  })  : previews = previews ?? {},
        selections = selections ?? {},
        previewsCartesian = previewsCartesian ?? {},
        selectionsCartesian = selectionsCartesian ?? {},
        centroids = centroids ?? {},
        centroidsUserOffset = centroidsUserOffset ?? {},
        mowParameters = mowParameters ?? {};

  bool active;
  Map<String, List<List<Offset>>> previews;
  Map<String, List<List<Offset>>> selections;
  Map<String, List<List<Offset>>> previewsCartesian;
  Map<String, List<List<Offset>>> selectionsCartesian;
  Map<String, List<Offset>> centroids;
  Map<String, List<Offset>> centroidsUserOffset;
  Map<String, List<MowParameters>> mowParameters;
  String? selectedTask;
  int? selectedSubtask;
  int? selectedPointIndex;
  Offset? selectedPointCoordsStart;
  Offset? lastPosition;
  Offset? pointInformationPosition;

  Task copy() {
    return Task(
      active: active,
      previews: _deepCopy(previews),
      selections: _deepCopy(selections),
      previewsCartesian: _deepCopy(previewsCartesian),
      selectionsCartesian: _deepCopy(selectionsCartesian),
      centroids: centroids
          .map((key, value) => MapEntry(key, List<Offset>.from(value))),
      centroidsUserOffset: centroidsUserOffset
          .map((key, value) => MapEntry(key, List<Offset>.from(value))),
      mowParameters: _deepCopyMowParameters(mowParameters),
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

  Map<String, List<MowParameters>> _deepCopyMowParameters(
      Map<String, List<MowParameters>> original) {
    return original.map(
      (key, value) => MapEntry(
        key,
        value.map((list) => list).toList(),
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
    selectedPointCoordsStart = null;
    centroidsUserOffset = {};
    lastPosition = null;
    pointInformationPosition = null;
  }

  void fromMap(Tasks tasks) {
    previews = _deepCopy(tasks.scaledPreviews);
    selections = _deepCopy(tasks.scaledSelections);
    previewsCartesian = _deepCopy(tasks.previews);
    selectionsCartesian = _deepCopy(tasks.selections);
    centroids = _getCentroids();
    mowParameters = _deepCopyMowParameters(tasks.mowParameters);
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
            selectedPointCoordsStart = selection[i];
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
          lastPosition = scaledAndMovedCoords;
        }
      }
    }
  }

  void move(LongPressMoveUpdateDetails details, ZoomPanLogic zoomPan) {
    if (selectedPointIndex != null) {
      _moveSelectedPoint(details, zoomPan);
    } else if (selectedSubtask != null) {
      _moveShape(details, zoomPan);
    }
  }

  void toCartesian(Landscape currentMap) {
    Map<String, List<List<Offset>>> newPreviews = {};
    Map<String, List<List<Offset>>> newSelections = {};
    for (var taskName in previews.keys) {
      List<List<Offset>> currentPreviews = [];
      for (var preview in previews[taskName]!) {
        currentPreviews.add(_canvasCoordsToCartesian(preview, currentMap));
      }
      newPreviews[taskName] = currentPreviews;
    }
    for (var taskName in selections.keys) {
      List<List<Offset>> currentSelections = [];
      for (var selection in selections[taskName]!) {
        currentSelections.add(_canvasCoordsToCartesian(selection, currentMap));
      }
      newSelections[taskName] = currentSelections;
    }
    previewsCartesian = newPreviews;
    selectionsCartesian = newSelections;
  }

  List<Offset> _canvasCoordsToCartesian(
      List<Offset> shape, Landscape currentMap) {
    shape = shape
        .map(
            (p) => Offset(p.dx - currentMap.offsetX, p.dy - currentMap.offsetY))
        .toList();
    shape = shape
        .map((p) =>
            Offset(p.dx / currentMap.mapScale, p.dy / currentMap.mapScale))
        .toList();
    shape = shape
        .map((p) => Offset(p.dx + currentMap.minX, -p.dy + currentMap.minY))
        .toList();
    return shape;
  }

  void unselectAll() {
    selectedTask = null;
    selectedSubtask = null;
    selectedPointIndex = null;
    selectedPointCoordsStart = null;
    pointInformationPosition = null;
  }

  void removePoint() {
    if (selectedPointIndex != null &&
        selections[selectedTask!]![selectedSubtask!].length > 3) {
      if (selectedPointIndex == 0) {
        selections[selectedTask!]![selectedSubtask!].removeAt(0);
        selections[selectedTask!]![selectedSubtask!]
            .removeAt(selections[selectedTask!]![selectedSubtask!].length - 1);
        selections[selectedTask!]![selectedSubtask!]
            .add(selections[selectedTask!]![selectedSubtask!].first);
      } else {
        selections[selectedTask!]![selectedSubtask!]
            .removeAt(selectedPointIndex!);
      }
    }
  }

  void removeSubtask() {
    if (selectedTask != null &&
        selectedSubtask != null &&
        selectedPointIndex == null) {
      previews[selectedTask!]!.removeAt(selectedSubtask!);
      selections[selectedTask!]!.removeAt(selectedSubtask!);
      centroids[selectedTask!]!.removeAt(selectedSubtask!);
      unselectAll();
    }
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

  Map<String, dynamic> toGeoJson(String name) {
    List<dynamic> features = [];
    Map<String, dynamic> taskJson = {};
    int subtaskNr = 0;
    final nameFeature = {
      'type': 'Feature',
      'properties': {
        'taskName': name,
      },
    };
    features.add(nameFeature);
    for (var taskName in selections.keys) {
      for (var i = 0; i < selections[taskName]!.length; i++) {
        final taskFeature = selections[taskName]![i].isNotEmpty
            ? {
                'type': 'Feature',
                'properties': {
                  'subtaskNr': subtaskNr,
                  'mowParameters': mowParameters[taskName]![i].toJson(),
                },
                'geometry': [
                  {
                    'type': 'Polygon',
                    'coordinates': [
                      selectionsCartesian[taskName]![i]
                          .map((point) => [point.dx, point.dy])
                          .toList()
                    ],
                  },
                  {
                    'type': 'LineString',
                    'coordinates': [
                      previewsCartesian[taskName]![i]
                          .map((point) => [point.dx, point.dy])
                          .toList()
                    ],
                  }
                ],
              }
            : [
                {'type': 'Polygon', 'coordinates': []},
                {
                  'type': 'LineString',
                  'coordinates': [
                    previewsCartesian[taskName]![i]
                        .map((point) => [point.dx, point.dy])
                        .toList()
                  ]
                },
              ];
        features.add(taskFeature);
        subtaskNr++;
      }
    }
    taskJson = {
      'type': 'FeatureCollection',
      'features': features,
    };
    return taskJson;
  }

  void _moveSelectedPoint(
      LongPressMoveUpdateDetails details, ZoomPanLogic zoomPan) {
    final Offset scaledAndMovedCoords =
        (details.localPosition - zoomPan.offset) / zoomPan.scale;
    final taskSelection = selections[selectedTask!]![selectedSubtask!].toList();
    final taskSelectionCopy =
        selections[selectedTask!]![selectedSubtask!].toList();
    if (selectedPointIndex == 0 ||
        selectedPointIndex == taskSelection.length - 1) {
      taskSelection.first = scaledAndMovedCoords;
      taskSelection.last = scaledAndMovedCoords;
    } else {
      taskSelection[selectedPointIndex!] = scaledAndMovedCoords;
    }
    if (hasSelfIntersections(taskSelection.sublist(1, taskSelection.length))) {
      selections[selectedTask!]![selectedSubtask!] = taskSelectionCopy;
    } else {
      selections[selectedTask!]![selectedSubtask!] = taskSelection;
      // centroids[selectedTask!]![selectedSubtask!] =
      //     calculateCentroid(selections[selectedTask!]![selectedSubtask!]) +
      //         (centroidsUserOffset.containsKey(selectedTask!)
      //             ? centroidsUserOffset[selectedTask!]![selectedSubtask!]
      //             : Offset.zero);
    }
  }

  void _moveShape(LongPressMoveUpdateDetails details, ZoomPanLogic zoomPan) {
    final Offset scaledAndMovedCoords =
        (details.localPosition - zoomPan.offset) / zoomPan.scale;
    final Offset delta = scaledAndMovedCoords - lastPosition!;
    selections[selectedTask!]![selectedSubtask!] =
        selections[selectedTask!]![selectedSubtask!]
            .map((point) => point + delta)
            .toList();
    previews[selectedTask!]![selectedSubtask!] =
        previews[selectedTask!]![selectedSubtask!]
            .map((point) => point + delta)
            .toList();
    centroids[selectedTask!]![selectedSubtask!] =
        centroids[selectedTask!]![selectedSubtask!] + delta;
    // centroids[selectedTask!]![selectedSubtask!] =
    //     calculateCentroid(selections[selectedTask!]![selectedSubtask!]) +
    //         (centroidsUserOffset.containsKey(selectedTask!)
    //             ? centroidsUserOffset[selectedTask!]![selectedSubtask!]
    //             : Offset.zero);
    lastPosition = scaledAndMovedCoords;
  }

  Map<String, List<Offset>> _getCentroids() {
    for (var taskName in selections.keys) {
      List<Offset> currentCentroids = [];
      List<Offset> currentCentroidsUserOffset = [];
      for (int i = 0; i < selections[taskName]!.length; i++) {
        currentCentroids.add(calculateCentroid(selections[taskName]![i]));
        currentCentroidsUserOffset.add(Offset.zero);
      }
      centroids[taskName] = currentCentroids;
      centroidsUserOffset[taskName] = currentCentroidsUserOffset;
    }
    return centroids;
  }

  void selectTaskOrPointInformation(
      LongPressStartDetails details, ZoomPanLogic zoomPan) {
    final scaledAndMovedCoords =
        (details.localPosition - zoomPan.offset) / zoomPan.scale;
    lastPosition = scaledAndMovedCoords;
  }

  void moveTaskInformation(String taskName, int subTaskNr,
      LongPressMoveUpdateDetails details, ZoomPanLogic zoomPan) {
    final Offset scaledAndMovedCoords =
        (details.localPosition - zoomPan.offset) / zoomPan.scale;
    final Offset delta = scaledAndMovedCoords - lastPosition!;
    centroids[taskName]![subTaskNr] = centroids[taskName]![subTaskNr] + delta;
    lastPosition = scaledAndMovedCoords;
    // final Offset scaledAndMovedCoords =
    //     (details.globalPosition - zoomPan.offset) / zoomPan.scale;
    // centroids[taskName]![subTaskNr] = scaledAndMovedCoords + Offset(-15, -80);
  }

  void movePointInformation(Offset position, LongPressMoveUpdateDetails details,
      ZoomPanLogic zoomPan) {
    final Offset scaledAndMovedCoords =
        (details.localPosition - zoomPan.offset) / zoomPan.scale;
    final Offset delta = scaledAndMovedCoords - lastPosition!;
    pointInformationPosition = position + delta;
    lastPosition = scaledAndMovedCoords;
    // final Offset scaledAndMovedCoords =
    //     (details.globalPosition - zoomPan.offset) / zoomPan.scale;
    // pointInformationPosition = scaledAndMovedCoords + Offset(-15, -80);
  }

  Map<String, dynamic> subtaskToGeoJson(String taskName, int subtaskNr,
      List<Offset> selection, MowParameters mowParameters) {
    List<dynamic> features = [];
    Map<String, dynamic> taskJson = {};
    final nameFeature = {
      'type': 'Feature',
      'properties': {
        'taskName': taskName,
        'mowParameters': mowParameters.toJson(),
      },
    };
    features.add(nameFeature);
    final taskFeature = selection.isNotEmpty
        ? {
            'type': 'Feature',
            'properties': {
              'subtaskNr': subtaskNr,
              'mowParameters': mowParameters.toJson(),
            },
            'geometry': {
              'type': 'Polygon',
              'coordinates': [
                selection.map((point) => [point.dx, point.dy]).toList()
              ],
            }
          }
        : {'type': 'Polygon', 'coordinates': []};
    features.add(taskFeature);
    taskJson = {
      'type': 'FeatureCollection',
      'features': features,
    };
    return taskJson;
  }

  void addSubtask(List<Offset> selection, MowParameters taskMowParameters,
      Landscape currentMap) {
    late List<Offset> currentSelection;
    if (selection.isNotEmpty) {
      currentSelection = List.of(selection);
      currentSelection.add(selection.first);
    } else {
      currentSelection = currentMap.scaledPerimeter;
    }
    previews[''] = [];
    selections[''] = [];
    mowParameters[''] = [];
    centroids[''] = [];
    previews['']!.add([]);
    selections['']!.add(currentSelection);
    centroids['']!.add(calculateCentroid(currentSelection));
    mowParameters['']!.add(taskMowParameters);
  }

  void updatePreview(Map<String, dynamic> updatedCoords) {
    List<Offset> coords = [];
    for (var coord in updatedCoords['preview']['coordinates'][0]) {
      coords.add(Offset(coord[0], coord[1]));
    }
    previewsCartesian[updatedCoords['taskName']]![updatedCoords['subtaskNr']] =
        coords;
  }
}
