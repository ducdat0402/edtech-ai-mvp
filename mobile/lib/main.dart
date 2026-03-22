import 'package:flutter/material.dart';
import 'package:edtech_mobile/app/app.dart';
import 'package:edtech_mobile/core/services/ai_user_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AiUserPreferences.instance.load();
  runApp(const EdTechApp());
}
