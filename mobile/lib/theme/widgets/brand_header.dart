import 'package:flutter/material.dart';
import '../semantic_colors.dart';
import '../text_styles.dart';

/// Header gradient purple đậm theo mockup Gamistu (Homepage / TV-01 / MT-02 / TV-05).
///
/// Dùng làm `flexibleSpace` cho `SliverAppBar`, hoặc `bottomSheet` cho AppBar
/// mà cần "kéo dài" gradient xuống.
class BrandHeader extends StatelessWidget {
  const BrandHeader({
    super.key,
    required this.child,
    this.height,
    this.bottomCornerRadius = 28,
    this.padding,
  });

  final Widget child;
  final double? height;
  final double bottomCornerRadius;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;

    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: tokens.heroGradient,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(bottomCornerRadius),
          bottomRight: Radius.circular(bottomCornerRadius),
        ),
      ),
      padding: padding ?? const EdgeInsets.fromLTRB(20, 16, 20, 22),
      child: child,
    );
  }
}

/// AppBar trong suốt + tiêu đề trắng — dùng đè lên `BrandHeader`.
class BrandTransparentAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const BrandTransparentAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.centerTitle = true,
  });

  final String? title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool centerTitle;

  @override
  Widget build(BuildContext context) {
    final sem = context.colors;
    return AppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      foregroundColor: sem.textOnBrand,
      iconTheme: IconThemeData(color: sem.textOnBrand),
      actionsIconTheme: IconThemeData(color: sem.textOnBrand),
      leading: leading,
      actions: actions,
      centerTitle: centerTitle,
      title: title == null
          ? null
          : Text(
              title!,
              style: AppTextStyles.h4.copyWith(
                color: sem.textOnBrand,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
