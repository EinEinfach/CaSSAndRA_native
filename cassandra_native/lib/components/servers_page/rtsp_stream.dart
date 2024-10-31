import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

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
  String selectedPlayer = 'media kit';
  late VlcPlayerController _vlcPlayerController;
  late final player = Player();
  late final controller = VideoController(player);

  @override
  void initState() {
    super.initState();
    if (selectedPlayer == 'vlc') {
      _initializeVlcController(widget.rtspUrl);
    } else if (selectedPlayer == 'media kit') {
      _initializeMediaKitController(widget.rtspUrl);
    }
  }

  @override
  void dispose() {
    if (selectedPlayer == 'vlc') {
      _vlcPlayerController.dispose();
    } else if (selectedPlayer == 'media kit') {
      player.dispose();
    }
    super.dispose();
  }

  void _initializeVlcController(String url) {
    _vlcPlayerController = VlcPlayerController.network(
      url,
      hwAcc: HwAcc.full,
      autoPlay: true,
    );
  }

  void _initializeMediaKitController(String url) {
    player.open(Media(widget.rtspUrl));
  }

  @override
  Widget build(BuildContext context) {
    if (selectedPlayer == 'vlc') {
      return VlcPlayer(
        controller: _vlcPlayerController,
        aspectRatio: 16 / 9,
      );
    } else {
      return AspectRatio(
        aspectRatio: 16/9,
        child: Video(
          fill: Theme.of(context).colorScheme.secondary,
          controller: controller,
          controls: null,
        ),
      );
    }
  }
}
