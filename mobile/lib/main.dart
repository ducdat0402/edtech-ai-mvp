import 'package:flutter/material.dart';
import 'package:edtech_mobile/app/app.dart';
import 'package:media_kit/media_kit.dart';

void main() {
  // Initialize MediaKit for desktop video playback
  MediaKit.ensureInitialized();
  runApp(const EdTechApp());
}
