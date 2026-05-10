import 'package:flutter/material.dart';
import '../semantic_colors.dart';
import '../text_styles.dart';

/// Tab toggle 2 mục với icon + label dạng pill (mockup TV-01 / MT-02).
///
/// Dùng cho cặp `Học tập / Đóng góp`, `Đang học / Đóng góp`, …
class SectionTabSwitcher extends StatelessWidget {
  const SectionTabSwitcher({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
    this.height = 92,
  });

  final List<SectionTabItem> tabs;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final double height;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var i = 0; i < tabs.length; i++) ...[
            Expanded(
              child: _TabSlot(
                item: tabs[i],
                selected: selectedIndex == i,
                tokens: tokens,
                onTap: () => onChanged(i),
              ),
            ),
            if (i != tabs.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class SectionTabItem {
  const SectionTabItem({
    required this.label,
    this.icon,
    this.iconAsset,
  });

  final String label;
  final IconData? icon;
  final String? iconAsset;
}

class _TabSlot extends StatelessWidget {
  const _TabSlot({
    required this.item,
    required this.selected,
    required this.tokens,
    required this.onTap,
  });

  final SectionTabItem item;
  final bool selected;
  final SemanticColors tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor = tokens.gold;
    final inactiveColor = tokens.textOnBrand.withValues(alpha: 0.85);
    final on = tokens.textOnBrand;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: selected
                    ? on.withValues(alpha: 0.18)
                    : on.withValues(alpha: 0.10),
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? activeColor.withValues(alpha: 0.85)
                      : on.withValues(alpha: 0.18),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: item.iconAsset != null
                    ? Image.asset(
                        item.iconAsset!,
                        width: 30,
                        height: 30,
                        fit: BoxFit.contain,
                      )
                    : Icon(
                        item.icon ?? Icons.bookmark_rounded,
                        color: selected ? activeColor : inactiveColor,
                        size: 28,
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item.label,
              style: AppTextStyles.labelLarge.copyWith(
                color: selected ? activeColor : inactiveColor,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
