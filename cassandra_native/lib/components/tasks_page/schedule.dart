import 'package:flutter/material.dart';

import 'package:cassandra_native/models/server.dart';

class Schedule extends StatefulWidget {
  final Server server;
  const Schedule({
    super.key,
    required this.server,
  });

  @override
  State<Schedule> createState() => _ScheduleState();
}

class _ScheduleState extends State<Schedule> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
