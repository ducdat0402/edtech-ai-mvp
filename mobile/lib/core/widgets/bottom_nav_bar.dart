import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/theme/colors.dart';

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
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgSecondary,
        border: Border(
          top: BorderSide(color: Color(0x332D363D)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Theme(
          data: Theme.of(context).copyWith(
            splashColor: AppColors.purpleNeon.withValues(alpha: 0.12),
            highlightColor: Colors.transparent,
          ),
          child: BottomNavigationBar(
            currentIndex: widget.currentIndex,
            onTap: (index) => _onItemTapped(context, index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: AppColors.primaryLight,
            unselectedItemColor: AppColors.textTertiary,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard_rounded),
                label: 'Tổng quan',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.menu_book_outlined),
                activeIcon: Icon(Icons.menu_book_rounded),
                label: 'Thư viện',
              ),
              BottomNavigationBarItem(
                icon: _buildFriendsIcon(selected: false),
                activeIcon: _buildFriendsIcon(selected: true),
                label: 'Cộng đồng',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.storefront_outlined),
                activeIcon: Icon(Icons.storefront_rounded),
                label: 'Cửa hàng',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFriendsIcon({required bool selected}) {
    final icon = Icon(
      selected ? Icons.groups_rounded : Icons.groups_outlined,
    );
    if (_pendingCount <= 0) return icon;
    return Badge(
      backgroundColor: AppColors.purpleNeon,
      label: Text(
        _pendingCount > 9 ? '9+' : '$_pendingCount',
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
      ),
      child: icon,
    );
  }
}
