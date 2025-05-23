import 'package:cassandra_native/pages/stream_page.dart';
import 'package:flutter/material.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';

import 'package:cassandra_native/models/server.dart';
import 'package:cassandra_native/pages/home_page.dart';
import 'package:cassandra_native/components/servers_page/rtsp_stream.dart';
import 'package:cassandra_native/components/common/buttons/customized_elevated_icon_button.dart';

class ServerItem extends StatelessWidget {
  final Server server;
  final Color serverItemColor;
  final void Function() onRemoveServer;
  final void Function() openEditServer;
  final void Function(Server) selectServer;
  final void Function() onRestartServer;
  final void Function() onShutdownServer;

  const ServerItem({
    super.key,
    required this.server,
    required this.serverItemColor,
    required this.onRemoveServer,
    required this.openEditServer,
    required this.selectServer,
    required this.onRestartServer,
    required this.onShutdownServer,
  });

  void _navigateTo(Widget page, BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => page,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: serverItemColor,
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(10),
      width: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: GestureDetector(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    width: double.infinity,
                    //padding: const EdgeInsets.all(5),
                    child: Stack(
                      children: [
                        Center(
                          child: server.rtspUrl == null
                              ? Image.asset(
                                  categoryImages[server.category]!.elementAt(0))
                              : AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: RtspStream(
                                    rtspUrl: server.rtspUrl!,
                                  ),
                                ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(
                              width: 5,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  server.robot.firmware != ''
                                      ? '${server.robot.firmware}: ${server.robot.version}'
                                      : server.robot.firmware,
                                  style: Theme.of(context).textTheme.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  server.cpuTemp != null &&
                                          server.cpuLoad != null &&
                                          server.memUsage != null &&
                                          server.hddUsage != null
                                      ? 'CPU: ${server.cpuLoad!.toInt()}% ${server.cpuTemp!.toInt()}°C MEM: ${server.memUsage!.toInt()}% HDD: ${server.hddUsage!.toInt()}%'
                                      : '',
                                  style: Theme.of(context).textTheme.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                            Expanded(
                              child: SizedBox.shrink(),
                            ),
                            Text(
                              server.software != ''
                                  ? '${server.software}: ${server.version}'
                                  : server.software,
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(
                              width: 5,
                            ),
                          ],
                        ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: IconButton(
                            color: Theme.of(context).colorScheme.primary,
                            onPressed: () {
                              selectServer(server);
                              //Scaffold.of(context).openEndDrawer();
                            },
                            icon: const Icon(BootstrapIcons.joystick),
                          ),
                        ),
                      ],
                    ),
                  ),
                  onLongPress: () {
                    if (server.rtspUrl != null) {
                      _navigateTo(
                        StreamPage(server: server),
                        context,
                      );
                    }
                  },
                  onTap: () => _navigateTo(
                    HomePage(server: server),
                    context,
                  ),
                ),
              ),
              const SizedBox(
                height: 25,
              ),
              Center(
                child: Column(
                  children: [
                    Text(
                      server.alias,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      server.id,
                      style: const TextStyle(fontSize: 8),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 25,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("server: "),
                  Text(
                    server.status,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("robot: "),
                  Text(
                    server.robot.status,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomizedElevatedIconButton(
                icon: BootstrapIcons.power,
                isActive: false,
                onPressed: onShutdownServer,
              ),
              CustomizedElevatedIconButton(
                icon: BootstrapIcons.bootstrap_reboot,
                isActive: false,
                onPressed: onRestartServer,
              ),
              CustomizedElevatedIconButton(
                isActive: false,
                icon: Icons.edit,
                onPressed: openEditServer,
              ),
              CustomizedElevatedIconButton(
                isActive: false,
                icon: Icons.delete,
                onPressed: onRemoveServer,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
