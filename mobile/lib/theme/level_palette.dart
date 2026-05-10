import 'package:flutter/material.dart';

/// Màu / gradient theo bậc level (Gamistu). Không phụ thuộc light/dark;
/// blend với surface qua [tierAccentMuted] / [tierIconTint].
class LevelPalette {
  LevelPalette._();

  static const Color levelNewbie = Color(0xFF41E184);
  static const Color levelStudent = Color(0xFF38BDF8);
  static const Color levelScholar = Color(0xFF6366F1);
  static const Color levelExpert = Color(0xFF7354F5);
  static const Color levelMaster = Color(0xFFF59E0B);
  static const Color levelLegend = Color(0xFFEF4444);
  static const Color levelProdigy = Color(0xFFFFD647);

  static Color getLevelColor(int level) {
    if (level <= 5) return levelNewbie;
    if (level <= 10) return levelStudent;
    if (level <= 20) return levelScholar;
    if (level <= 35) return levelExpert;
    if (level <= 50) return levelMaster;
    if (level <= 75) return levelLegend;
    return levelProdigy;
  }

  static List<Color> getLevelGradient(int level) {
    if (level <= 5) {
      return [levelNewbie, const Color(0xFF22C55E)];
    } else if (level <= 10) {
      return [levelStudent, const Color(0xFF0EA5E9)];
    } else if (level <= 20) {
      return [levelScholar, const Color(0xFF4F46E5)];
    } else if (level <= 35) {
      return [levelExpert, const Color(0xFF5B21B6)];
    } else if (level <= 50) {
      return [levelMaster, const Color(0xFFD97706)];
    } else if (level <= 75) {
      return [levelLegend, const Color(0xFFDC2626)];
    } else {
      return [levelProdigy, const Color(0xFFF59E0B)];
    }
  }

  /// Gradient bậc đã hạ bão hòa — blend về [towardSurface] (vd. `context.colors.card`).
  static List<Color> getLevelGradientMuted(int level, Color towardSurface) {
    return getLevelGradient(level)
        .map((c) => tierAccentMuted(c, towardSurface))
        .toList();
  }

  static Color tierAccentMuted(Color tier, Color towardSurface) =>
      Color.lerp(tier, towardSurface, 0.45)!;

  /// Icon theo bậc: hàng hiện tại rõ hơn; hàng khóa gợn tier nhưng không chói.
  static Color tierIconTint(
    Color tier, {
    required bool isCurrent,
    required Color towardSurface,
    required Color mutedText,
  }) {
    final m = tierAccentMuted(tier, towardSurface);
    if (isCurrent) return m;
    return Color.lerp(m, mutedText, 0.42)!;
  }
}
