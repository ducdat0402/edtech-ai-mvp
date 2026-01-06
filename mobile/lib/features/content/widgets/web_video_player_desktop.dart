import 'package:flutter/material.dart';

// Conditional import for media_kit (desktop only, not web)
import 'desktop_video_player_media_kit.dart'
    if (dart.library.html) 'desktop_video_player_stub.dart';

Widget buildWebVideoPlayer(String videoUrl, double? height, double? width) {
  // This should not be called on desktop, but provide fallback
  return buildDesktopVideoPlayer(videoUrl, height, width);
}

Widget buildDesktopVideoPlayer(String videoUrl, double? height, double? width) {
  // Use media_kit for desktop video playback (Windows, Linux, macOS)
  return buildMediaKitVideoPlayer(videoUrl, height, width);
}

