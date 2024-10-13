import 'package:flutter/material.dart';

import 'package:cassandra_native/models/server.dart';
import 'package:cassandra_native/components/home_page/logic/home_page_logic.dart';

class StatusWindow extends StatelessWidget {
  final Color backgroundColor;
  final Server server;
  final bool smallSize;
  const StatusWindow(
      {super.key,
      required this.backgroundColor,
      required this.server,
      required this.smallSize});

  // build status window
  Widget _buildStatusWindow(BuildContext context) {
    final StatusWindowLogic statusWindowLogic =
        StatusWindowLogic(currentServer: server);
    if (smallSize) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor.withOpacity(0.90),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          minimumSize: const Size(80, 80),
          padding: const EdgeInsets.fromLTRB(0, 8, 16, 8),
        ),
        onPressed: () {},
        onLongPress: () {},
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'State',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    server.robot.status,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
            ),
            const SizedBox(
              width: 8,
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Total',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  statusWindowLogic.totalSqm,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                Text(
                  'Estimated',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  statusWindowLogic.uiEstimationTime,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor.withOpacity(0.90),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          minimumSize: const Size(80, 80),
          padding: const EdgeInsets.fromLTRB(0, 8, 12, 8),
        ),
        onPressed: () {},
        onLongPress: () {},
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'State',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    server.robot.status,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
            ),
            const SizedBox(
              width: 8,
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Total',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  statusWindowLogic.totalSqm,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
            const SizedBox(
              width: 9,
            ),
            Column(
              children: [
                Text(
                  'Estimated',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  statusWindowLogic.uiEstimationTime,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                Text(
                  'Duration',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '${statusWindowLogic.duration}h',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
            const SizedBox(
              width: 8,
            ),
            Column(
              children: [
                Text(
                  'Distance',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '${server.currentMap.distancePercent}%',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                Text(
                  'Index',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '${server.currentMap.idxPercent}%',
                  style: Theme.of(context).textTheme.labelLarge,
                )
              ],
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildStatusWindow(context);
  }
}
