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
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const AppBarLeadingBackAndHome(),
        leadingWidth: 112,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.orangeNeon.withValues(alpha: 0.45),
                    AppColors.orangeNeon.withValues(alpha: 0.08),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.orangeNeon.withValues(alpha: 0.22),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                _outer.index == 0
                    ? Icons.groups_rounded
                    : Icons.people_rounded,
                color: AppColors.orangeNeon,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _outer.index == 0 ? 'Cộng đồng' : 'Bạn bè',
                style: AppTextStyles.h4.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.orangeNeon.withValues(alpha: 0.14),
                    AppColors.bgSecondary,
                  ],
                ),
                border: Border.all(
                  color: AppColors.orangeNeon.withValues(alpha: 0.28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    offset: const Offset(0, 5),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: TabBar(
                controller: _outer,
                padding: const EdgeInsets.all(5),
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.purpleNeon.withValues(alpha: 0.42),
                      AppColors.purpleNeon.withValues(alpha: 0.14),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.purpleNeon.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: AppTextStyles.labelMedium,
                tabs: const [
                  Tab(
                    height: 44,
                    text: 'Cộng đồng',
                    icon: Icon(Icons.forum_rounded, size: 20),
                  ),
                  Tab(
                    height: 44,
                    text: 'Bạn bè',
                    icon: Icon(Icons.people_rounded, size: 20),
                  ),
                ],
              ),
            ),
          ),
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
