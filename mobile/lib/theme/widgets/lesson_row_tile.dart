import 'package:flutter/material.dart';
import '../semantic_colors.dart';
import '../text_styles.dart';

enum LessonRowStatus { done, current, locked, pending }

enum LessonRowType { reading, quiz, video, image, gallery, other }

/// Row 1 bài học trong "Danh sách bài học" (TV-05).
/// - Trạng thái icon tròn bên trái (green check / play purple / lock vàng …).
/// - Pill loại bài (Đọc / Quiz / Video) bên phải.
class LessonRowTile extends StatelessWidget {
  const LessonRowTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.type,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final LessonRowStatus status;
  final LessonRowType type;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    final isCurrent = status == LessonRowStatus.current;

    return Material(
      color: tokens.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCurrent
                  ? tokens.brand.withValues(alpha: 0.6)
                  : tokens.border,
              width: isCurrent ? 1.4 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _StatusBubble(status: status, type: type),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: tokens.textTertiary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _TypePill(type: type, isCurrent: isCurrent),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBubble extends StatelessWidget {
  const _StatusBubble({required this.status, required this.type});

  final LessonRowStatus status;
  final LessonRowType type;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;

    Color bg;
    Color fg;
    IconData icon;
    switch (status) {
      case LessonRowStatus.done:
        bg = tokens.success.withValues(alpha: 0.16);
        fg = tokens.success;
        icon = Icons.check_rounded;
        break;
      case LessonRowStatus.current:
        bg = tokens.brand.withValues(alpha: 0.16);
        fg = tokens.brand;
        icon = Icons.play_arrow_rounded;
        break;
      case LessonRowStatus.locked:
        bg = tokens.cardMuted;
        fg = tokens.textTertiary;
        icon = Icons.lock_rounded;
        break;
      case LessonRowStatus.pending:
        bg = tokens.gold.withValues(alpha: 0.18);
        fg = tokens.gold;
        icon = _typeIcon(type);
        break;
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: fg, size: 20),
    );
  }
}

class _TypePill extends StatelessWidget {
  const _TypePill({required this.type, required this.isCurrent});

  final LessonRowType type;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(context, type);
    final isPrimaryStyle = isCurrent && type != LessonRowType.reading;
    final bg = isPrimaryStyle ? color : color.withValues(alpha: 0.16);
    final fg = isPrimaryStyle ? context.colors.textOnBrand : color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: isPrimaryStyle
            ? null
            : Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        _typeLabel(type),
        style: AppTextStyles.labelLarge.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

IconData _typeIcon(LessonRowType type) {
  switch (type) {
    case LessonRowType.reading:
      return Icons.menu_book_rounded;
    case LessonRowType.quiz:
      return Icons.bolt_rounded;
    case LessonRowType.video:
      return Icons.play_circle_fill_rounded;
    case LessonRowType.image:
    case LessonRowType.gallery:
      return Icons.image_rounded;
    case LessonRowType.other:
      return Icons.extension_rounded;
  }
}

String _typeLabel(LessonRowType type) {
  switch (type) {
    case LessonRowType.reading:
      return 'Đọc';
    case LessonRowType.quiz:
      return 'Quiz';
    case LessonRowType.video:
      return 'Video';
    case LessonRowType.image:
      return 'Ảnh';
    case LessonRowType.gallery:
      return 'Gallery';
    case LessonRowType.other:
      return 'Khác';
  }
}

Color _typeColor(BuildContext context, LessonRowType type) {
  final tokens = context.colors;
  switch (type) {
    case LessonRowType.reading:
      return tokens.gold;
    case LessonRowType.quiz:
      return const Color(0xFFF59E0B);
    case LessonRowType.video:
      return tokens.brand;
    case LessonRowType.image:
    case LessonRowType.gallery:
      return tokens.info;
    case LessonRowType.other:
      return tokens.textTertiary;
  }
}
