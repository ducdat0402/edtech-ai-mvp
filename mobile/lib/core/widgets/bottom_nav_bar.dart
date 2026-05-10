import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/theme/semantic_colors.dart';
import 'package:edtech_mobile/theme/text_styles.dart';

/// Bottom nav theo bộ mockup Gamistu (light) — vẫn hoạt động trong dark mode.
///
/// Tabs:
/// 0. Trang chủ → /dashboard
/// 1. Thư viện → /library
/// 2. Của tôi → /library/my-contributions
/// 3. Profile → /profile (Cửa hàng / Quests / Leaderboard nằm bên trong)
class BottomNavBar extends StatefulWidget {
  final int currentIndex;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
  });

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPendingCount();
  }

  Future<void> _loadPendingCount() async {
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final data = await api.getFriendPendingCount();
      if (mounted) {
        setState(() => _pendingCount = data['count'] ?? 0);
      }
    } catch (_) {}
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/library');
        break;
      case 2:
        context.go('/library/my-contributions');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = context.colors;
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF1E2830),
                    tokens.card,
                    tokens.card,
                  ],
                  stops: const [0.0, 0.35, 1.0],
                )
              : null,
          color: isDark ? null : tokens.card,
          border: Border(
            top: BorderSide(
              color:
                  isDark ? tokens.brand.withValues(alpha: 0.28) : tokens.border,
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? tokens.brand.withValues(alpha: 0.14)
                  : tokens.shadowColor,
              blurRadius: isDark ? 18 : 22,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          minimum: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
            child: Row(
              children: [
                Expanded(
                  child: _NavEntry(
                    selected: widget.currentIndex == 0,
                    label: 'Trang chủ',
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    onTap: () => _onItemTapped(context, 0),
                  ),
                ),
                Expanded(
                  child: _NavEntry(
                    selected: widget.currentIndex == 1,
                    label: 'Thư viện',
                    icon: Icons.menu_book_outlined,
                    activeIcon: Icons.menu_book_rounded,
                    onTap: () => _onItemTapped(context, 1),
                  ),
                ),
                Expanded(
                  child: _NavEntry(
                    selected: widget.currentIndex == 2,
                    label: 'Của tôi',
                    icon: Icons.edit_note_outlined,
                    activeIcon: Icons.edit_note_rounded,
                    onTap: () => _onItemTapped(context, 2),
                  ),
                ),
                Expanded(
                  child: _NavEntry(
                    selected: widget.currentIndex == 3,
                    label: 'Profile',
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    onTap: () => _onItemTapped(context, 3),
                    badgeCount: _pendingCount,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavEntry extends StatelessWidget {
  const _NavEntry({
    required this.selected,
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.onTap,
    this.badgeCount = 0,
  });

  final bool selected;
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = context.colors;

    final iconColor = selected
        ? (isDark ? tokens.textOnBrand : tokens.brandStrong)
        : (isDark
            ? tokens.textTertiary.withValues(alpha: 0.9)
            : tokens.textSecondary);
    final labelColor = iconColor;

    Widget iconWidget = Icon(
      selected ? activeIcon : icon,
      size: 24,
      color: iconColor,
    );

    if (badgeCount > 0) {
      iconWidget = Badge(
        backgroundColor: tokens.brand,
        alignment: const Alignment(0.55, -0.65),
        label: Text(
          badgeCount > 9 ? '9+' : '$badgeCount',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: tokens.textOnBrand,
          ),
        ),
        child: iconWidget,
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: tokens.brand.withValues(alpha: 0.18),
        highlightColor: tokens.brand.withValues(alpha: 0.08),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: selected && isDark
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      tokens.brand.withValues(alpha: 0.55),
                      tokens.brand.withValues(alpha: 0.22),
                    ],
                  )
                : null,
            color: selected && !isDark ? tokens.brandSoft : null,
            border: Border.all(
              color: selected
                  ? (isDark
                      ? tokens.brand.withValues(alpha: 0.45)
                      : tokens.brand.withValues(alpha: 0.3))
                  : Colors.transparent,
            ),
            boxShadow: selected && isDark
                ? [
                    BoxShadow(
                      color: tokens.brand.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : (selected && !isDark
                    ? [
                        BoxShadow(
                          color: tokens.brand.withValues(alpha: 0.12),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              iconWidget,
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTextStyles.labelSmall.copyWith(
                  color: labelColor,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                  fontSize: selected ? 11.5 : 10.5,
                  letterSpacing: selected ? -0.1 : 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
