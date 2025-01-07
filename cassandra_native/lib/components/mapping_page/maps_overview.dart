import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:cassandra_native/models/server.dart';
import 'package:cassandra_native/components/common/dismiss_item.dart';
import 'package:cassandra_native/components/common/buttons/customized_elevated_button.dart';
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
    _sortMaps();
    super.initState();
  }

  void _sortMaps() {
    sortedMapNames =
        widget.server.maps.available.map((item) => item.toString()).toList();
    sortedMapNames.sort((a, b) => a.compareTo(b));
  }

  void onNewMapSelected() {
    setState(() {});
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Column(
  //     mainAxisSize: MainAxisSize.min,
  //     children: [
  //       ConstrainedBox(
  //         constraints: BoxConstraints(
  //           maxHeight: 100,
  //           minHeight: 200,
  //           minWidth: double.maxFinite,
  //         ),
  //         child: SizedBox.shrink(
  //           child: ListView.builder(
  //             shrinkWrap: true,
  //             scrollDirection: Axis.vertical,
  //             itemCount: sortedMapNames.length,
  //             itemBuilder: (context, index) {
  //               final map = sortedMapNames[index];
  //               return Dismissible(
  //                 key: Key(map),
  //                 background: const DismissItem(),
  //                 onDismissed: (direction) {
  //                   widget.server.serverInterface.commandRemoveMap([map]);
  //                   if (widget.server.maps.selected == map) {
  //                     widget.server.maps.resetSelection();
  //                   }
  //                   widget.server.maps.available.remove(map);
  //                   _sortMaps();
  //                   setState(() {});
  //                 },
  //                 child: MapItem(
  //                   mapName: map,
  //                   server: widget.server,
  //                   onNewMapSelected: onNewMapSelected,
  //                 ).animate().fadeIn().scale(),
  //               );
  //             },
  //           ),
  //         ),
  //       ),
  //       SizedBox(
  //         height: 8,
  //       ),
  //       Align(
  //         alignment: Alignment.bottomRight,
  //         child: CustomizedElevatedButton(
  //           text: 'ok',
  //           onPressed: () {
  //             Navigator.pop(context);
  //           },
  //         ),
  //       ),
  //     ],
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    int dialogHeight = 50;
    if (sortedMapNames.length > 1 && sortedMapNames.length < 6) {
      dialogHeight = sortedMapNames.length * 45;
    } else if (sortedMapNames.length >= 6) {
      dialogHeight = 6*45;
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.maxFinite,
          height: dialogHeight.toDouble(),
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
                  widget.server.maps.available.remove(map);
                  _sortMaps();
                  setState(() {});
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
