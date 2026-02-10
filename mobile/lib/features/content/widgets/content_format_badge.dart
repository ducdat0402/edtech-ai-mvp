import 'package:flutter/material.dart';

/// Stub widget - old content system removed
class ContentFormatBadge extends StatelessWidget {
  final String format;

  const ContentFormatBadge({super.key, required this.format});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(format, style: const TextStyle(fontSize: 10)),
    );
  }
}
