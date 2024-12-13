import 'package:flutter/material.dart';

import 'package:cassandra_native/models/server.dart';

class ProgressSlider extends StatefulWidget {
  final Server server;
  const ProgressSlider({
    super.key,
    required this.server,
  });

  @override
  State<ProgressSlider> createState() => _ProgressSliderState();
}

class _ProgressSliderState extends State<ProgressSlider> {
  late double _currentValue;

  @override
  void initState() {
    _currentValue = widget.server.currentMap.idxPercent.toDouble();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Slider(
      value: _currentValue,
      min: 0.0,
      max: 100.0,
      divisions: 1000,
      label: _currentValue.toStringAsFixed(1),
      onChanged: (value) {
        setState(() {
          _currentValue = value;
        });
      },
      onChangeEnd: (value) =>
          widget.server.serverInterface.commandSetMowProgress(double.parse((value/100).toStringAsFixed(3))),
    );
  }
}
