import 'package:flutter/material.dart';
import '../semantic_colors.dart';
import '../text_styles.dart';

/// Card 1 môn học dạng row: avatar/illustration trái, name + meta giữa, CTA phải.
/// Có thể có progress bar gold ở dưới (mockup MT-02).
class SubjectListTile extends StatelessWidget {
  const SubjectListTile({
    super.key,
    required this.name,
    required this.onTap,
    this.subtitle,
    this.leadingIcon,
    this.leadingAsset,
    this.leadingColor,
    this.actionLabel,
    this.progressLabel,
    this.progressValue,
  });

  final String name;
  final String? subtitle;
  final IconData? leadingIcon;
  final String? leadingAsset;
  final Color? leadingColor;
  final String? actionLabel;
  final String? progressLabel;
  final double? progressValue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    final accent = leadingColor ?? tokens.brand;

    return Material(
      color: tokens.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: tokens.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: leadingAsset != null
                      ? Image.asset(
                          leadingAsset!,
                          width: 38,
                          height: 38,
                          fit: BoxFit.contain,
                        )
                      : Icon(
                          leadingIcon ?? Icons.auto_stories_rounded,
                          color: accent,
                          size: 26,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: tokens.textTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (progressValue != null) ...[
                      const SizedBox(height: 8),
                      _SubjectProgress(
                        value: progressValue!,
                        label: progressLabel,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (actionLabel != null)
                _ActionLink(label: actionLabel!, color: tokens.brand)
              else
                Icon(Icons.chevron_right_rounded,
                    color: tokens.textTertiary, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubjectProgress extends StatelessWidget {
  const _SubjectProgress({required this.value, this.label});

  final double value;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: tokens.cardMuted,
              valueColor: AlwaysStoppedAnimation<Color>(tokens.gold),
            ),
          ),
        ),
        if (label != null) ...[
          const SizedBox(width: 8),
          Text(
            label!,
            style: AppTextStyles.bodySmall.copyWith(
              color: tokens.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _ActionLink extends StatelessWidget {
  const _ActionLink({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTextStyles.labelLarge.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 2),
        Icon(Icons.chevron_right_rounded, color: color, size: 18),
      ],
    );
  }
}
