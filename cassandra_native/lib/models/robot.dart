import 'package:cassandra_native/models/shapes.dart';

class Robot {
  String status = 'offline';
  Point position = Point(x: 0, y: 0);
  Point target = Point(x: 0, y: 0);
  double angle = 0;
}