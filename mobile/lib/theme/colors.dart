import 'package:flutter/material.dart';

/// Gamistu — "Luminal Scholar" palette (`mobile/DESIGN.md`).
/// Giữ tên biến cũ (`bgPrimary`, `purpleNeon`, …) để tránh phá widget hiện có.
class AppColors {
  AppColors._();

  // ═══ Surfaces (graphite / obsidian — không dùng #000) ═══
  static const Color bgPrimary = Color(0xFF0B141B); // surface
  static const Color bgSecondary = Color(0xFF182127); // surface_container
  static const Color bgTertiary = Color(0xFF222B32); // surface_container_high
  static const Color bgOverlay = Color(0xFF060F16); // surface_container_lowest
  /// Khối nội dung lồng nhẹ (lesson card / vùng đệm)
  static const Color surfaceContainerLow = Color(0xFF101920);

  // ═══ Viền — ưu tiên tonal; dùng ghost khi cần ranh giới ═══
  static const Color borderPrimary =
      Color(0xFF2D363D); // surface_container_highest (lift)
  static const Color outlineVariant = Color(0xFF474554);
  static const Color borderGlow = Color(0xFF3A3A5A);

  // ═══ Brand — violet lạnh (gradient CTA: #7354f5 → #cabeff) ═══
  static const Color purpleNeon =
      Color(0xFF7354F5); // primary_container / solid CTA
  static const Color primaryLight = Color(0xFFCABEFF); // primary (gradient end)
  static const Color pinkNeon =
      Color(0xFF9F8CFF); // accent phụ (giữ slot gradient)
  static const Color orangeNeon = Color(0xFFFFD647); // gần secondary gold

  // ═══ Accent chức năng ═══
  static const Color cyanNeon =
      Color(0xFF8B9CFF); // link / outline thay cyan neon cũ
  static const Color cyanGlow = Color(0xFFCABEFF);

  // Success / XP (tertiary trong DESIGN)
  static const Color successNeon = Color(0xFF41E184);
  static const Color successGlow = Color(0xFF34D399);

  static const Color errorNeon = Color(0xFFFF4D6A);
  static const Color errorGlow = Color(0xFFEF4444);

  static const Color warningNeon = Color(0xFFFFD647);
  static const Color warningGlow = Color(0xFFFBBF24);

  static const Color infoNeon = Color(0xFF7354F5);

  // ═══ Text ═══
  static const Color textPrimary = Color(0xFFF4F4F5);
  static const Color textSecondary =
      Color(0xFFC8C4D7); // on_surface_variant — body dài
  static const Color textTertiary = Color(0xFF8E8A9A);
  static const Color textDisabled = Color(0xFF5C5866);

  // ═══ Contributor mode (giữ tông tối, hài hòa graphite) ═══
  static const Color contributorBlue = Color(0xFF2563EB);
  static const Color contributorBlueDark = Color(0xFF1E40AF);
  static const Color contributorBlueLight = Color(0xFF3B82F6);
  static const Color contributorBgPrimary = Color(0xFF0A1218);
  static const Color contributorBgSecondary = Color(0xFF152028);
  static const Color contributorBorder = Color(0xFF1E3A5F);

  // ═══ Gamification ═══
  static const Color xpGold =
      Color(0xFFFFD647); // secondary gold (coin / highlight)
  static const Color xpOrange = Color(0xFFF59E0B);
  static const Color levelUpGlow = Color(0xFFFFD647);

  static const Color streakOrange = Color(0xFFFF6B35);
  static const Color streakYellow = Color(0xFFFFD647);

  static const Color coinGold = Color(0xFFFFD647);
  static const Color coinShadow = Color(0xFFB45309);

  static const Color rankGold = Color(0xFFFFD647);
  static const Color rankSilver = Color(0xFFC0C0C0);
  static const Color rankBronze = Color(0xFFCD7F32);

  static const List<Color> achievementRainbow = [
    Color(0xFFEC4899),
    Color(0xFF7354F5),
    Color(0xFF41E184),
    Color(0xFFFFD647),
    Color(0xFF38BDF8),
  ];

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

  /// Gradient bậc đã hạ bão hòa — dùng thanh profile / LevelCard (khớp dialog danh hiệu).
  static List<Color> getLevelGradientMuted(int level) {
    return getLevelGradient(level).map(tierAccentMuted).toList();
  }

  /// Hạ bão hòa màu bậc so với nền graphite (dialog danh hiệu — phương án A).
  static Color tierAccentMuted(Color tier) =>
      Color.lerp(tier, bgSecondary, 0.45)!;

  /// Icon theo bậc: hàng hiện tại rõ hơn; hàng khóa gợn tier nhưng không chói.
  static Color tierIconTint(Color tier, {required bool isCurrent}) {
    final m = tierAccentMuted(tier);
    if (isCurrent) return m;
    return Color.lerp(m, textTertiary, 0.42)!;
  }
}
