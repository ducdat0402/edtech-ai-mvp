import 'package:flutter/material.dart';

Widget buildWebVideoPlayer(String videoUrl, double? height, double? width) {
  return Container(
    height: height,
    width: width ?? double.infinity,
    color: Colors.black,
    child: const Center(
      child: Text(
        'Video player không khả dụng trên platform này',
        style: TextStyle(color: Colors.white70),
      ),
    ),
  );
}

Widget buildDesktopVideoPlayer(String videoUrl, double? height, double? width) {
  return Container(
    height: height,
    width: width ?? double.infinity,
    color: Colors.black,
    child: const Center(
      child: Text(
        'Video player không khả dụng trên platform này',
        style: TextStyle(color: Colors.white70),
      ),
    ),
  );
}

