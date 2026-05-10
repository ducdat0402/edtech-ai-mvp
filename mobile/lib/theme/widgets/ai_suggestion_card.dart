import 'package:flutter/material.dart';
import '../semantic_colors.dart';
import '../text_styles.dart';

/// Card "AI gợi ý ví dụ thực tế" với border gradient + ribbon tím + mascot tròn.
///
/// Hỗ trợ 2 trạng thái:
/// - `placeholder` (Bạn còn N lượt tạo… + nút CTA "Tạo ví dụ")
/// - `content` (đoạn ví dụ đã sinh ra)
class AiSuggestionCard extends StatelessWidget {
  const AiSuggestionCard({
    super.key,
    required this.title,
    required this.body,
    this.cta,
    this.onCta,
    this.mascotIcon = Icons.smart_toy_rounded,
  });

  final String title;
  final Widget body;
  final String? cta;
  final VoidCallback? onCta;
  final IconData mascotIcon;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    final onGold = Theme.of(context).colorScheme.onSecondary;
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: tokens.aiGradient,
    );

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: tokens.aiGradient.last.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(2),
      child: Container(
        decoration: BoxDecoration(
          color: tokens.card,
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 24),
                    child: Text(
                      title,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: tokens.textOnBrand,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: -6,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: gradient,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: tokens.card, width: 2),
                    ),
                    child:
                        Icon(mascotIcon, color: tokens.textOnBrand, size: 22),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DefaultTextStyle(
              style: AppTextStyles.bodyMedium.copyWith(
                color: tokens.textPrimary,
                height: 1.5,
              ),
              child: body,
            ),
            if (cta != null) ...[
              const SizedBox(height: 12),
              Material(
                color: tokens.gold,
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                  onTap: onCta,
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome_rounded,
                            color: onGold, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          cta!,
                          style: AppTextStyles.labelLarge.copyWith(
                            color: onGold,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
