import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'package:cassandra_native/cassandra_native.dart';

class RtspStream extends StatefulWidget {
  final String rtspUrl;
  const RtspStream({
    super.key,
    required this.rtspUrl,
  });

  @override
  State<RtspStream> createState() => _RtspStreamState();
}

class _RtspStreamState extends State<RtspStream> {
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;
  late final player = Player();
  late final controller = VideoController(player);

  @override
  void initState() {
    super.initState();
    _initializeMediaKitController(widget.rtspUrl);
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  void _handleAppLifecycleState(
      AppLifecycleState oldState, AppLifecycleState newState) {
    if (newState == AppLifecycleState.resumed &&
        oldState != AppLifecycleState.resumed) {
      _initializeMediaKitController(widget.rtspUrl);
    }
  }

  void _initializeMediaKitController(String url) {
    player.open(Media(widget.rtspUrl));
  }

  @override
  Widget build(BuildContext context) {
    
    _handleAppLifecycleState(_appLifecycleState,
        Provider.of<CassandraNative>(context).appLifecycleState);
    _appLifecycleState =
        Provider.of<CassandraNative>(context).appLifecycleState;

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Video(
        fill: Theme.of(context).colorScheme.secondary,
        controller: controller,
        controls: null,
      ),
    );
  }
}
