import 'package:flutter/material.dart';
import 'package:edtech_mobile/theme/theme.dart';

class AiGeneratedNotice extends StatelessWidget {
  const AiGeneratedNotice({
    super.key,
    required this.visible,
    this.compact = false,
  });

  final bool visible;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.warningNeon.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.warningNeon.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 16, color: AppColors.warningNeon),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Dữ liệu này được AI tạo ra, có thể còn sai sót. Hãy đóng góp để cộng đồng lớn mạnh thêm.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
                fontSize: compact ? 11 : 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
