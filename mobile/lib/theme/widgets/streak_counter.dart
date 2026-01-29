import 'package:flutter/material.dart';
import '../colors.dart';
import '../gradients.dart';
import '../text_styles.dart';

/// Streak counter with fire effect
class StreakCounter extends StatelessWidget {
  final int streak;
  final bool showLabel;
  final bool compact;

  const StreakCounter({
    super.key,
    required this.streak,
    this.showLabel = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompact();
    }
    return _buildFull();
  }

  Widget _buildFull() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: AppGradients.streak,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.streakOrange.withOpacity(0.5),
            blurRadius: 16,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$streak',
                style: AppTextStyles.numberMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (showLabel)
                Text(
                  streak == 1 ? 'DAY' : 'DAYS',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompact() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: AppGradients.streak,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.streakOrange.withOpacity(0.4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            '$streak',
            style: AppTextStyles.labelMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Large streak display for profile/dashboard
class StreakDisplay extends StatelessWidget {
  final int streak;
  final int? maxStreak;

  const StreakDisplay({
    super.key,
    required this.streak,
    this.maxStreak,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.streakOrange.withOpacity(0.2),
            AppColors.streakYellow.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.streakOrange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Fire icon with glow
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.streak,
              boxShadow: [
                BoxShadow(
                  color: AppColors.streakOrange.withOpacity(0.6),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Center(
              child: Text('🔥', style: TextStyle(fontSize: 40)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '$streak',
            style: AppTextStyles.h1.copyWith(
              fontSize: 48,
              color: AppColors.streakYellow,
            ),
          ),
          Text(
            streak == 1 ? 'Day Streak' : 'Days Streak',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (maxStreak != null && maxStreak! > streak) ...[
            const SizedBox(height: 8),
            Text(
              'Best: $maxStreak days',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
