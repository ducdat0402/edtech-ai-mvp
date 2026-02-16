import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/core/widgets/bottom_nav_bar.dart';
import 'package:edtech_mobile/core/widgets/error_widget.dart';
import 'package:edtech_mobile/core/widgets/empty_state.dart';
import 'package:edtech_mobile/theme/theme.dart';

class LeaderboardScreen extends StatefulWidget {
  final String? subjectId;

  const LeaderboardScreen({
    super.key,
    this.subjectId,
  });

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _globalData;
  Map<String, dynamic>? _weeklyData;
  Map<String, dynamic>? _subjectData;
  Map<String, dynamic>? _myRank;
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;
  final int _pageSize = 50;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: widget.subjectId != null ? 3 : 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _loadDataForTab(_tabController.index);
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);

      try {
        final myRank = await apiService.getMyRank();
        setState(() {
          _myRank = myRank;
        });
      } catch (e) {
        // Ignore
      }

      await _loadDataForTab(_tabController.index);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDataForTab(int tabIndex) async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);

      switch (tabIndex) {
        case 0:
          final globalData =
              await apiService.getGlobalLeaderboard(limit: _pageSize, page: 1);
          setState(() => _globalData = globalData);
          break;
        case 1:
          final weeklyData =
              await apiService.getWeeklyLeaderboard(limit: _pageSize, page: 1);
          setState(() => _weeklyData = weeklyData);
          break;
        case 2:
          if (widget.subjectId != null) {
            final subjectData = await apiService.getSubjectLeaderboard(
                widget.subjectId!,
                limit: _pageSize,
                page: 1);
            setState(() => _subjectData = subjectData);
          }
          break;
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Bảng xếp hạng',
            style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.purpleNeon,
          indicatorWeight: 3,
          labelColor: AppColors.textPrimary,
          unselectedLabelColor: AppColors.textTertiary,
          labelStyle: AppTextStyles.labelMedium,
          tabs: widget.subjectId != null
              ? const [
                  Tab(
                      text: 'Toàn cầu',
                      icon: Icon(Icons.public_rounded, size: 20)),
                  Tab(
                      text: 'Tuần này',
                      icon: Icon(Icons.calendar_view_week_rounded, size: 20)),
                  Tab(
                      text: 'Môn học',
                      icon: Icon(Icons.book_rounded, size: 20)),
                ]
              : const [
                  Tab(
                      text: 'Toàn cầu',
                      icon: Icon(Icons.public_rounded, size: 20)),
                  Tab(
                      text: 'Tuần này',
                      icon: Icon(Icons.calendar_view_week_rounded, size: 20)),
                ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: AppColors.textSecondary),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _error != null
              ? AppErrorWidget(message: _error!, onRetry: _loadData)
              : Column(
                  children: [
                    if (_myRank != null) _buildMyRankCard(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildLeaderboardList(_globalData),
                          _buildLeaderboardList(_weeklyData),
                          if (widget.subjectId != null)
                            _buildLeaderboardList(_subjectData),
                        ],
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.purpleNeon),
          const SizedBox(height: 16),
          Text('Đang tải...',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildMyRankCard() {
    final rank = _myRank?['rank'] as int?;
    final totalUsers = _myRank?['totalUsers'] as int?;
    final entry = _myRank?['entry'] as Map<String, dynamic>?;

    if (rank == null || entry == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.purpleNeon.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border:
                  Border.all(color: Colors.white.withOpacity(0.3), width: 2),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '#$rank',
                    style: AppTextStyles.h3.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry['fullName'] ?? 'You',
                  style: AppTextStyles.h4.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hạng $rank / $totalUsers người chơi',
                  style:
                      AppTextStyles.bodySmall.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  const Icon(Icons.star_rounded,
                      color: AppColors.xpGold, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '${entry['totalXP'] ?? 0}',
                    style: AppTextStyles.numberMedium
                        .copyWith(color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.local_fire_department_rounded,
                      color: AppColors.streakOrange, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${entry['currentStreak'] ?? 0}',
                    style:
                        AppTextStyles.bodySmall.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardList(Map<String, dynamic>? data) {
    if (data == null) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.purpleNeon));
    }

    final entries = data['entries'] as List<dynamic>? ?? [];

    if (entries.isEmpty) {
      return const EmptyLeaderboardWidget();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index] as Map<String, dynamic>;
        final rank = entry['rank'] as int? ?? index + 1;

        return StaggeredListItem(
          index: index,
          child: _LeaderboardEntryCard(rank: rank, entry: entry),
        );
      },
    );
  }
}

class _LeaderboardEntryCard extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> entry;

  const _LeaderboardEntryCard({
    required this.rank,
    required this.entry,
  });

  Color _getRankColor(int rank) {
    if (rank == 1) return AppColors.rankGold;
    if (rank == 2) return AppColors.rankSilver;
    if (rank == 3) return AppColors.rankBronze;
    return AppColors.textSecondary;
  }

  IconData _getRankIcon(int rank) {
    if (rank == 1) return Icons.emoji_events_rounded;
    if (rank == 2) return Icons.military_tech_rounded;
    if (rank == 3) return Icons.workspace_premium_rounded;
    return Icons.person_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final rankColor = _getRankColor(rank);
    final rankIcon = _getRankIcon(rank);
    final isTopThree = rank <= 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: isTopThree
            ? Border.all(color: rankColor.withOpacity(0.5), width: 2)
            : Border.all(color: AppColors.borderPrimary),
        boxShadow: isTopThree
            ? [
                BoxShadow(
                  color: rankColor.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Rank indicator
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isTopThree
                  ? rankColor.withOpacity(0.2)
                  : AppColors.bgTertiary,
              borderRadius: BorderRadius.circular(12),
              border: isTopThree
                  ? Border.all(color: rankColor.withOpacity(0.5))
                  : null,
            ),
            child: Center(
              child: isTopThree
                  ? Icon(rankIcon, color: rankColor, size: 24)
                  : Text(
                      '#$rank',
                      style: AppTextStyles.labelLarge
                          .copyWith(color: AppColors.textSecondary),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry['fullName'] ?? 'Anonymous',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: isTopThree ? rankColor : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (entry['currentStreak'] != null &&
                        entry['currentStreak'] > 0) ...[
                      const Icon(Icons.local_fire_department_rounded,
                          size: 14, color: AppColors.streakOrange),
                      const SizedBox(width: 4),
                      Text(
                        '${entry['currentStreak']}',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (entry['coins'] != null) ...[
                      const Icon(Icons.monetization_on_rounded,
                          size: 14, color: AppColors.coinGold),
                      const SizedBox(width: 4),
                      Text(
                        '${entry['coins']}',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // XP
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.xpGold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.star_rounded,
                    color: AppColors.xpGold, size: 18),
                const SizedBox(width: 4),
                Text(
                  '${entry['totalXP'] ?? entry['lPoints'] ?? 0}',
                  style: AppTextStyles.numberMedium
                      .copyWith(color: AppColors.xpGold, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
