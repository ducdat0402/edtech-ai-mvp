import 'package:flutter/material.dart';
import '../colors.dart';
import '../gradients.dart';
import '../text_styles.dart';

/// Animated XP progress bar with glow effect
class XPBar extends StatelessWidget {
  final int currentXP;
  final int maxXP;
  final int level;
  final double height;
  final bool showLabels;
  final bool showGlow;

  const XPBar({
    super.key,
    required this.currentXP,
    required this.maxXP,
    required this.level,
    this.height = 8,
    this.showLabels = true,
    this.showGlow = true,
  });

  double get progress => maxXP > 0 ? (currentXP / maxXP).clamp(0.0, 1.0) : 0.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabels) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: AppGradients.forLevel(level),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'LV $level',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$currentXP / $maxXP XP',
                    style: AppTextStyles.labelMedium,
                  ),
                ],
              ),
              Text(
                '${(progress * 100).toStringAsFixed(1)}%',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.xpGold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Stack(
          children: [
            // Background
            Container(
              height: height,
              decoration: BoxDecoration(
                color: AppColors.bgTertiary,
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
            // Progress with gradient and glow
            AnimatedProgressBox(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              widthFactor: progress,
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  gradient: AppGradients.xpBar,
                  borderRadius: BorderRadius.circular(height / 2),
                  boxShadow: showGlow
                      ? [
                          BoxShadow(
                            color: AppColors.xpGold.withOpacity(0.6),
                            blurRadius: 8,
                            spreadRadius: 0,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Mini XP bar for compact displays
class XPBarMini extends StatelessWidget {
  final double progress;
  final double width;
  final double height;

  const XPBarMini({
    super.key,
    required this.progress,
    this.width = 100,
    this.height = 4,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Stack(
        children: [
          Container(
            height: height,
            decoration: BoxDecoration(
              color: AppColors.bgTertiary,
              borderRadius: BorderRadius.circular(height / 2),
            ),
          ),
          FractionallySizedBox(
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              height: height,
              decoration: BoxDecoration(
                gradient: AppGradients.xpBar,
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated fraction box for smooth progress animations
class AnimatedProgressBox extends StatelessWidget {
  final double widthFactor;
  final Duration duration;
  final Curve curve;
  final Widget child;

  const AnimatedProgressBox({
    super.key,
    required this.widthFactor,
    required this.duration,
    required this.curve,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: widthFactor),
      duration: duration,
      curve: curve,
      builder: (context, value, _) {
        return FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: value,
          child: child,
        );
      },
    );
  }
}
