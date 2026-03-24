import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:edtech_mobile/theme/colors.dart';

/// Hàng nút **Quay lại** + **Trang chủ** (dashboard) trên AppBar.
///
/// - Nếu có thể pop (Navigator hoặc GoRouter) → hiện nút back.
/// - Nút **Trang chủ** luôn gọi [GoRouter.go] tới `/dashboard` (trừ khi [onHome] tùy chỉnh).
/// - Dùng với `leadingWidth: 112`, `automaticallyImplyLeading: false`.
class AppBarLeadingBackAndHome extends StatelessWidget {
  const AppBarLeadingBackAndHome({
    super.key,
    this.onBack,
    this.onHome,
    this.showHome = true,
    this.iconColor,
  });

  final VoidCallback? onBack;
  final VoidCallback? onHome;
  final bool showHome;
  /// Mặc định [AppColors.textPrimary]; dùng khi AppBar nền sáng.
  final Color? iconColor;

  void _defaultBack(BuildContext context) {
    if (onBack != null) {
      onBack!();
      return;
    }
    final nav = Navigator.of(context);
    final go = GoRouter.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else if (go.canPop()) {
      go.pop();
    }
  }

  void _defaultHome(BuildContext context) {
    if (onHome != null) {
      onHome!();
    } else {
      GoRouter.of(context).go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final nav = Navigator.of(context);
    final go = GoRouter.of(context);
    final showBack = nav.canPop() || go.canPop();
    final c = iconColor ?? AppColors.textPrimary;

    if (!showHome && !showBack) {
      return const SizedBox.shrink();
    }

    if (!showHome && showBack) {
      return IconButton(
        icon: Icon(Icons.arrow_back_rounded, color: c),
        onPressed: () => _defaultBack(context),
        tooltip: 'Quay lại',
      );
    }

    return SizedBox(
      width: showBack ? 112 : 56,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showBack)
            IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: c),
              onPressed: () => _defaultBack(context),
              tooltip: 'Quay lại',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            ),
          if (showHome)
            IconButton(
              icon: Icon(Icons.home_rounded, color: c),
              onPressed: () => _defaultHome(context),
              tooltip: 'Trang chủ',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            ),
        ],
      ),
    );
  }
}
