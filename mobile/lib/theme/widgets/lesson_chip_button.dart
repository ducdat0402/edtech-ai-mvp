import 'package:flutter/material.dart';
import '../semantic_colors.dart';
import '../text_styles.dart';

/// Pill chip có icon + label, dùng cho hàng `Tóm tắt / Chia sẻ / Ghi chú` (TV-03).
class LessonChipButton extends StatelessWidget {
  const LessonChipButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.dense = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    final padding = dense
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
        : const EdgeInsets.symmetric(horizontal: 16, vertical: 10);

    return Material(
      color: tokens.card,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: tokens.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: tokens.textSecondary, size: dense ? 16 : 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.labelLarge.copyWith(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: dense ? 12 : 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pill nav nhỏ "Bài trước / Bài tiếp" ở footer (TV-03).
class LessonNavPill extends StatelessWidget {
  const LessonNavPill({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.iconRight = false,
    this.enabled = true,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool iconRight;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    final bg = enabled ? tokens.brand : tokens.cardMuted;
    final fg = enabled ? tokens.onBrand : tokens.textTertiary;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!iconRight) ...[
                Icon(icon, color: fg, size: 18),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: AppTextStyles.labelLarge.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (iconRight) ...[
                const SizedBox(width: 8),
                Icon(icon, color: fg, size: 18),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
