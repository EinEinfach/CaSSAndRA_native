import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/gestures.dart';
import 'dart:math';

class AllowMultipleGestureRecognizer extends PanGestureRecognizer {
  @override
  void rejectGesture(int pointer) {
    acceptGesture(pointer);
  }
}

class Joystick extends StatefulWidget {
  final Function(Offset) onJoystickMoved;

  const Joystick({super.key, required this.onJoystickMoved});

  @override
  _JoystickState createState() => _JoystickState();
}

class _JoystickState extends State<Joystick> {
  Offset position = Offset.zero;
  double _linearSpeed = 0.0;
  double _angularSpeed = 0.0;
  static double _maxSpeed = 0.5;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (position != Offset.zero) {
        widget.onJoystickMoved(position);
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double radius = 120; // Size of first circle
    const double redCircleRadius = radius / 2; // Size of second circle

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: Card(
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
                        details.localPosition - const Offset(radius, radius);
                    if (newPosition.distance <= radius) {
                      position = newPosition;
                    } else {
                      position = Offset.fromDirection(
                        newPosition.direction,
                        radius,
                      );
                    }
                    _linearSpeed = -1*_maxSpeed*((position.distance)/radius)*sin(position.direction);
                    _angularSpeed = -1*_maxSpeed*((position.distance)/radius)*cos(position.direction);
                    widget.onJoystickMoved(position);
                  });
                };
                instance.onEnd = (_) {
                  setState(() {
                    position = Offset.zero;
                    _linearSpeed = 0;
                    _angularSpeed = 0;
                    widget.onJoystickMoved(position);
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
              color: Theme.of(context).colorScheme.background.withOpacity(0.8),
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
