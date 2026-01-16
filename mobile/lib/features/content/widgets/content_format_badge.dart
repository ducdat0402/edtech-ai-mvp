import 'package:flutter/material.dart';

/// Badge widget to display content format (video, image, mixed, quiz, text)
class ContentFormatBadge extends StatelessWidget {
  final String? format;
  final bool compact;

  const ContentFormatBadge({
    super.key,
    required this.format,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (format == null || format!.isEmpty) {
      return const SizedBox.shrink();
    }

    final formatData = _getFormatData(format!);
    if (formatData == null) {
      return const SizedBox.shrink();
    }

    if (compact) {
      return Tooltip(
        message: formatData['label'] as String,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: formatData['color'] as Color,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            formatData['icon'] as IconData,
            size: 14,
            color: Colors.white,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: formatData['color'] as Color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            formatData['icon'] as IconData,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            formatData['label'] as String,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic>? _getFormatData(String format) {
    switch (format.toLowerCase()) {
      case 'video':
        return {
          'label': 'Video',
          'icon': Icons.videocam,
          'color': Colors.red.shade600,
        };
      case 'image':
        return {
          'label': 'Hình ảnh',
          'icon': Icons.image,
          'color': Colors.blue.shade600,
        };
      case 'mixed':
        return {
          'label': 'Hỗn hợp',
          'icon': Icons.auto_awesome,
          'color': Colors.purple.shade600,
        };
      case 'quiz':
        return {
          'label': 'Quiz',
          'icon': Icons.quiz,
          'color': Colors.orange.shade600,
        };
      case 'text':
        return {
          'label': 'Văn bản',
          'icon': Icons.article,
          'color': Colors.grey.shade600,
        };
      default:
        return null;
    }
  }
}

