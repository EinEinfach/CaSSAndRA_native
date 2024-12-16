import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/gestures.dart';

import 'package:cassandra_native/models/server.dart';

class AllowMultipleGestureRecognizer extends PanGestureRecognizer {
  @override
  void rejectGesture(int pointer) {
    acceptGesture(pointer);
  }
}

class JoystickV2 extends StatefulWidget {
  final Server server;
  final Function(Offset, double, double) onJoystickMoved;

  const JoystickV2({
    super.key,
    required this.server,
    required this.onJoystickMoved,
  });

  @override
  State<JoystickV2> createState() => _JoystickV2State();
}

class _JoystickV2State extends State<JoystickV2> {
  Offset position = Offset.zero;
  double radius = 120; // Size of first circle
  double redCircleRadius = 60; // Size of second circle
  final double _maxSpeed = 0.5;
  final int _updateInterval = 200;

  Timer? _timer;
  DateTime? _lastSent;

  @override
  void initState() {
    super.initState();
    _lastSent = DateTime.now();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      if (position != Offset.zero) {
        _updatePosition();
      }
    });
  }

  void _updatePosition() {
    final now = DateTime.now();
    if (now.difference(_lastSent!).inMilliseconds > _updateInterval ||
        position == Offset.zero) {
      _lastSent = DateTime.now();
      widget.onJoystickMoved(position, _maxSpeed, radius);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: RawGestureDetector(
        gestures: {
          AllowMultipleGestureRecognizer: GestureRecognizerFactoryWithHandlers<
              AllowMultipleGestureRecognizer>(
            () => AllowMultipleGestureRecognizer(),
            (AllowMultipleGestureRecognizer instance) {
              instance.onUpdate = (details) {
                setState(() {
                  Offset newPosition =
                      details.localPosition - Offset(radius, radius);
                  if (newPosition.distance <= radius) {
                    position = newPosition;
                  } else {
                    position = Offset.fromDirection(
                      newPosition.direction,
                      radius,
                    );
                  }
                  _updatePosition();
                });
              };
              instance.onEnd = (_) {
                setState(() {
                  position = Offset.zero;
                  _updatePosition();
                });
              };
            },
          ),
        },
        child: Container(
          margin: EdgeInsets.all(5),
          width: 2 * radius,
          height: 2 * radius,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
          ),
          child: Center(
            child: Transform.translate(
              offset: position,
              child: Container(
                width: 2 * redCircleRadius,
                height: 2 * redCircleRadius,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
