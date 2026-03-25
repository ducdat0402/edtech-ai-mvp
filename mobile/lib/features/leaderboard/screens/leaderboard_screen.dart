import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/core/widgets/app_bar_leading_back_home.dart';
import 'package:edtech_mobile/core/widgets/bottom_nav_bar.dart';
import 'package:edtech_mobile/core/widgets/error_widget.dart';
import 'package:edtech_mobile/core/widgets/empty_state.dart';
import 'package:edtech_mobile/features/chat/widgets/chat_bubble.dart';
import 'package:edtech_mobile/features/leaderboard/widgets/leaderboard_user_profile_sheet.dart';
import 'package:edtech_mobile/theme/theme.dart';

int _entryRank(Map<String, dynamic> e, int fallback) {
  final r = e['rank'];
  if (r is int) return r;
  if (r is num) return r.toInt();
  return fallback;
}

class LeaderboardScreen extends StatefulWidget {
  final String? subjectId;
  const LeaderboardScreen({super.key, this.subjectId});

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
  Timer? _countdownTimer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: widget.subjectId != null ? 3 : 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadData();
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _updateTimeLeft();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateTimeLeft();
    });
  }

  void _updateTimeLeft() {
    final now = DateTime.now();
    final daysTillMonday = (DateTime.monday - now.weekday) % 7;
    final nextMonday = DateTime(now.year, now.month,
        now.day + (daysTillMonday == 0 ? 7 : daysTillMonday));
    setState(() {
      _timeLeft = nextMonday.difference(now);
    });
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
      final api = Provider.of<ApiService>(context, listen: false);
      try {
        _myRank = await api.getMyRank();
      } catch (_) {}
      await _loadDataForTab(_tabController.index);
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDataForTab(int tabIndex) async {
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      switch (tabIndex) {
        case 0:
          _globalData = await api.getGlobalLeaderboard(limit: 50, page: 1);
          break;
        case 1:
          _weeklyData = await api.getWeeklyRankings(limit: 50);
          break;
        case 2:
          if (widget.subjectId != null) {
            _subjectData = await api.getSubjectLeaderboard(widget.subjectId!,
                limit: 50, page: 1);
          }
          break;
      }
      setState(() {});
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
        leading: const AppBarLeadingBackAndHome(),
        leadingWidth: 112,
        automaticallyImplyLeading: false,
        title: Text('Bảng xếp hạng',
            style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.purpleNeon,
          indicatorWeight: 3,
          labelColor: AppColors.textPrimary,
          unselectedLabelColor: AppColors.textTertiary,
          labelStyle: AppTextStyles.labelMedium,
          tabs: [
            const Tab(
                text: 'Toàn cầu', icon: Icon(Icons.public_rounded, size: 20)),
            const Tab(
                text: 'Tuần này',
                icon: Icon(Icons.emoji_events_rounded, size: 20)),
            if (widget.subjectId != null)
              const Tab(
                  text: 'Môn học', icon: Icon(Icons.book_rounded, size: 20)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded,
                color: AppColors.textSecondary),
            tooltip: 'Lịch sử phần thưởng',
            onPressed: () => context.push('/weekly-rewards-history'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: AppColors.textSecondary),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Stack(
        children: [
          _isLoading
              ? _buildLoading()
              : _error != null
                  ? AppErrorWidget(message: _error!, onRetry: _loadData)
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildGlobalTab(),
                        _buildWeeklyTab(),
                        if (widget.subjectId != null)
                          _buildGlobalList(_subjectData),
                      ],
                    ),
          const FloatingChatBubble(),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.purpleNeon),
    );
  }

  // ─── Global Tab ───
  Widget _buildGlobalTab() {
    return Column(
      children: [
        if (_myRank != null) _buildMyRankCard(),
        Expanded(
            child: _buildGlobalList(_globalData,
                sourceLabel: 'Bảng toàn cầu')),
      ],
    );
  }

  Widget _buildGlobalList(
    Map<String, dynamic>? data, {
    String sourceLabel = 'Bảng xếp hạng',
  }) {
    if (data == null) return _buildLoading();
    final entries = data['entries'] as List? ?? [];
    if (entries.isEmpty) return const EmptyLeaderboardWidget();
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: entries.length,
      itemBuilder: (_, i) {
        final entry = entries[i] as Map<String, dynamic>;
        return StaggeredListItem(
          index: i,
          child: _LeaderboardEntryCard(
            rank: entry['rank'] ?? i + 1,
            entry: entry,
            profileSourceLabel: sourceLabel,
          ),
        );
      },
    );
  }

  // ─── Weekly Tab ───
  Widget _buildWeeklyTab() {
    if (_weeklyData == null) return _buildLoading();
    final entries = _weeklyData!['entries'] as List? ?? [];
    final myRank = _weeklyData!['myRank'] as int?;
    final myXp = _weeklyData!['myXp'] as int? ?? 0;
    final tiers = _weeklyData!['rewardTiers'] as List? ?? [];

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildWeekHeader()),
        SliverToBoxAdapter(child: _buildRewardsPreview(tiers)),
        if (entries.length >= 3)
          SliverToBoxAdapter(child: _buildPodium(entries)),
        if (entries.isEmpty)
          const SliverFillRemaining(child: EmptyLeaderboardWidget()),
        if (entries.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final startIdx = entries.length >= 3 ? 3 : 0;
                  if (startIdx + i >= entries.length) return null;
                  final entry = entries[startIdx + i] as Map<String, dynamic>;
                  return _WeeklyEntryCard(
                    rank: entry['rank'] ?? startIdx + i + 1,
                    entry: entry,
                    profileSourceLabel: 'Bảng XP tuần này',
                  );
                },
                childCount:
                    entries.length >= 3 ? entries.length - 3 : entries.length,
              ),
            ),
          ),
        if (myRank != null && myRank > 10)
          SliverToBoxAdapter(child: _buildStickyMyPosition(myRank, myXp)),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  Widget _buildWeekHeader() {
    final d = _timeLeft.inDays;
    final h = _timeLeft.inHours % 24;
    final m = _timeLeft.inMinutes % 60;
    final s = _timeLeft.inSeconds % 60;
    final weekCode = _weeklyData?['weekCode'] ?? '';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.purpleNeon.withOpacity(0.8),
            AppColors.cyanNeon.withOpacity(0.6)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.purpleNeon.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(weekCode,
                  style:
                      AppTextStyles.labelLarge.copyWith(color: Colors.white)),
              const Spacer(),
              const Icon(Icons.emoji_events_rounded,
                  color: Colors.amber, size: 24),
            ],
          ),
          const SizedBox(height: 16),
          Text('Kết thúc trong',
              style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CountdownBlock(value: '$d', label: 'Ngày'),
              _CountdownSeparator(),
              _CountdownBlock(
                  value: h.toString().padLeft(2, '0'), label: 'Giờ'),
              _CountdownSeparator(),
              _CountdownBlock(
                  value: m.toString().padLeft(2, '0'), label: 'Phút'),
              _CountdownSeparator(),
              _CountdownBlock(
                  value: s.toString().padLeft(2, '0'), label: 'Giây'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsPreview(List tiers) {
    if (tiers.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Phần thưởng tuần',
              style: AppTextStyles.labelLarge
                  .copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tiers.map<Widget>((t) {
              final tier = t is Map<String, dynamic> ? t : <String, dynamic>{};
              final maxRank = tier['maxRank'] ?? 0;
              final diamonds = tier['diamonds'] ?? 0;
              final badge = tier['badgeName'];
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: maxRank <= 3
                      ? AppColors.purpleNeon.withOpacity(0.1)
                      : AppColors.bgTertiary,
                  borderRadius: BorderRadius.circular(12),
                  border: maxRank <= 3
                      ? Border.all(color: AppColors.purpleNeon.withOpacity(0.3))
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      maxRank <= 3 ? 'Top $maxRank' : 'Top $maxRank',
                      style: AppTextStyles.labelMedium.copyWith(
                          color: maxRank <= 3
                              ? AppColors.purpleNeon
                              : AppColors.textSecondary),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.diamond_rounded,
                        size: 14, color: Colors.lightBlueAccent),
                    const SizedBox(width: 2),
                    Text('$diamonds',
                        style: AppTextStyles.labelMedium
                            .copyWith(color: Colors.lightBlueAccent)),
                    if (badge != null) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.workspace_premium_rounded,
                          size: 14, color: Colors.amber),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPodium(List entries) {
    final top3 = entries.take(3).toList();
    if (top3.length < 3) return const SizedBox.shrink();
    final e1 = top3[0] as Map<String, dynamic>;
    final e2 = top3[1] as Map<String, dynamic>;
    final e3 = top3[2] as Map<String, dynamic>;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
              child: _PodiumItem(
                  entry: e2,
                  rank: _entryRank(e2, 2),
                  height: 100,
                  profileSourceLabel: 'Bảng XP tuần này')),
          Expanded(
              child: _PodiumItem(
                  entry: e1,
                  rank: _entryRank(e1, 1),
                  height: 130,
                  profileSourceLabel: 'Bảng XP tuần này')),
          Expanded(
              child: _PodiumItem(
                  entry: e3,
                  rank: _entryRank(e3, 3),
                  height: 80,
                  profileSourceLabel: 'Bảng XP tuần này')),
        ],
      ),
    );
  }

  Widget _buildStickyMyPosition(int rank, int xp) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.purpleNeon.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text('#$rank',
                  style: AppTextStyles.h4.copyWith(color: Colors.white)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Vị trí của bạn',
                    style:
                        AppTextStyles.labelLarge.copyWith(color: Colors.white)),
                Text('$xp XP tuần này',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: Colors.white70)),
              ],
            ),
          ),
          const Icon(Icons.arrow_upward_rounded,
              color: Colors.greenAccent, size: 24),
        ],
      ),
    );
  }

  Widget _buildMyRankCard() {
    final rank = _myRank?['globalRank'] ?? _myRank?['rank'];
    final totalXP = _myRank?['totalXP'] ?? 0;
    if (rank == null) return const SizedBox.shrink();

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
              child: Text('#$rank',
                  style: AppTextStyles.h3.copyWith(color: Colors.white)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hạng của bạn',
                    style: AppTextStyles.h4.copyWith(color: Colors.white)),
                const SizedBox(height: 4),
                Text('$totalXP XP tổng',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Countdown Widgets ───

class _CountdownBlock extends StatelessWidget {
  final String value;
  final String label;
  const _CountdownBlock({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(value,
                style: AppTextStyles.h3.copyWith(color: Colors.white)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: AppTextStyles.caption
                .copyWith(color: Colors.white60, fontSize: 10)),
      ],
    );
  }
}

class _CountdownSeparator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(':', style: AppTextStyles.h3.copyWith(color: Colors.white60)),
    );
  }
}

