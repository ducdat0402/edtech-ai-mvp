import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:edtech_mobile/core/services/api_service.dart';

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
        context.go('/subjects');
        break;
      case 2:
        context.go('/leaderboard');
        break;
      case 3:
        context.go('/friends');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: widget.currentIndex,
      onTap: (index) => _onItemTapped(context, index),
      type: BottomNavigationBarType.fixed,
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Tổng quan',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.menu_book),
          label: 'Môn học',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.leaderboard),
          label: 'Xếp hạng',
        ),
        BottomNavigationBarItem(
          icon: _buildFriendsIcon(),
          label: 'Cộng đồng',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Hồ sơ',
        ),
      ],
    );
  }

  Widget _buildFriendsIcon() {
    if (_pendingCount <= 0) {
      return const Icon(Icons.groups_rounded);
    }
    return Badge(
      label: Text(
        _pendingCount > 9 ? '9+' : '$_pendingCount',
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
      ),
      child: const Icon(Icons.groups_rounded),
    );
  }
}
