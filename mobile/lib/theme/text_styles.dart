import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

/// Typography: Outfit (tiêu đề) + Be Vietnam Pro (nội dung tiếng Việt).
/// Dùng GoogleFonts thay vì `fontFamily` chuỗi để font thực sự được tải và hiển thị đúng dấu.
class AppTextStyles {
  AppTextStyles._();

  static const String fontHeading = 'Outfit';
  static const String fontBody = 'Be Vietnam Pro';
  static const String fontUI = 'Be Vietnam Pro';

  // ─── Headings (Outfit) ─────────────────────────────────────────────
  static TextStyle get h1 => GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 0.3,
        height: 1.2,
      );

  static TextStyle get h2 => GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 0.25,
        height: 1.3,
      );

  static TextStyle get h3 => GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.2,
        height: 1.3,
      );

  static TextStyle get h4 => GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.15,
        height: 1.3,
      );

  // ─── Body (Be Vietnam Pro) ─────────────────────────────────────────
  static TextStyle get bodyLarge => GoogleFonts.beVietnamPro(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  static TextStyle get bodyMedium => GoogleFonts.beVietnamPro(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.5,
      );

  static TextStyle get bodySmall => GoogleFonts.beVietnamPro(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textTertiary,
        height: 1.45,
      );

  static TextStyle get bodyBold => GoogleFonts.beVietnamPro(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  // ─── Labels ────────────────────────────────────────────────────────
  static TextStyle get labelLarge => GoogleFonts.beVietnamPro(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.2,
      );

  static TextStyle get labelMedium => GoogleFonts.beVietnamPro(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        letterSpacing: 0.15,
      );

  static TextStyle get labelSmall => GoogleFonts.beVietnamPro(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppColors.textTertiary,
        letterSpacing: 0.1,
      );

  // ─── Numbers / thống kê (cùng Be Vietnam Pro, đậm hơn) ───────────────
  static TextStyle get numberXLarge => GoogleFonts.beVietnamPro(
        fontSize: 48,
        fontWeight: FontWeight.w800,
        color: AppColors.xpGold,
        letterSpacing: -0.5,
      );

  static TextStyle get numberLarge => GoogleFonts.beVietnamPro(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.xpGold,
        letterSpacing: -0.3,
      );

  static TextStyle get numberMedium => GoogleFonts.beVietnamPro(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: -0.15,
      );

  static TextStyle get numberSmall => GoogleFonts.beVietnamPro(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: -0.1,
      );

  static TextStyle get levelDisplay => GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get xpDisplay => GoogleFonts.beVietnamPro(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.xpGold,
        letterSpacing: -0.15,
      );

  static TextStyle get coinDisplay => GoogleFonts.beVietnamPro(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.coinGold,
        letterSpacing: -0.1,
      );

  static TextStyle get streakDisplay => GoogleFonts.beVietnamPro(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 0.2,
      );

  static TextStyle get button => GoogleFonts.beVietnamPro(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.3,
      );

  static TextStyle get caption => GoogleFonts.beVietnamPro(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: AppColors.textTertiary,
        height: 1.4,
      );

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
