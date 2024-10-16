import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../models/robot.dart';

class StatusBar extends StatelessWidget {
  final Robot robot;
  const StatusBar({
    super.key,
    required this.robot,
  });

  IconData _createBatteryIcon() {
    if (robot.status == 'charging') {
      return Icons.battery_charging_full_rounded;
    } else if (robot.soc > 95) {
      return Icons.battery_full_rounded;
    } else if (robot.soc > 90) {
      return Icons.battery_6_bar_rounded;
    } else if (robot.soc > 80) {
      return Icons.battery_5_bar_rounded;
    } else if (robot.soc > 70) {
      return Icons.battery_5_bar_rounded;
    } else if (robot.soc > 60) {
      return Icons.battery_4_bar_rounded;
    } else if (robot.soc > 50) {
      return Icons.battery_3_bar_rounded;
    } else if (robot.soc > 30) {
      return Icons.battery_2_bar_rounded;
    } else if (robot.soc > 20) {
      return Icons.battery_1_bar_rounded;
    } else {
      return Icons.battery_0_bar_rounded;
    }
  }

  Color _createBatteryColor(BuildContext context) {
    if (robot.soc < 20) {
      return const Color.fromARGB(255, 206, 36, 23);
    } else if (robot.soc < 30) {
      return const Color.fromARGB(255, 178, 161, 4);
    } else {
      return Theme.of(context).colorScheme.primary;
    }
  }

  Color _createRtkColor(BuildContext context) {
    if (robot.rtkSolution == 'invalid') {
      return const Color.fromARGB(255, 206, 36, 23);
    } else if (robot.rtkSolution == 'float') {
      return const Color.fromARGB(255, 178, 161, 4);
    } else {
      return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(
          height: 20,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(
                  Icons.satellite_alt_rounded,
                  size: 30,
                  color: _createRtkColor(context),
                ),
                Column(
                  children: [
                    SizedBox(
                      width: 35,
                      child: Text(
                        '${robot.dgpsSatellites}/${robot.visibleSatellites}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    SizedBox(
                      width: 35,
                      child: Text(
                        robot.rtkAge,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(
              width: 20,
            ),
            Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.rotate(
                      angle: math.pi / 2,
                      child: 
                      Icon(
                        _createBatteryIcon(),
                        size: 35,
                        color: _createBatteryColor(context),
                      ),
                    ),
                    Text(
                      '${robot.soc}%',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                Column(
                  children: [
                    SizedBox(
                      width: 35,
                      child: Text(
                        '${robot.voltage}V',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    SizedBox(
                      width: 35,
                      child: Text(
                        '${robot.current}A',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        const SizedBox(
          height: 20,
        ),
      ],
    );
  }
}
