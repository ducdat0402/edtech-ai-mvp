import 'package:flutter/material.dart';
import 'package:edtech_mobile/theme/theme.dart';

/// Phase 3: DRL suggested next node (`GET /ai-agents/drl/next-node`).
class DrlNextNodeCard extends StatelessWidget {
  final bool loading;
  final String? nextNodeId;
  final String? nextTitle;
  final double? confidence;
  final String? reason;
  final VoidCallback? onOpen;

  const DrlNextNodeCard({
    super.key,
    required this.loading,
    this.nextNodeId,
    this.nextTitle,
    this.confidence,
    this.reason,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.cyanNeon.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.cyanNeon,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Đang tìm bài học phù hợp tiếp theo…',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (nextNodeId == null || nextNodeId!.isEmpty) {
      return const SizedBox.shrink();
    }

    final confPct = confidence != null
        ? '${(confidence!.clamp(0.0, 1.0) * 100).round()}%'
        : null;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.cyanNeon.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.route_rounded,
                  color: AppColors.cyanNeon, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Lộ trình gợi ý (DRL)',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            nextTitle?.isNotEmpty == true ? nextTitle! : 'Bài học tiếp theo',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (confPct != null) ...[
            const SizedBox(height: 4),
            Text(
              'Độ tin cậy ước lượng: $confPct',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textTertiary),
            ),
          ],
          if (reason != null && reason!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              reason!,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary, height: 1.35),
            ),
          ],
          const SizedBox(height: 12),
          GamingButton(
            text: 'Mở bài gợi ý',
            onPressed: onOpen,
            icon: Icons.open_in_new_rounded,
          ),
        ],
      ),
    );
  }
}
