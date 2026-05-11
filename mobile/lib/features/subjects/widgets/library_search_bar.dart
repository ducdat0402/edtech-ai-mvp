import 'package:flutter/material.dart';
import 'package:edtech_mobile/theme/theme.dart';

class LibrarySearchBar extends StatelessWidget {
  const LibrarySearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    this.hintText = 'Tìm kiếm môn học',
    this.semantics,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;

  /// Khi non-null (vd. contributor trên theme sáng), dùng palette này thay [BuildContext.colors].
  final SemanticColors? semantics;

  @override
  Widget build(BuildContext context) {
    final sem = semantics ?? context.colors;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          style: AppTextStyles.bodyMedium.copyWith(color: sem.textPrimary),
          cursorColor: sem.brand,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AppTextStyles.bodySmall.copyWith(
              color: sem.textSecondary.withValues(alpha: 0.9),
            ),
            prefixIcon: Icon(Icons.search_rounded, color: sem.textSecondary),
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Xóa',
                    icon: Icon(Icons.clear_rounded, color: sem.textSecondary),
                    onPressed: () {
                      controller.clear();
                    },
                  ),
            filled: true,
            fillColor: sem.card,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: sem.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: sem.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: sem.brand.withValues(alpha: 0.55)),
            ),
          ),
          textInputAction: TextInputAction.search,
        );
      },
    );
  }
}
