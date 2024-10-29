import 'package:flutter/material.dart';
//import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
//import 'package:media_kit/media_kit.dart';
//import 'package:media_kit_video/media_kit_video.dart';

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
  late VlcPlayerController _vlcPlayerController;

  @override
  void initState() {
    super.initState();
    _initializeVlcController(widget.rtspUrl);
  }

  @override
  void dispose() {
    _vlcPlayerController.dispose();
    super.dispose();
  }

  void _initializeVlcController(String url) {
    _vlcPlayerController = VlcPlayerController.network(
      url,
      hwAcc: HwAcc.full,
      autoPlay: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return VlcPlayer(
      controller: _vlcPlayerController,
      aspectRatio: 16 / 9,
    );
  }
  // @override
  // void initState() {
  //   super.initState();
  //   BetterPlayerDataSource dataSource = BetterPlayerDataSource(
  //     liveStream: true,
  //     BetterPlayerDataSourceType.network,
  //     widget.rtspUrl,
  //     bufferingConfiguration: BetterPlayerBufferingConfiguration(
  //         minBufferMs: 5000, maxBufferMs: 10000),
  //   );
  //   _betterPlayerController = BetterPlayerController(
  //       BetterPlayerConfiguration(autoPlay: true),
  //       betterPlayerDataSource: dataSource);
  // }

  // @override
  // void dispose() {
  //   _betterPlayerController.dispose();
  //   super.dispose();
  // }

  // @override
  // Widget build(BuildContext context) {
  //   return BetterPlayer(controller: _betterPlayerController);
  // }

  /* Example with media_kit */
  // late final player = Player();
  // late final controller = VideoController(player);

  // @override
  // void initState() {
  //   super.initState();
  //   player.open(Media(widget.rtspUrl));
  // }

  // @override
  // void dispose() {
  //   player.dispose();
  //   super.dispose();
  // }

  // @override
  // Widget build(BuildContext context) {
  //   return Video(controller: controller);
  // }

  /* Example with flutter_vlc_player */
  // late VlcPlayerController _vlcPlayerController;

  // @override
  // void initState() {
  //   super.initState();
  //   _initializeVlcController(widget.rtspUrl);
  // }

  // @override
  // void dispose() {
  //   _vlcPlayerController.dispose();
  //   super.dispose();
  // }

  // void _initializeVlcController(String url) {
  //   _vlcPlayerController = VlcPlayerController.network(
  //     url,
  //     hwAcc: HwAcc.full,
  //     autoPlay: true,
  //   );
  // }

  // @override
  // Widget build(BuildContext context) {
  //   return VlcPlayer(
  //     controller: _vlcPlayerController,
  //     aspectRatio: 16 / 9,
  //   );
  // }
}
