import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:cassandra_native/models/server.dart';
import 'package:cassandra_native/components/common/dismiss_item.dart';
import 'package:cassandra_native/components/common/customized_elevated_button.dart';
import 'package:cassandra_native/components/mapping_page/map_item.dart';

class MapsOverview extends StatefulWidget {
  final Server server;

  const MapsOverview({
    super.key,
    required this.server,
  });

  @override
  State<MapsOverview> createState() => _MapsOverviewState();
}

class _MapsOverviewState extends State<MapsOverview> {
  List<String> sortedMapNames = [];

  @override
  void initState() {
    sortedMapNames = widget.server.maps.available.map((item) => item.toString()).toList();
    sortedMapNames.sort((a, b) => a.compareTo(b));
    super.initState();
  }
  void onNewMapSelected() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SingleChildScrollView(
          child: SizedBox(
            width: double.maxFinite,
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.vertical,
              itemCount: sortedMapNames.length,
              itemBuilder: (context, index) {
                final map = sortedMapNames[index];
                return Dismissible(
                  key: Key(map),
                  background: const DismissItem(),
                  onDismissed: (direction) {
                    widget.server.serverInterface.commandRemoveMap([map]);
                    if (widget.server.maps.selected == map) {
                      widget.server.maps.resetSelection();
                    }
                  },
                  child: MapItem(
                    mapName: map,
                    server: widget.server,
                    onNewMapSelected: onNewMapSelected,
                  ).animate().fadeIn().scale(),
                );
              },
            ),
          ),
        ),
        SizedBox(
          height: 8,
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: CustomizedElevatedButton(
            text: 'ok',
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
      ],
    );
  }
}
