import 'package:flutter/material.dart';
import '../semantic_colors.dart';
import '../text_styles.dart';

/// Hàng 4 chip nhỏ tròn ở Dashboard (đã đăng / streak / xp / gem) — mockup Homepage.
class StatPillRow extends StatelessWidget {
  const StatPillRow({super.key, required this.items, this.spacing = 10});

  final List<StatPillItem> items;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Expanded(child: _StatPill(item: items[i])),
          if (i != items.length - 1) SizedBox(width: spacing),
        ],
      ],
    );
  }
}

class StatPillItem {
  const StatPillItem({
    required this.value,
    required this.icon,
    this.color,
    this.iconAsset,
  });

  final String value;
  final IconData icon;
  final Color? color;
  final String? iconAsset;
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.item});
  final StatPillItem item;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    final color = item.color ?? tokens.brand;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tokens.border),
        boxShadow: [
          BoxShadow(
            color: tokens.shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          item.iconAsset != null
              ? Image.asset(item.iconAsset!,
                  width: 18, height: 18, fit: BoxFit.contain)
              : Icon(item.icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(
            item.value,
            style: AppTextStyles.labelLarge.copyWith(
              color: tokens.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
