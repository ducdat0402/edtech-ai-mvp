import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/theme/colors.dart';
import 'package:edtech_mobile/theme/text_styles.dart';

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
        context.go('/friends');
        break;
      case 3:
        context.go('/shop');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1E2830),
              AppColors.bgSecondary,
              AppColors.bgSecondary,
            ],
            stops: const [0.0, 0.35, 1.0],
          ),
          border: Border(
            top: BorderSide(
              color: AppColors.purpleNeon.withValues(alpha: 0.28),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.purpleNeon.withValues(alpha: 0.14),
              blurRadius: 18,
              offset: const Offset(0, -8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.55),
              blurRadius: 14,
              offset: const Offset(0, -4),
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
                    label: 'Tổng quan',
                    icon: Icons.dashboard_outlined,
                    activeIcon: Icons.dashboard_rounded,
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
                    label: 'Cộng đồng',
                    icon: Icons.groups_outlined,
                    activeIcon: Icons.groups_rounded,
                    onTap: () => _onItemTapped(context, 2),
                    badgeCount: _pendingCount,
                  ),
                ),
                Expanded(
                  child: _NavEntry(
                    selected: widget.currentIndex == 3,
                    label: 'Cửa hàng',
                    icon: Icons.storefront_outlined,
                    activeIcon: Icons.storefront_rounded,
                    onTap: () => _onItemTapped(context, 3),
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
    final iconColor =
        selected ? Colors.white : AppColors.textTertiary.withValues(alpha: 0.9);
    final labelColor =
        selected ? Colors.white : AppColors.textTertiary.withValues(alpha: 0.88);

    Widget iconWidget = Icon(
      selected ? activeIcon : icon,
      size: 24,
      color: iconColor,
    );

    if (badgeCount > 0) {
      iconWidget = Badge(
        backgroundColor: AppColors.purpleNeon,
        alignment: const Alignment(0.55, -0.65),
        label: Text(
          badgeCount > 9 ? '9+' : '$badgeCount',
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: Colors.white,
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
        splashColor: AppColors.purpleNeon.withValues(alpha: 0.2),
        highlightColor: AppColors.purpleNeon.withValues(alpha: 0.08),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: selected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.purpleNeon.withValues(alpha: 0.55),
                      AppColors.purpleNeon.withValues(alpha: 0.22),
                    ],
                  )
                : null,
            border: Border.all(
              color: selected
                  ? AppColors.primaryLight.withValues(alpha: 0.35)
                  : Colors.transparent,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.purpleNeon.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              iconWidget,
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTextStyles.labelSmall.copyWith(
                  color: labelColor,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 11,
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
