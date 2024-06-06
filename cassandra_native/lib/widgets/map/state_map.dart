import 'package:flutter/material.dart';
import 'package:polygon/polygon.dart';

const polygon = Polygon([
  Offset(0.25, -1),
  Offset(0, -0.25),
  Offset(0.5, 0),
  Offset(-0.25, 1),
  Offset(0, 0.25),
  Offset(-0.5, 0),
]);

class StateMap extends StatefulWidget {
  const StateMap({super.key});

  @override
  State createState() => _StateMapState();
}

class _StateMapState extends State<StateMap> {
  final TransformationController _transformationController =
      TransformationController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoscale());
  }

  void _autoscale() {
    Size screenSize = MediaQuery.of(context).size;
    Size containerSize = Size(400, 400);

    double scaleX = screenSize.width / containerSize.width;
    double scaleY = screenSize.height / containerSize.height;
    double scale = scaleX < scaleY ? scaleX : scaleY;

    _transformationController.value = Matrix4.identity()
      ..scale(scale)
      ..translate(
        (screenSize.width - containerSize.width * scale) / 2 / scale,
        (screenSize.height - containerSize.height * scale) / 2 / scale,
      );

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    return Center(
      child: InteractiveViewer(
        transformationController: _transformationController,
        boundaryMargin: EdgeInsets.all(double.infinity),
        minScale: 0.01,
        maxScale: 4.0,
        child: Container(
          width: screenSize.width,
          height: screenSize.height,
          child: CustomPaint(
            painter: PolygonPainter(polygon),
          ),
        ),
      ),
    );
  }
}

class LinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    Offset startPoint = Offset(0, 0);
    Offset endPoint = Offset(200, 200);

    canvas.drawLine(startPoint, endPoint, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

class PolygonPainter extends CustomPainter {
  PolygonPainter(this.polygon);

  final Polygon polygon;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      polygon.computePath(rect: Offset.zero & size),
      Paint()..color = Colors.yellow.shade800
    );
  }

  @override
  bool shouldRepaint(PolygonPainter oldDelegate) {
    return oldDelegate.polygon != polygon;
  }
}