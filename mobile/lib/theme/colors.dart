import 'package:flutter/material.dart';

/// Gamified Learning App - Cyberpunk Color System
class AppColors {
  AppColors._();

  // ═══════════════════════════════════════════════════════════════════
  // BACKGROUNDS
  // ═══════════════════════════════════════════════════════════════════
  static const Color bgPrimary = Color(0xFF0A0A0A); // Main background
  static const Color bgSecondary =
      Color(0xFF1A1A1A); // Cards, elevated surfaces
  static const Color bgTertiary =
      Color(0xFF252525); // Hover states, active elements
  static const Color bgOverlay = Color(0xFF0F0F0F); // Modals, dialogs

  // ═══════════════════════════════════════════════════════════════════
  // BORDERS & DIVIDERS
  // ═══════════════════════════════════════════════════════════════════
  static const Color borderPrimary = Color(0xFF2A2A2A);
  static const Color borderGlow = Color(0xFF3A3A3A); // With glow effect

  // ═══════════════════════════════════════════════════════════════════
  // NEON COLORS (Primary Gradient)
  // ═══════════════════════════════════════════════════════════════════
  static const Color purpleNeon = Color(0xFF8B5CF6);
  static const Color pinkNeon = Color(0xFFEC4899);
  static const Color orangeNeon = Color(0xFFF59E0B);

  // ═══════════════════════════════════════════════════════════════════
  // ACCENT COLORS
  // ═══════════════════════════════════════════════════════════════════
  static const Color cyanNeon = Color(0xFF06B6D4);
  static const Color cyanGlow = Color(0xFF22D3EE);

  // ═══════════════════════════════════════════════════════════════════
  // FUNCTIONAL COLORS
  // ═══════════════════════════════════════════════════════════════════
  // Success (correct answers, achievements)
  static const Color successNeon = Color(0xFF00FF88);
  static const Color successGlow = Color(0xFF10B981);

  // Error (wrong answers)
  static const Color errorNeon = Color(0xFFFF3366);
  static const Color errorGlow = Color(0xFFEF4444);

  // Warning (energy low, alerts)
  static const Color warningNeon = Color(0xFFFFE31A);
  static const Color warningGlow = Color(0xFFFBBF24);

  // Info
  static const Color infoNeon = Color(0xFF3B82F6);

  // ═══════════════════════════════════════════════════════════════════
  // TEXT COLORS
  // ═══════════════════════════════════════════════════════════════════
  static const Color textPrimary = Color(0xFFFAFAFA); // Main text
  static const Color textSecondary =
      Color(0xFFA3A3A3); // Subtitles, descriptions
  static const Color textTertiary = Color(0xFF737373); // Placeholders, disabled
  static const Color textDisabled = Color(0xFF525252);

  // ═══════════════════════════════════════════════════════════════════
  // ROLE/MODE COLORS
  // ═══════════════════════════════════════════════════════════════════
  static const Color contributorBlue = Color(0xFF2563EB); // Contributor primary
  static const Color contributorBlueDark =
      Color(0xFF1E40AF); // Contributor dark
  static const Color contributorBlueLight =
      Color(0xFF3B82F6); // Contributor light
  static const Color contributorBgPrimary =
      Color(0xFF0A0F1A); // Contributor background
  static const Color contributorBgSecondary =
      Color(0xFF111827); // Contributor cards
  static const Color contributorBorder =
      Color(0xFF1E3A5F); // Contributor borders

  // ═══════════════════════════════════════════════════════════════════
  // GAMIFICATION COLORS
  // ═══════════════════════════════════════════════════════════════════
  // XP & Level System
  static const Color xpGold = Color(0xFFFFD700);
  static const Color xpOrange = Color(0xFFFF6B00);
  static const Color levelUpGlow = Color(0xFFFFE31A);

  // Streak Fire 🔥
  static const Color streakOrange = Color(0xFFFF4500);
  static const Color streakYellow = Color(0xFFFFD700);

  // Coins
  static const Color coinGold = Color(0xFFFFD700);
  static const Color coinShadow = Color(0xFFB8860B);

  // Leaderboard Ranks
  static const Color rankGold = Color(0xFFFFD700); // #1
  static const Color rankSilver = Color(0xFFC0C0C0); // #2
  static const Color rankBronze = Color(0xFFCD7F32); // #3

  // Achievement Rainbow
  static const List<Color> achievementRainbow = [
    Color(0xFFFF00FF), // Magenta
    Color(0xFF8B5CF6), // Purple
    Color(0xFF06B6D4), // Cyan
    Color(0xFF00FF88), // Green
    Color(0xFFFFE31A), // Yellow
  ];

  // ═══════════════════════════════════════════════════════════════════
  // LEVEL TITLE COLORS (matching danh hiệu system)
  // ═══════════════════════════════════════════════════════════════════
  static const Color levelNewbie = Color(0xFF10B981); // Người mới - Green
  static const Color levelStudent = Color(0xFF06B6D4); // Học viên - Cyan
  static const Color levelScholar = Color(0xFF6366F1); // Sinh viên - Indigo
  static const Color levelExpert = Color(0xFF8B5CF6); // Chuyên gia - Purple
  static const Color levelMaster = Color(0xFFF59E0B); // Bậc thầy - Orange
  static const Color levelLegend = Color(0xFFEF4444); // Huyền thoại - Red
  static const Color levelProdigy = Color(0xFFFFD700); // Thần đồng - Gold

  /// Get level color based on level number
  static Color getLevelColor(int level) {
    if (level <= 5) return levelNewbie;
    if (level <= 10) return levelStudent;
    if (level <= 20) return levelScholar;
    if (level <= 35) return levelExpert;
    if (level <= 50) return levelMaster;
    if (level <= 75) return levelLegend;
    return levelProdigy;
  }

  /// Get level gradient based on level number
  static List<Color> getLevelGradient(int level) {
    if (level <= 5) {
      return [levelNewbie, const Color(0xFF059669)];
    } else if (level <= 10) {
      return [levelStudent, const Color(0xFF0891B2)];
    } else if (level <= 20) {
      return [levelScholar, const Color(0xFF4F46E5)];
    } else if (level <= 35) {
      return [levelExpert, const Color(0xFF7C3AED)];
    } else if (level <= 50) {
      return [levelMaster, const Color(0xFFD97706)];
    } else if (level <= 75) {
      return [levelLegend, const Color(0xFFDC2626)];
    } else {
      return [levelProdigy, const Color(0xFFF59E0B)];
    }
  }
}
