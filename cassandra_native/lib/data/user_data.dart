import 'package:cassandra_native/models/ui_state.dart';
import 'package:cassandra_native/models/server.dart';
import 'package:cassandra_native/models/mow_parameters.dart';

UiState storedUiState = UiState(serversListViewOrientation: 'vertical');
Servers registredServers = Servers();
MowParameters currentMowParameters = MowParameters(
  mowPattern: Pattern.lines,
  width: 0.18,
  angle: 0,
  distanceToBorder: 0,
  borderLaps: 0,
  mowArea: true,
  mowExclusionBorder: true,
  mowBorderCcw: false,
);
