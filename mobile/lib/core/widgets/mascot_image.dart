import 'package:flutter/material.dart';

/// Raster mascot with alpha (no white matte). Replaces legacy SVG+embedded-PNG assets.
enum MascotKind {
  idle,
  happy,
  sad,
  celebrating,
}

class MascotImage extends StatelessWidget {
  const MascotImage(
    this.kind, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.filterQuality = FilterQuality.high,
  });

  final MascotKind kind;
  final double? width;
  final double? height;
  final BoxFit fit;
  final FilterQuality filterQuality;

  static String assetPath(MascotKind k) {
    switch (k) {
      case MascotKind.idle:
        return 'assets/mascot/idle.png';
      case MascotKind.happy:
        return 'assets/mascot/happy.png';
      case MascotKind.sad:
        return 'assets/mascot/sad.png';
      case MascotKind.celebrating:
        return 'assets/mascot/celebrating.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath(kind),
      width: width,
      height: height,
      fit: fit,
      filterQuality: filterQuality,
      gaplessPlayback: true,
    );
  }
}
