import 'package:flutter/material.dart';
import 'package:edtech_mobile/theme/theme.dart';

/// Phase 2: show mastery + ITS hint from `/ai-agents/mastery` + `/ai-agents/its/adjust-difficulty`.
class AiLearningInsightCard extends StatelessWidget {
  final int? masteryPercentage;
  final String? suggestedDifficulty;
  final String? reason;
  final bool? shouldSkip;

  const AiLearningInsightCard({
    super.key,
    this.masteryPercentage,
    this.suggestedDifficulty,
    this.reason,
    this.shouldSkip,
  });

  static String difficultyLabelVi(String code) {
    switch (code.toLowerCase()) {
      case 'easy':
        return 'Dễ';
      case 'medium':
        return 'Trung bình';
      case 'hard':
        return 'Khó';
      case 'expert':
        return 'Chuyên sâu';
      default:
        return code;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasMastery = masteryPercentage != null;
    final hasIts = (reason != null && reason!.isNotEmpty) ||
        (suggestedDifficulty != null && suggestedDifficulty!.isNotEmpty);
    final skip = shouldSkip == true;

    if (!hasMastery && !hasIts && !skip) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.purpleNeon.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology_outlined,
                  color: AppColors.purpleNeon, size: 22),
              const SizedBox(width: 8),
              Text(
                'Gợi ý học tập (AI)',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (hasMastery) ...[
            const SizedBox(height: 10),
            Text(
              'Mức nắm vững ước lượng: $masteryPercentage%',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
          if (skip) ...[
            const SizedBox(height: 8),
            Text(
              'Bạn có thể đã nắm vững phần lớn nội dung này — có thể ôn nhanh hoặc chuyển bài tiếp theo.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.successNeon),
            ),
          ],
          if (suggestedDifficulty != null && suggestedDifficulty!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Độ khó gợi ý: ${difficultyLabelVi(suggestedDifficulty!)}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (reason != null && reason!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              reason!,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textTertiary, height: 1.35),
            ),
          ],
        ],
      ),
    );
  }
}
