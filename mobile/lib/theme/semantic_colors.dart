import 'package:flutter/material.dart';
import 'colors.dart';

/// Bộ token màu **semantic** dùng theo theme (light/dark).
///
/// Truy cập trong widget bằng `context.colors.brand`, `context.colors.bg`, …
/// Token tự đổi theo `Theme.of(context).brightness` nên screen migrate sang
/// token mới sẽ hoạt động cho cả light & dark mà không cần if/else.
class SemanticColors {
  const SemanticColors({
    required this.bg,
    required this.bgElevated,
    required this.card,
    required this.cardMuted,
    required this.cardOverlay,
    required this.border,
    required this.divider,
    required this.brand,
    required this.brandStrong,
    required this.brandSoft,
    required this.onBrand,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textOnBrand,
    required this.gold,
    required this.goldSoft,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.aiGradient,
    required this.heroGradient,
    required this.shadowColor,
  });

  // Surfaces ----------------------------------------------------------------
  final Color bg;
  final Color bgElevated;
  final Color card;
  final Color cardMuted;
  final Color cardOverlay;

  // Lines -------------------------------------------------------------------
  final Color border;
  final Color divider;

  // Brand -------------------------------------------------------------------
  final Color brand;
  final Color brandStrong;
  final Color brandSoft;
  final Color onBrand;

  // Text --------------------------------------------------------------------
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textOnBrand;

  // Accents -----------------------------------------------------------------
  final Color gold;
  final Color goldSoft;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;

  // Gradients ---------------------------------------------------------------
  final List<Color> aiGradient;
  final List<Color> heroGradient;

  // Misc --------------------------------------------------------------------
  final Color shadowColor;

  // ──────────────────────────────────────────────────────────────────────
  // Presets

  static const SemanticColors light = SemanticColors(
    bg: Color(0xFFF4F1FA),
    bgElevated: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    cardMuted: Color(0xFFF1ECFB),
    cardOverlay: Color(0xFFFAF7FE),
    border: Color(0xFFE7E1F4),
    divider: Color(0xFFEFE9FA),
    brand: Color(0xFF6B46C1),
    brandStrong: Color(0xFF553597),
    brandSoft: Color(0xFFEDE7FA),
    onBrand: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF1F1B2E),
    textSecondary: Color(0xFF534F66),
    textTertiary: Color(0xFF8A859E),
    textOnBrand: Color(0xFFFFFFFF),
    gold: Color(0xFFF4B73B),
    goldSoft: Color(0xFFFFE7A8),
    success: Color(0xFF3DBE7B),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFE5484D),
    info: Color(0xFF5577FF),
    aiGradient: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
    heroGradient: [Color(0xFF6B46C1), Color(0xFF8B5CF6)],
    shadowColor: Color(0x1F1F1B2E),
  );

  static const SemanticColors dark = SemanticColors(
    bg: AppColors.bgPrimary,
    bgElevated: AppColors.bgSecondary,
    card: AppColors.bgSecondary,
    cardMuted: AppColors.bgTertiary,
    cardOverlay: AppColors.bgOverlay,
    border: AppColors.borderPrimary,
    divider: AppColors.borderPrimary,
    brand: AppColors.purpleNeon,
    brandStrong: Color(0xFF553597),
    brandSoft: Color(0x337354F5),
    onBrand: Colors.white,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textTertiary: AppColors.textTertiary,
    textOnBrand: Colors.white,
    gold: AppColors.xpGold,
    goldSoft: Color(0x66FFD647),
    success: AppColors.successNeon,
    warning: AppColors.warningNeon,
    error: AppColors.errorNeon,
    info: AppColors.cyanNeon,
    aiGradient: [Color(0xFF7354F5), Color(0xFF9F8CFF)],
    heroGradient: [Color(0xFF7354F5), Color(0xFFCABEFF)],
    shadowColor: Color(0x66000000),
  );
}

extension SemanticColorsX on BuildContext {
  /// Token màu semantic — tự đổi theo theme.
  SemanticColors get colors {
    final isDark = Theme.of(this).brightness == Brightness.dark;
    return isDark ? SemanticColors.dark : SemanticColors.light;
  }

  /// Helper kiểm tra nhanh dark mode (dùng khi cần asset/icon thay đổi theo theme).
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  // ──────────────────────────────────────────────────────────────────────
  // Aliases tiện cho migrate nhanh từ AppColors.* (giữ tên giống cho DX).
  // VD: `AppColors.bgSecondary` -> `context.bgSecondary`.

  Color get bgPrimary => colors.bg;
  Color get bgSecondary => colors.card;
  Color get bgTertiary => colors.cardMuted;
  Color get bgOverlay => colors.cardOverlay;
  Color get borderPrimary => colors.border;

  Color get textPrimaryColor => colors.textPrimary;
  Color get textSecondaryColor => colors.textSecondary;
  Color get textTertiaryColor => colors.textTertiary;

  Color get brandPurple => colors.brand;
  Color get brandPurpleStrong => colors.brandStrong;
  Color get brandPurpleSoft => colors.brandSoft;
  Color get brandGold => colors.gold;
}
