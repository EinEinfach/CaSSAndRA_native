import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/gestures.dart';

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
            Card(
              child: Padding(
                padding: EdgeInsets.all(10.0),
                child: Text('Linear Speed'),
              ),
            ),
            Card(
              child: Padding(
                padding: EdgeInsets.all(10.0),
                child: Text('Angular Speed'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20), // Abstand zwischen den Karten und dem Joystick
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
                    widget.onJoystickMoved(position);
                  });
                };
                instance.onEnd = (_) {
                  setState(() {
                    position = Offset.zero;
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
