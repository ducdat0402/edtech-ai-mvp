import 'package:flutter/material.dart';
import 'colors.dart';

/// Gamified Learning App - Typography System
/// 
/// Font Families:
/// - Orbitron: Gaming style headers
/// - Exo2: Gaming body text  
/// - Inter: Numbers, stats, UI elements
class AppTextStyles {
  AppTextStyles._();

  // ═══════════════════════════════════════════════════════════════════
  // FONT FAMILIES
  // ═══════════════════════════════════════════════════════════════════
  static const String fontHeading = 'Orbitron';
  static const String fontBody = 'Exo2';
  static const String fontUI = 'Inter';

  // ═══════════════════════════════════════════════════════════════════
  // HEADERS (Orbitron - Gaming Style)
  // ═══════════════════════════════════════════════════════════════════
  
  static const TextStyle h1 = TextStyle(
    fontFamily: fontHeading,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: 1.2,
    height: 1.2,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: fontHeading,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: 1.0,
    height: 1.3,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: fontHeading,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.8,
    height: 1.3,
  );

  static const TextStyle h4 = TextStyle(
    fontFamily: fontHeading,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.6,
    height: 1.3,
  );

  // ═══════════════════════════════════════════════════════════════════
  // BODY TEXT (Exo2)
  // ═══════════════════════════════════════════════════════════════════
  
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontBody,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontBody,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontBody,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
    height: 1.4,
  );

  static const TextStyle bodyBold = TextStyle(
    fontFamily: fontBody,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  // ═══════════════════════════════════════════════════════════════════
  // UI LABELS (Inter)
  // ═══════════════════════════════════════════════════════════════════
  
  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontUI,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontUI,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontUI,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.textTertiary,
    letterSpacing: 0.5,
  );

  // ═══════════════════════════════════════════════════════════════════
  // NUMBERS (Inter - for XP, Coins, Level)
  // ═══════════════════════════════════════════════════════════════════
  
  static const TextStyle numberXLarge = TextStyle(
    fontFamily: fontUI,
    fontSize: 48,
    fontWeight: FontWeight.w800,
    color: AppColors.xpGold,
    letterSpacing: -1.0,
  );

  static const TextStyle numberLarge = TextStyle(
    fontFamily: fontUI,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.xpGold,
    letterSpacing: -0.5,
  );

  static const TextStyle numberMedium = TextStyle(
    fontFamily: fontUI,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  static const TextStyle numberSmall = TextStyle(
    fontFamily: fontUI,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );

  // ═══════════════════════════════════════════════════════════════════
  // SPECIAL STYLES
  // ═══════════════════════════════════════════════════════════════════
  
  /// Level display (large, bold)
  static const TextStyle levelDisplay = TextStyle(
    fontFamily: fontUI,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  /// XP display with gold color
  static const TextStyle xpDisplay = TextStyle(
    fontFamily: fontUI,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.xpGold,
    letterSpacing: -0.3,
  );

  /// Coin display with gold color
  static const TextStyle coinDisplay = TextStyle(
    fontFamily: fontUI,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.coinGold,
    letterSpacing: -0.2,
  );

  /// Streak display
  static const TextStyle streakDisplay = TextStyle(
    fontFamily: fontUI,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
  );

  /// Button text (uppercase, spaced)
  static const TextStyle button = TextStyle(
    fontFamily: fontUI,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 1.0,
  );

  /// Caption/disclaimer text
  static const TextStyle caption = TextStyle(
    fontFamily: fontBody,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
    height: 1.4,
  );

  // ═══════════════════════════════════════════════════════════════════
  // GRADIENT TEXT HELPER
  // ═══════════════════════════════════════════════════════════════════
  
  /// Helper to create gradient text
  static Widget gradientText(String text, TextStyle style, Gradient gradient) {
    return ShaderMask(
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(
        text,
        style: style.copyWith(color: Colors.white),
      ),
    );
  }
}
