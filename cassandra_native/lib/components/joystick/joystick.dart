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

class Joystick extends StatefulWidget {
  final Server server;
  final Function(Offset, double, double) onJoystickMoved;

  const Joystick({
    super.key,
    required this.onJoystickMoved,
    required this.server,
  });

  @override
  State createState() => _JoystickState();
}

class _JoystickState extends State<Joystick> {
  Offset position = Offset.zero;
  double radius = 120; // Size of first circle
  double redCircleRadius = 60; // Size of second circle
  double _linearSpeed = 0.0;
  double _angularSpeed = 0.0;
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

  void _startTimer(){
    _timer = Timer.periodic(const Duration(milliseconds: 10), (timer){
      if (position != Offset.zero){
        _updatePosition();
      }
    });
  }

  void _updatePosition(){
    final now = DateTime.now();
    if (now.difference(_lastSent!).inMilliseconds > _updateInterval || position == Offset.zero) {
      _lastSent = DateTime.now();
      widget.onJoystickMoved(position, _maxSpeed, radius);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: Card(
                color: Theme.of(context).colorScheme.primary,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text('Linear Speed'),
                      const SizedBox(
                        height: 2,
                      ),
                      Text(
                        _linearSpeed.toStringAsFixed(2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Card(
                color: Theme.of(context).colorScheme.primary,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text('Angular Speed'),
                      const SizedBox(
                        height: 2,
                      ),
                      Text(
                        _angularSpeed.toStringAsFixed(2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        RawGestureDetector(
          gestures: {
            AllowMultipleGestureRecognizer:
                GestureRecognizerFactoryWithHandlers<
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
                    _linearSpeed = -1 * _maxSpeed * position.dy / radius;
                    _angularSpeed = -1 * _maxSpeed * position.dx / radius;
                    _updatePosition();
                  });
                };
                instance.onEnd = (_) {
                  setState(() {
                    position = Offset.zero;
                    _linearSpeed = 0;
                    _angularSpeed = 0;
                    _updatePosition();
                  });
                };
              },
            ),
          },
          child: Container(
            width: 2 * radius,
            height: 2 * radius,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Center(
              child: Transform.translate(
                offset: position,
                child: Container(
                  width: 2 * redCircleRadius,
                  height: 2 * redCircleRadius,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withOpacity(0.8),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
