import 'package:flutter/material.dart';
import 'package:edtech_mobile/core/widgets/app_bar_leading_back_home.dart';
import 'package:edtech_mobile/core/widgets/bottom_nav_bar.dart';
import 'package:edtech_mobile/features/community/screens/community_feed_tab.dart';
import 'package:edtech_mobile/features/friends/screens/friends_connections_panel.dart';
import 'package:edtech_mobile/theme/theme.dart';

/// Tab thanh dưới: Cộng đồng (bảng tin) + Bạn bè (danh sách / lời mời / gợi ý).
class CommunityHubScreen extends StatefulWidget {
  const CommunityHubScreen({super.key});

  @override
  State<CommunityHubScreen> createState() => _CommunityHubScreenState();
}

class _CommunityHubScreenState extends State<CommunityHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _outer;

  @override
  void initState() {
    super.initState();
    _outer = TabController(length: 2, vsync: this);
    _outer.addListener(() {
      if (!_outer.indexIsChanging && mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _outer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgSecondary,
        leading: const AppBarLeadingBackAndHome(),
        leadingWidth: 112,
        automaticallyImplyLeading: false,
        title: Text(
          _outer.index == 0 ? 'Cộng đồng' : 'Bạn bè',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        bottom: TabBar(
          controller: _outer,
          indicatorColor: AppColors.purpleNeon,
          labelColor: AppColors.purpleNeon,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Cộng đồng', icon: Icon(Icons.groups_rounded, size: 20)),
            Tab(text: 'Bạn bè', icon: Icon(Icons.people_rounded, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _outer,
        children: const [
          CommunityFeedTab(),
          Material(
            color: AppColors.bgPrimary,
            child: FriendsConnectionsPanel(),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
    );
  }
}
