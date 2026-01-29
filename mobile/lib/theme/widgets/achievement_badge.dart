import 'package:flutter/material.dart';
import '../colors.dart';
import '../gradients.dart';
import '../text_styles.dart';

/// Achievement badge with rainbow glow effect
class AchievementBadge extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool isUnlocked;
  final double size;
  final VoidCallback? onTap;

  const AchievementBadge({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.isUnlocked = false,
    this.size = 80,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Badge circle
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isUnlocked ? AppGradients.achievementRainbow : null,
              color: isUnlocked ? null : AppColors.bgTertiary,
              boxShadow: isUnlocked
                  ? [
                      BoxShadow(
                        color: AppColors.purpleNeon.withOpacity(0.6),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Container(
              margin: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isUnlocked ? AppColors.bgSecondary : AppColors.bgTertiary,
              ),
              child: Center(
                child: isUnlocked
                    ? Icon(icon, color: Colors.white, size: size * 0.45)
                    : Icon(Icons.lock, color: AppColors.textDisabled, size: size * 0.35),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Title
          Text(
            title,
            style: AppTextStyles.labelMedium.copyWith(
              color: isUnlocked ? AppColors.textPrimary : AppColors.textTertiary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: AppTextStyles.caption.copyWith(
                color: isUnlocked ? AppColors.textSecondary : AppColors.textDisabled,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Large achievement card for detail view
class AchievementCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isUnlocked;
  final String? unlockedDate;
  final double? progress;
  final int? current;
  final int? target;

  const AchievementCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.isUnlocked = false,
    this.unlockedDate,
    this.progress,
    this.current,
    this.target,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked ? AppColors.purpleNeon.withOpacity(0.5) : AppColors.borderPrimary,
          width: isUnlocked ? 2 : 1,
        ),
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: AppColors.purpleNeon.withOpacity(0.2),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Badge
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isUnlocked ? AppGradients.achievementRainbow : null,
              color: isUnlocked ? null : AppColors.bgTertiary,
            ),
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isUnlocked ? AppColors.bgSecondary : AppColors.bgTertiary,
              ),
              child: Center(
                child: isUnlocked
                    ? Icon(icon, color: Colors.white, size: 28)
                    : Icon(Icons.lock, color: AppColors.textDisabled, size: 24),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyBold.copyWith(
                    color: isUnlocked ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTextStyles.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isUnlocked && unlockedDate != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Unlocked $unlockedDate',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.successGlow,
                    ),
                  ),
                ],
                if (!isUnlocked && progress != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: AppColors.bgTertiary,
                            valueColor: AlwaysStoppedAnimation(AppColors.purpleNeon),
                            minHeight: 4,
                          ),
                        ),
                      ),
                      if (current != null && target != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '$current/$target',
                          style: AppTextStyles.labelSmall,
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Rank badge (Gold, Silver, Bronze)
class RankBadge extends StatelessWidget {
  final int rank;
  final double size;

  const RankBadge({
    super.key,
    required this.rank,
    this.size = 40,
  });

  Color get _color {
    switch (rank) {
      case 1:
        return AppColors.rankGold;
      case 2:
        return AppColors.rankSilver;
      case 3:
        return AppColors.rankBronze;
      default:
        return AppColors.textTertiary;
    }
  }

  String get _emoji {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '#$rank';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (rank <= 3) {
      return Text(_emoji, style: TextStyle(fontSize: size * 0.7));
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.bgTertiary,
        border: Border.all(color: _color, width: 2),
      ),
      child: Center(
        child: Text(
          '#$rank',
          style: AppTextStyles.labelSmall.copyWith(
            color: _color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
