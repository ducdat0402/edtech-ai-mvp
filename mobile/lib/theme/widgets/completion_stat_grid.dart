import 'package:flutter/material.dart';
import '../semantic_colors.dart';
import '../text_styles.dart';

/// Lưới 2x2 thống kê cuối bài (mockup TV-02 "Hoàn thành bài học!").
class CompletionStatGrid extends StatelessWidget {
  const CompletionStatGrid({super.key, required this.items});

  final List<CompletionStatItem> items;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.6,
      children: items.map((e) => _StatCard(item: e)).toList(),
    );
  }
}

class CompletionStatItem {
  const CompletionStatItem({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? color;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.item});
  final CompletionStatItem item;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    final color = item.color ?? tokens.brand;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.border),
        boxShadow: [
          BoxShadow(
            color: tokens.shadowColor,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(item.icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                item.label,
                style: AppTextStyles.labelLarge.copyWith(
                  color: tokens.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Text(
            item.value,
            style: AppTextStyles.h2.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
