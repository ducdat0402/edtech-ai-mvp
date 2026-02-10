import 'package:flutter/material.dart';

/// Stub widget - old content system removed
class WebVideoPlayer extends StatelessWidget {
  final String url;
  final double? height;

  const WebVideoPlayer({super.key, required this.url, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? 200,
      color: Colors.black12,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.video_library, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            Text(url, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
