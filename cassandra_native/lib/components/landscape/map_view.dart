import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

const coords = [
  [
    Offset(10, 10),
    Offset(10, 20),
    Offset(20, 20),
    Offset(20, 10),
    Offset(10, 10),
  ],
  [
    Offset(15, 15),
    Offset(15, 16),
    Offset(16, 16),
    Offset(16, 15),
    Offset(15, 15),
  ]
];

const roverPostion = Offset(15, 15);
double roverRotation = 0.5;

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final TransformationController _transformationController =
      TransformationController();
  double minX = double.infinity,
      minY = double.infinity,
      maxX = double.negativeInfinity,
      maxY = double.negativeInfinity;
  double baseLineWidth = 2;
  ui.Image? roverImage;

  @override
  void initState() {
    super.initState();
    _loadImage('lib/images/rover0grad.png');
  }

  Future<void> _loadImage(String asset) async {
    final data = await rootBundle.load(asset);
    final list = Uint8List.view(data.buffer);
    final codec = await ui.instantiateImageCodec(list);
    final frame = await codec.getNextFrame();
    setState(() {
      roverImage = frame.image;
    });
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    return LayoutBuilder(builder: (context, constraints) {
      // calc container size
      final width = constraints.maxWidth;
      final height = constraints.maxHeight;

      // look for min an max coordinates
      for (var polygon in coords) {
        for (var point in polygon) {
          if (point.dx < minX) minX = point.dx;
          if (point.dy < minY) minY = point.dy;
          if (point.dx > maxX) maxX = point.dx;
          if (point.dy > maxY) maxY = point.dy;
        }
      }

      // shift min coords to 0,0
      final shiftedPolygons = coords
          .map((polygon) =>
              polygon.map((p) => Offset(p.dx - minX, p.dy - minY)).toList())
          .toList();

      // calc new min an max coords
      final shiftedMaxX = maxX - minX;
      final shiftedMaxY = maxY - minY;

      // calc scale factor 1:1 depends on container size
      final scale = (shiftedMaxX / shiftedMaxY) > (width / height)
          ? width / shiftedMaxX
          : height / shiftedMaxY;

      // calc coords for canvas
      final scaledPolygons = shiftedPolygons
          .map((polygon) =>
              polygon.map((p) => Offset(p.dx * scale, p.dy * scale)).toList())
          .toList();

      //
      final offsetX = (width - shiftedMaxX * scale) / 2;
      final offsetY = (height - shiftedMaxY * scale) / 2;

      final centeredPolygons = scaledPolygons
          .map((polygon) => polygon
              .map((p) => Offset(p.dx + offsetX, p.dy + offsetY))
              .toList())
          .toList();

      // calc rover postion for canvas
      final shiftedRoverPosition = Offset(
          (roverPostion.dx - minX) * scale + offsetX,
          (roverPostion.dy - minY) * scale + offsetY);

      return InteractiveViewer(
        transformationController: _transformationController,
        boundaryMargin: const EdgeInsets.all(double.infinity),
        minScale: 0.01,
        maxScale: 5.0,
        child: SizedBox(
          width: screenSize.width,
          height: screenSize.height,
          child: AspectRatio(
            aspectRatio: 1,
            child: CustomPaint(
              painter: PolygonPainter(
                polygons: centeredPolygons,
                colors: Theme.of(context).colorScheme,
                transformationController: _transformationController,
                lineWidth: baseLineWidth,
                roverImage: roverImage,
                roverPostion: shiftedRoverPosition,
                roverRotaion: roverRotation,
              ),
            ),
          ),
        ),
      );
    });
  }
}

class PolygonPainter extends CustomPainter {
  final List<List<Offset>> polygons;
  final ColorScheme colors;
  final TransformationController transformationController;
  final double lineWidth;
  final ui.Image? roverImage;
  final Offset roverPostion;
  final double roverRotaion;

  const PolygonPainter(
      {required this.polygons,
      required this.colors,
      required this.transformationController,
      required this.lineWidth,
      required this.roverImage,
      required this.roverPostion,
      required this.roverRotaion});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = transformationController.value.getMaxScaleOnAxis();
    final adjustedLineWidth = lineWidth / scale;

    var polygonBrush = Paint()
      ..color = colors.inversePrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = adjustedLineWidth;

    for (var points in polygons) {
      final path = Path();
      if (points.isNotEmpty) {
        path.moveTo(points[0].dx, points[0].dy);
        for (var point in points.skip(1)) {
          path.lineTo(point.dx, point.dy);
        }
        path.close();
      }
      canvas.drawPath(path, polygonBrush);

      if (roverImage != null) {
        final imageSize = 70.0;

        // rotate rover image
        canvas.save();
        canvas.translate(roverPostion.dx, roverPostion.dy);
        canvas.rotate(roverRotaion);
        canvas.translate(-roverPostion.dx, -roverPostion.dy);

        final rect = Rect.fromCenter(
            center: roverPostion, width: imageSize, height: imageSize);
        paintImage(
            canvas: canvas, rect: rect, image: roverImage!, fit: BoxFit.cover);

        // restore saved canvas
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
