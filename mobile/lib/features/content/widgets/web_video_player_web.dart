import 'package:flutter/widgets.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

Widget buildWebVideoPlayer(String videoUrl, double? height, double? width) {
  // Create a unique view ID
  final viewId = 'web-video-player-${DateTime.now().millisecondsSinceEpoch}';
  
  // Register the view factory
  ui_web.platformViewRegistry.registerViewFactory(
    viewId,
    (int viewId) {
      final videoElement = html.VideoElement()
        ..src = videoUrl
        ..autoplay = false
        ..controls = true
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.borderRadius = '8px';
      
      return videoElement;
    },
  );

  return SizedBox(
    height: height,
    width: width ?? double.infinity,
    child: HtmlElementView(viewType: viewId),
  );
}

// For web, desktop player is same as web player
Widget buildDesktopVideoPlayer(String videoUrl, double? height, double? width) {
  return buildWebVideoPlayer(videoUrl, height, width);
}

