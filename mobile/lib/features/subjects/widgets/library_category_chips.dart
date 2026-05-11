import 'package:flutter/material.dart';
import 'package:edtech_mobile/features/subjects/widgets/library_ui_constants.dart';
import 'package:edtech_mobile/theme/theme.dart';

class LibraryCategoryChips extends StatelessWidget {
  const LibraryCategoryChips({
    super.key,
    required this.presentSlugs,
    required this.selected,
    required this.onSelected,
  });

  /// Slug đang có ít nhất một môn (không gồm `all`).
  final Set<String> presentSlugs;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final sem = context.colors;
    final ordered = <String>[
      kLibraryCategoryAll,
      ...kLibraryCategoryOrder.where(presentSlugs.contains),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < ordered.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            _Chip(
              label: ordered[i] == kLibraryCategoryAll
                  ? 'Tất cả'
                  : (kLibraryCategoryLabelsVi[ordered[i]] ?? ordered[i]),
              selected: selected == ordered[i],
              onTap: () => onSelected(ordered[i]),
              sem: sem,
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.sem,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final SemanticColors sem;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? sem.brand : sem.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? sem.brand : sem.border,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              color: selected ? sem.textOnBrand : sem.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
