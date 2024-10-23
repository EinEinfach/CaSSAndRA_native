import 'package:flutter/material.dart';

import 'package:cassandra_native/models/server.dart';
import 'package:cassandra_native/components/home_page/logic/home_page_logic.dart';

class StatusWindow extends StatelessWidget {
  final Color backgroundColor;
  final Server server;
  final bool smallSize;
  final void Function() onPressed;

  const StatusWindow({
    super.key,
    required this.backgroundColor,
    required this.server,
    required this.smallSize,
    required this.onPressed,
  });

  // build status window
  Widget _buildStatusWindow(BuildContext context) {
    final StatusWindowLogic statusWindowLogic =
        StatusWindowLogic(currentServer: server);
    if (smallSize) {
      // ------------------------widget for small screens--------------------------
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor.withOpacity(0.90),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          //fixedSize: const Size(190, 80),
          //minimumSize: const Size(80, 80),
          //padding: const EdgeInsets.fromLTRB(0, 8, 16, 8),
        ),
        onPressed: onPressed,
        onLongPress: () {},
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
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
      // ----------------------widget for wide screens------------------------
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor.withOpacity(0.90),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          //fixedSize: const Size(350, 160),
          padding: const EdgeInsets.fromLTRB(20, 5, 10, 5),
        ),
        onPressed: onPressed,
        onLongPress: () {},
        child: Row(
          children: [
            SizedBox(
              width: 80,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    height: 18,
                  ),
                  Text(
                    'State',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    server.robot.status,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const Expanded(
                    child: SizedBox(),
                  ),
                  Text(
                    'Map',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    statusWindowLogic.mapName,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(
                    height: 18,
                  ),
                ],
              ),
            ),
            const Expanded(
              child: SizedBox(),
            ),
            SizedBox(
              width: 120,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Text(
                        'Distance',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        statusWindowLogic.distanceData,
                        style: Theme.of(context).textTheme.labelLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        'Index',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        statusWindowLogic.idxData,
                        style: Theme.of(context).textTheme.labelLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        'Speed',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        statusWindowLogic.speedData,
                        style: Theme.of(context).textTheme.labelLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Expanded(
              child: SizedBox(),
            ),
            SizedBox(
              width: 80,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Text(
                        'Total',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        statusWindowLogic.totalSqm,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ],
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
                    ],
                  ),
                  Column(
                    children: [
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
                ],
              ),
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