// ─── Podium ───

class _PodiumItem extends StatelessWidget {
  final Map<String, dynamic> entry;
  final int rank;
  final double height;
  final String profileSourceLabel;
  const _PodiumItem({
    required this.entry,
    required this.rank,
    required this.height,
    required this.profileSourceLabel,
  });

  Color get _color {
    if (rank == 1) return AppColors.rankGold;
    if (rank == 2) return AppColors.rankSilver;
    return AppColors.rankBronze;
  }

  String get _medal {
    if (rank == 1) return '🥇';
    if (rank == 2) return '🥈';
    return '🥉';
  }

  @override
  Widget build(BuildContext context) {
    final userId = entry['userId']?.toString();
    final api = Provider.of<ApiService>(context, listen: false);
    final weeklyXp = entry['weeklyXp'] ?? entry['totalXP'] ?? 0;
    final name = entry['fullName'] as String?;

    void openProfile() {
      if (userId == null || userId.isEmpty) return;
      final wxp = weeklyXp is int ? weeklyXp : int.tryParse('$weeklyXp') ?? 0;
      showLeaderboardUserProfileSheet(
        context,
        api: api,
        userId: userId,
        nameHint: name,
        rankHint: rank,
        sourceLabel: profileSourceLabel,
        weeklyXpFromBoard: wxp > 0 ? wxp : null,
      );
    }

    return Column(
      children: [
        Text(_medal, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 6),
        LeaderboardUserAvatar(
          displayName: name,
          imageUrl: entry['avatar'] as String?,
          size: 40,
          onTap: userId != null && userId.isNotEmpty ? openProfile : null,
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: userId != null && userId.isNotEmpty ? openProfile : null,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              entry['fullName'] ?? 'Anon',
              style: AppTextStyles.labelMedium
                  .copyWith(color: AppColors.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        Text(
          '$weeklyXp XP',
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        Container(
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_color.withOpacity(0.8), _color.withOpacity(0.4)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: AppTextStyles.h3.copyWith(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Weekly Entry Card ───

class _WeeklyEntryCard extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> entry;
  final String profileSourceLabel;
  const _WeeklyEntryCard({
    required this.rank,
    required this.entry,
    required this.profileSourceLabel,
  });

  @override
  Widget build(BuildContext context) {
    final userId = entry['userId']?.toString();
    final api = Provider.of<ApiService>(context, listen: false);
    final name = entry['fullName'] as String?;
    final weeklyXp = entry['weeklyXp'] ?? 0;
    final wxp = weeklyXp is int ? weeklyXp : int.tryParse('$weeklyXp') ?? 0;

    void openProfile() {
      if (userId == null || userId.isEmpty) return;
      showLeaderboardUserProfileSheet(
        context,
        api: api,
        userId: userId,
        nameHint: name,
        rankHint: rank,
        sourceLabel: profileSourceLabel,
        weeklyXpFromBoard: wxp > 0 ? wxp : null,
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderPrimary),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.bgTertiary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text('#$rank',
                  style: AppTextStyles.labelLarge
                      .copyWith(color: AppColors.textSecondary)),
            ),
          ),
          const SizedBox(width: 10),
          LeaderboardUserAvatar(
            displayName: name,
            imageUrl: entry['avatar'] as String?,
            size: 44,
            onTap: userId != null && userId.isNotEmpty ? openProfile : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: userId != null && userId.isNotEmpty ? openProfile : null,
              borderRadius: BorderRadius.circular(8),
              child: Text(
                entry['fullName'] ?? 'Anonymous',
                style: AppTextStyles.labelLarge
                    .copyWith(color: AppColors.textPrimary),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.xpGold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.star_rounded,
                    color: AppColors.xpGold, size: 16),
                const SizedBox(width: 4),
                Text('${entry['weeklyXp'] ?? 0}',
                    style: AppTextStyles.numberMedium
                        .copyWith(color: AppColors.xpGold, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Leaderboard Entry Card (Global/Subject) ───

class _LeaderboardEntryCard extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> entry;
  final String profileSourceLabel;
  const _LeaderboardEntryCard({
    required this.rank,
    required this.entry,
    required this.profileSourceLabel,
  });

  Color _getRankColor(int rank) {
    if (rank == 1) return AppColors.rankGold;
    if (rank == 2) return AppColors.rankSilver;
    if (rank == 3) return AppColors.rankBronze;
    return AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final rankColor = _getRankColor(rank);
    final isTopThree = rank <= 3;
    final userId = entry['userId']?.toString();
    final api = Provider.of<ApiService>(context, listen: false);
    final name = entry['fullName'] as String?;

    void openProfile() {
      if (userId == null || userId.isEmpty) return;
      showLeaderboardUserProfileSheet(
        context,
        api: api,
        userId: userId,
        nameHint: name,
        rankHint: rank,
        sourceLabel: profileSourceLabel,
      );
    }

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
                    offset: const Offset(0, 2))
              ]
            : null,
      ),
      child: Row(
        children: [
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
                  ? Icon(Icons.emoji_events_rounded, color: rankColor, size: 24)
                  : Text('#$rank',
                      style: AppTextStyles.labelLarge
                          .copyWith(color: AppColors.textSecondary)),
            ),
          ),
          const SizedBox(width: 10),
          LeaderboardUserAvatar(
            displayName: name,
            imageUrl: entry['avatar'] as String?,
            size: 44,
            onTap: userId != null && userId.isNotEmpty ? openProfile : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: userId != null && userId.isNotEmpty ? openProfile : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Text(
                    entry['fullName'] ?? 'Anonymous',
                    style: AppTextStyles.labelLarge.copyWith(
                        color: isTopThree ? rankColor : AppColors.textPrimary),
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
                      Text('${entry['currentStreak']}',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textSecondary)),
                      const SizedBox(width: 12),
                    ],
                    if (entry['coins'] != null) ...[
                      const Icon(Icons.monetization_on_rounded,
                          size: 14, color: AppColors.coinGold),
                      const SizedBox(width: 4),
                      Text('${entry['coins']}',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textSecondary)),
                    ],
                  ],
                ),
              ],
            ),
          ),
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
                Text('${entry['totalXP'] ?? 0}',
                    style: AppTextStyles.numberMedium
                        .copyWith(color: AppColors.xpGold, fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
