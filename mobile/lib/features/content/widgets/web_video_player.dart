import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional import for web vs desktop
import 'web_video_player_web.dart'
    if (dart.library.io) 'web_video_player_desktop.dart';

/// Web video player widget that uses HTML5 video element
class WebVideoPlayer extends StatelessWidget {
  final String videoUrl;
  final double? height;
  final double? width;

  const WebVideoPlayer({
    super.key,
    required this.videoUrl,
    this.height = 200,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // For web, use HtmlElementView
      return buildWebVideoPlayer(videoUrl, height, width);
    } else {
      // For desktop/mobile, use webview to embed HTML5 video
      return buildDesktopVideoPlayer(videoUrl, height, width);
    }
  }
}
