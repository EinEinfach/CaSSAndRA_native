import 'package:flutter/material.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';

import 'package:cassandra_native/models/server.dart';
import 'package:cassandra_native/components/home_page/map_button.dart';

class MapItem extends StatefulWidget {
  final String mapName;
  final Server server;
  final VoidCallback onNewMapSelected;

  const MapItem({
    super.key,
    required this.mapName,
    required this.server,
    required this.onNewMapSelected,
  });

  @override
  State<MapItem> createState() => _MapItemState();
}

class _MapItemState extends State<MapItem> {
  final TextEditingController _mapRenameController = TextEditingController();
  bool _mapRename = false;
  late String _mapName;

  @override
  void initState() {
    _mapName = widget.mapName;
    _mapRenameController.text = widget.mapName;
    super.initState();
  }

  @override
  void dispose() {
    _mapRenameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_mapName != widget.server.maps.selected) {
          widget.server.maps.selected = _mapName;
          widget.server.serverInterface.commandSelectMap([_mapName]);
        } else {
          widget.server.maps.selected = '';
          widget.server.serverInterface.commandSelectMap([]);
        }
        widget.onNewMapSelected();
      },
      child: Container(
        decoration: BoxDecoration(
          color: widget.server.maps.selected == _mapName
              ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
              : Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        height: 40,
        margin: const EdgeInsets.all(2),
        //padding: const EdgeInsets.fromLTRB(20, 5, 5, 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: _mapRename
                  ? Container(
                    padding: EdgeInsets.all(2),
                    child: TextField(
                        controller: _mapRenameController,
                        style: Theme.of(context).textTheme.bodyMedium,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.secondary,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none),
                        ),
                      ),
                  )
                  : Container(
                    padding: EdgeInsets.fromLTRB(9, 0, 0, 0),
                    child: Text(
                        style: Theme.of(context).textTheme.bodyMedium,
                        _mapName,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                  ),
            ),
            Row(
              children: [
                SizedBox(
                  width: 8,
                ),
                MapButton(
                  icon: BootstrapIcons.cloud_arrow_down,
                  isActive: false,
                  onPressed: () {
                    widget.server.serverInterface.commandLoadMap([_mapName]);
                  },
                ),
                MapButton(
                  icon: BootstrapIcons.copy,
                  isActive: false,
                  onPressed: () {},
                ),
                MapButton(
                    icon: BootstrapIcons.pencil_square,
                    isActive: _mapRename,
                    onPressed: () {
                      if (_mapRename && _mapName != _mapRenameController.text) {
                        widget.server.serverInterface.commandRenameMap([_mapName, _mapRenameController.text]);
                        _mapName = _mapRenameController.text;
                      }
                      _mapRename = !_mapRename;
                      setState(() {});
                    }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// class MapItem extends StatelessWidget {
//   final String mapName;
//   final Server server;
//   final VoidCallback onNewMapSelected;

//   const MapItem({
//     super.key,
//     required this.mapName,
//     required this.server,
//     required this.onNewMapSelected,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () {
//         if (mapName != server.maps.selected) {
//           server.maps.selected = mapName;
//           server.serverInterface.commandSelectMap([mapName]);
//         } else {
//           server.maps.selected = '';
//           server.serverInterface.commandSelectMap([]);
//         }
//         onNewMapSelected();
//       },
//       child: Container(
//         decoration: BoxDecoration(
//           color: server.maps.selected == mapName
//               ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
//               : Theme.of(context).colorScheme.primary,
//           borderRadius: BorderRadius.circular(8),
//         ),
//         height: 40,
//         margin: const EdgeInsets.all(2),
//         padding: const EdgeInsets.fromLTRB(20, 5, 5, 5),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             Flexible(
//               child: Text(
//                 mapName,
//                 overflow: TextOverflow.ellipsis,
//                 maxLines: 1,
//               ),
//             ),
//             Expanded(
//               child: SizedBox.shrink(),
//             ),
//             Row(
//               children: [
//                 MapButton(
//                   icon: BootstrapIcons.cloud_arrow_down,
//                   isActive: false,
//                   onPressed: () {},
//                 ),
//                 MapButton(
//                   icon: BootstrapIcons.copy,
//                   isActive: false,
//                   onPressed: () {},
//                 ),
//                 MapButton(
//                   icon: BootstrapIcons.pencil_square,
//                   isActive: false,
//                   onPressed: () {},
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
