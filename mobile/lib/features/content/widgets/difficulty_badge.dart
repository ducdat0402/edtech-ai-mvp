import 'package:flutter/material.dart';

/// Badge widget to display difficulty level (easy, medium, hard, expert)
class DifficultyBadge extends StatelessWidget {
  final String? difficulty;
  final bool compact;

  const DifficultyBadge({
    super.key,
    required this.difficulty,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (difficulty == null || difficulty!.isEmpty) {
      return const SizedBox.shrink();
    }

    final difficultyData = _getDifficultyData(difficulty!);
    if (difficultyData == null) {
      return const SizedBox.shrink();
    }

    if (compact) {
      return Tooltip(
        message: difficultyData['label'] as String,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: difficultyData['color'] as Color,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            difficultyData['icon'] as IconData,
            size: 14,
            color: Colors.white,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: difficultyData['color'] as Color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            difficultyData['icon'] as IconData,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            difficultyData['label'] as String,
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

  Map<String, dynamic>? _getDifficultyData(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return {
          'label': 'Dễ',
          'icon': Icons.trending_down,
          'color': Colors.green.shade600,
        };
      case 'medium':
        return {
          'label': 'Trung bình',
          'icon': Icons.remove,
          'color': Colors.blue.shade600,
        };
      case 'hard':
        return {
          'label': 'Khó',
          'icon': Icons.trending_up,
          'color': Colors.orange.shade600,
        };
      case 'expert':
        return {
          'label': 'Chuyên gia',
          'icon': Icons.star,
          'color': Colors.red.shade600,
        };
      default:
        return null;
    }
  }
}

