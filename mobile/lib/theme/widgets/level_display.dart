import 'package:flutter/material.dart';
import '../colors.dart';
import '../gradients.dart';
import '../text_styles.dart';

/// Level badge with gradient based on level
class LevelBadge extends StatelessWidget {
  final int level;
  final double size;
  final bool showLabel;

  const LevelBadge({
    super.key,
    required this.level,
    this.size = 48,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppGradients.forLevel(level),
            boxShadow: [
              BoxShadow(
                color: AppColors.getLevelColor(level).withOpacity(0.5),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Text(
              '$level',
              style: TextStyle(
                fontFamily: AppTextStyles.fontUI,
                fontSize: size * 0.45,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: 4),
          Text(
            'LEVEL',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.getLevelColor(level),
            ),
          ),
        ],
      ],
    );
  }
}

/// Level card with title and progress
class LevelCard extends StatelessWidget {
  final int level;
  final String title;
  final int currentXP;
  final int xpForNextLevel;
  final int totalXP;

  const LevelCard({
    super.key,
    required this.level,
    required this.title,
    required this.currentXP,
    required this.xpForNextLevel,
    required this.totalXP,
  });

  double get progress => xpForNextLevel > 0 ? (currentXP / xpForNextLevel).clamp(0.0, 1.0) : 0.0;
  Color get levelColor => AppColors.getLevelColor(level);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppGradients.forLevel(level),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: levelColor.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Level circle
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$level',
                        style: AppTextStyles.levelDisplay.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Level',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$totalXP XP',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: AppTextStyles.h3.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Progress bar
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Level ${level + 1}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    '$currentXP / $xpForNextLevel',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Stack(
                children: [
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.5),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${(progress * 100).toStringAsFixed(1)}%',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Level title with color
class LevelTitle extends StatelessWidget {
  final int level;
  final String title;
  final bool showIcon;

  const LevelTitle({
    super.key,
    required this.level,
    required this.title,
    this.showIcon = true,
  });

  IconData get _icon {
    if (level <= 5) return Icons.emoji_people;
    if (level <= 10) return Icons.school;
    if (level <= 20) return Icons.menu_book;
    if (level <= 35) return Icons.psychology;
    if (level <= 50) return Icons.workspace_premium;
    if (level <= 75) return Icons.auto_awesome;
    return Icons.diamond;
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.getLevelColor(level);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showIcon) ...[
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_icon, color: color, size: 18),
          ),
          const SizedBox(width: 8),
        ],
        Text(
          title,
          style: AppTextStyles.bodyBold.copyWith(color: color),
        ),
      ],
    );
  }
}
