import 'package:flutter/material.dart';
import 'colors.dart';

/// Gamified Learning App - Gradient System
class AppGradients {
  AppGradients._();

  // ═══════════════════════════════════════════════════════════════════
  // PRIMARY GRADIENTS
  // ═══════════════════════════════════════════════════════════════════
  
  /// Main gradient (Purple → Pink → Orange)
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.purpleNeon,
      AppColors.pinkNeon,
      AppColors.orangeNeon,
    ],
  );

  /// Purple to Pink gradient
  static const LinearGradient purplePink = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.purpleNeon,
      AppColors.pinkNeon,
    ],
  );

  /// Pink to Orange gradient
  static const LinearGradient pinkOrange = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.pinkNeon,
      AppColors.orangeNeon,
    ],
  );

  // ═══════════════════════════════════════════════════════════════════
  // XP & PROGRESS GRADIENTS
  // ═══════════════════════════════════════════════════════════════════
  
  /// XP bar gradient (Gold → Orange)
  static const LinearGradient xpBar = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      AppColors.xpGold,
      AppColors.xpOrange,
    ],
  );

  /// Level up glow gradient
  static const RadialGradient levelUp = RadialGradient(
    colors: [
      AppColors.levelUpGlow,
      Colors.transparent,
    ],
  );

  // ═══════════════════════════════════════════════════════════════════
  // STREAK GRADIENTS
  // ═══════════════════════════════════════════════════════════════════
  
  /// Streak fire gradient
  static const LinearGradient streak = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.streakOrange,
      AppColors.streakYellow,
    ],
  );

  // ═══════════════════════════════════════════════════════════════════
  // COIN GRADIENTS
  // ═══════════════════════════════════════════════════════════════════
  
  /// Coin gradient
  static const RadialGradient coin = RadialGradient(
    colors: [
      AppColors.coinGold,
      AppColors.coinShadow,
    ],
  );

  // ═══════════════════════════════════════════════════════════════════
  // ACHIEVEMENT GRADIENTS
  // ═══════════════════════════════════════════════════════════════════
  
  /// Rainbow sweep gradient for achievements
  static const SweepGradient achievementRainbow = SweepGradient(
    colors: [
      Color(0xFFFF00FF),  // Magenta
      Color(0xFF8B5CF6),  // Purple
      Color(0xFF06B6D4),  // Cyan
      Color(0xFF00FF88),  // Green
      Color(0xFFFFE31A),  // Yellow
      Color(0xFFFF00FF),  // Magenta (close loop)
    ],
  );

  // ═══════════════════════════════════════════════════════════════════
  // FUNCTIONAL GRADIENTS
  // ═══════════════════════════════════════════════════════════════════
  
  /// Success gradient
  static const LinearGradient success = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.successNeon,
      AppColors.successGlow,
    ],
  );

  /// Error gradient
  static const LinearGradient error = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.errorNeon,
      AppColors.errorGlow,
    ],
  );

  /// Warning gradient
  static const LinearGradient warning = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.warningNeon,
      AppColors.warningGlow,
    ],
  );

  /// Cyan accent gradient
  static const LinearGradient cyan = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.cyanNeon,
      AppColors.cyanGlow,
    ],
  );

  // ═══════════════════════════════════════════════════════════════════
  // ROLE/MODE GRADIENTS
  // ═══════════════════════════════════════════════════════════════════

  /// Contributor mode gradient (Blue)
  static const LinearGradient contributor = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.contributorBlue,
      AppColors.contributorBlueLight,
    ],
  );

  // ═══════════════════════════════════════════════════════════════════
  // CARD/SURFACE GRADIENTS
  // ═══════════════════════════════════════════════════════════════════
  
  /// Glass card gradient (subtle)
  static LinearGradient glassCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.bgSecondary.withOpacity(0.6),
      AppColors.bgSecondary.withOpacity(0.3),
    ],
  );

  /// Dark overlay gradient
  static const LinearGradient darkOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.transparent,
      AppColors.bgPrimary,
    ],
  );

  // ═══════════════════════════════════════════════════════════════════
  // LEVEL GRADIENTS
  // ═══════════════════════════════════════════════════════════════════
  
  /// Get gradient based on level
  static LinearGradient forLevel(int level) {
    final colors = AppColors.getLevelGradient(level);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    );
  }
}
