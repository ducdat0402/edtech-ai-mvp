import 'package:flutter/material.dart';
import '../gradients.dart';
import '../semantic_colors.dart';
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
    final t = context.colors;
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
              color: isUnlocked ? null : t.cardMuted,
              boxShadow: isUnlocked
                  ? [
                      BoxShadow(
                        color: t.brand.withValues(alpha: 0.6),
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
                color: isUnlocked ? t.card : t.cardMuted,
              ),
              child: Center(
                child: isUnlocked
                    ? Icon(icon, color: t.textPrimary, size: size * 0.45)
                    : Icon(Icons.lock,
                        color: t.textTertiary, size: size * 0.35),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Title
          Text(
            title,
            style: AppTextStyles.labelMedium.copyWith(
              color: isUnlocked ? t.textPrimary : t.textTertiary,
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
                color: isUnlocked ? t.textSecondary : t.textTertiary,
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
    final t = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked
              ? t.brand.withValues(alpha: 0.5)
              : t.border,
          width: isUnlocked ? 2 : 1,
        ),
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: t.brand.withValues(alpha: 0.2),
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
              color: isUnlocked ? null : t.cardMuted,
            ),
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isUnlocked ? t.card : t.cardMuted,
              ),
              child: Center(
                child: isUnlocked
                    ? Icon(icon, color: t.textPrimary, size: 28)
                    : Icon(Icons.lock, color: t.textTertiary, size: 24),
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
                    color: isUnlocked ? t.textPrimary : t.textSecondary,
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
                      color: t.success,
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
                            backgroundColor: t.cardMuted,
                            valueColor: AlwaysStoppedAnimation(t.brand),
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

  /// Medal accent; ranks 1–3 only show emoji in UI, but kept for consistency.
  Color _accent(SemanticColors t) {
    switch (rank) {
      case 1:
        return t.gold;
      case 2:
        return const Color(0xFFC0C0C0);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return t.textTertiary;
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

    final t = context.colors;
    final accent = _accent(t);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: t.cardMuted,
        border: Border.all(color: accent, width: 2),
      ),
      child: Center(
        child: Text(
          '#$rank',
          style: AppTextStyles.labelSmall.copyWith(
            color: accent,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
