import 'package:flutter/material.dart';

const coords = [
  Offset(-10, -5),
  Offset(-10, 5),
  Offset(0, 5),
  Offset(0, 0),
  Offset(10, 0),
  Offset(10, -5),
];
final List<double> x = [-10, -10, 0, 0, 10, 10];
final List<double> y = [-5, 5, 5, 0, 0, -5];

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final TransformationController _transformationController =
      TransformationController();
  late List<Offset> originalPoints;
  late List<Offset> shiftexPoints;
  double minX = 0, minY = 0, maxX = 0, maxY = 0;

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    print(screenSize);

    return LayoutBuilder(builder: (context, constraints) {
      // calc container size
      final width = constraints.maxWidth;
      final height = constraints.maxHeight;
      // look for min an max coordinates
      final minX = coords.map((p) => p.dx).reduce((a, b) => a < b ? a : b);
      final minY = coords.map((p) => p.dy).reduce((a, b) => a < b ? a : b);
      final maxX = coords.map((p) => p.dx).reduce((a, b) => a > b ? a : b);
      final maxY = coords.map((p) => p.dy).reduce((a, b) => a > b ? a : b);

      // shift min coords to 0,0
      final shiftedPoints = coords.map((p) => Offset(p.dx - minX, p.dy - minY)).toList();

      // calc new min an max coords
      final shiftedMaxX = maxX - minX;
      final shiftedMaxY = maxY - minY;
      
      // calc scale factor 1:1 depends on container size
      final scale = (shiftedMaxX / shiftedMaxY) > (width / height)
          ? width / shiftedMaxX
          : height / shiftedMaxY;
          
      // calc coords for canvas
      final points =
          shiftedPoints.map((p) => Offset(p.dx * scale, p.dy * scale)).toList();
      
      // 
      final offsetX = (width - shiftedMaxX * scale) / 2;
      final offsetY = (height - shiftedMaxY * scale) / 2;
      final centeredPoints = points.map((p) => Offset(p.dx + offsetX, p.dy + offsetY)).toList();

      return InteractiveViewer(
        transformationController: _transformationController,
        boundaryMargin: const EdgeInsets.all(double.infinity),
        minScale: 0.01,
        maxScale: 5.0,
        child: AspectRatio(
          aspectRatio: 1,
          child: CustomPaint(
            painter: PolygonPainter(
                perimeterColor: Theme.of(context).colorScheme.inversePrimary,
                points: centeredPoints),
          ),
        ),
      );
    });
  }
}

class PolygonPainter extends CustomPainter {
  final Color perimeterColor;
  final List<Offset> points;
  const PolygonPainter({required this.perimeterColor, required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    var polygonBrush = Paint()
      ..color = perimeterColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final path = Path();
    if (points.isNotEmpty) {
      path.moveTo(points[0].dx, points[0].dy);
      for (var point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      path.close();
    }

    canvas.drawPath(path, polygonBrush);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
