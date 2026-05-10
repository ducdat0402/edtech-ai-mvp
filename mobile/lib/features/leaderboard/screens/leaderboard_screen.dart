import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/core/widgets/app_bar_leading_back_home.dart';
import 'package:edtech_mobile/core/widgets/bottom_nav_bar.dart';
import 'package:edtech_mobile/core/widgets/error_widget.dart';
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
    final sem = context.colors;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                    sem.gold.withValues(alpha: 0.5),
                    sem.gold.withValues(alpha: 0.08),
                  ],
                ),
                border: Border.all(
                  color: sem.textOnBrand.withValues(alpha: 0.12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: sem.gold.withValues(alpha: 0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.emoji_events_rounded,
                color: sem.gold,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Bảng xếp hạng',
                style: AppTextStyles.h4.copyWith(
                  color: context.colors.textPrimary,
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
                    sem.gold.withValues(alpha: 0.14),
                    sem.card,
                  ],
                ),
                border: Border.all(
                  color: sem.gold.withValues(alpha: 0.28),
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
                controller: _tabController,
                padding: const EdgeInsets.all(5),
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  gradient: LinearGradient(
                    colors: [
                      sem.brand.withValues(alpha: 0.45),
                      sem.brand.withValues(alpha: 0.14),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: sem.brand.withValues(alpha: 0.28),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: sem.textOnBrand,
                unselectedLabelColor: sem.textTertiary,
                labelStyle: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: AppTextStyles.labelMedium,
                tabs: [
                  const Tab(
                    height: 44,
                    text: 'Toàn cầu',
                    icon: Icon(Icons.public_rounded, size: 20),
                  ),
                  const Tab(
                    height: 44,
                    text: 'Tuần này',
                    icon: Icon(Icons.emoji_events_rounded, size: 20),
                  ),
                  if (widget.subjectId != null)
                    const Tab(
                      height: 44,
                      text: 'Môn học',
                      icon: Icon(Icons.book_rounded, size: 20),
                    ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.history_rounded,
              color: sem.brand.withValues(alpha: 0.95),
            ),
            tooltip: 'Lịch sử phần thưởng',
            onPressed: () => context.push('/weekly-rewards-history'),
          ),
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: sem.brand.withValues(alpha: 0.95),
            ),
            tooltip: 'Làm mới',
            onPressed: _loadData,
          ),
        ],
      ),
      body: Stack(
        children: [
          _isLoading
              ? _buildLoading(context)
              : _error != null
                  ? AppErrorWidget(message: _error!, onRetry: _loadData)
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildGlobalTab(context),
                        _buildWeeklyTab(context),
                        if (widget.subjectId != null)
                          _buildGlobalList(context, _subjectData),
                      ],
                    ),
          const FloatingChatBubble(),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildLoading(BuildContext context) {
    final sem = context.colors;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  sem.brand.withValues(alpha: 0.35),
                  sem.card,
                ],
              ),
              border: Border.all(
                color: sem.brand.withValues(alpha: 0.3),
              ),
            ),
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                color: sem.brand,
                strokeWidth: 2.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Đang tải bảng xếp hạng…',
            style: AppTextStyles.bodySmall.copyWith(
              color: sem.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Global Tab ───
  Widget _buildGlobalTab(BuildContext context) {
    return Column(
      children: [
        if (_myRank != null) _buildMyRankCard(context),
        Expanded(
            child: _buildGlobalList(context, _globalData,
                sourceLabel: 'Bảng toàn cầu')),
      ],
    );
  }

  Widget _buildGlobalList(
    BuildContext context,
    Map<String, dynamic>? data, {
    String sourceLabel = 'Bảng xếp hạng',
  }) {
    if (data == null) return _buildLoading(context);
    final entries = data['entries'] as List? ?? [];
    if (entries.isEmpty) return const _LeaderboardEmptyState();
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
  Widget _buildWeeklyTab(BuildContext context) {
    if (_weeklyData == null) return _buildLoading(context);
    final entries = _weeklyData!['entries'] as List? ?? [];
    final myRank = _weeklyData!['myRank'] as int?;
    final myXp = _weeklyData!['myXp'] as int? ?? 0;
    final tiers = _weeklyData!['rewardTiers'] as List? ?? [];

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildWeekHeader(context)),
        SliverToBoxAdapter(child: _buildRewardsPreview(context, tiers)),
        if (entries.length >= 3)
          SliverToBoxAdapter(child: _buildPodium(entries)),
        if (entries.isEmpty)
          const SliverFillRemaining(child: _LeaderboardEmptyState()),
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
          SliverToBoxAdapter(
              child: _buildStickyMyPosition(context, myRank, myXp)),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  Widget _buildWeekHeader(BuildContext context) {
    final sem = context.colors;
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
            sem.brand.withValues(alpha: 0.85),
            sem.brand.withValues(alpha: 0.55),
            sem.gold.withValues(alpha: 0.35),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: sem.textOnBrand.withValues(alpha: 0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: sem.brand.withValues(alpha: 0.38),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            offset: const Offset(0, 6),
            blurRadius: 14,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today_rounded,
                  color: sem.textOnBrand, size: 20),
              const SizedBox(width: 8),
              Text(weekCode,
                  style:
                      AppTextStyles.labelLarge.copyWith(color: sem.textOnBrand)),
              const Spacer(),
              Icon(Icons.emoji_events_rounded,
                  color: sem.gold, size: 24),
            ],
          ),
          const SizedBox(height: 16),
          Text('Kết thúc trong',
              style: AppTextStyles.bodySmall.copyWith(
                  color: sem.textOnBrand.withValues(alpha: 0.7))),
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

  Widget _buildRewardsPreview(BuildContext context, List tiers) {
    if (tiers.isEmpty) return const SizedBox.shrink();
    final sem = context.colors;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            sem.brand.withValues(alpha: 0.12),
            sem.card,
          ],
        ),
        border: Border.all(
          color: sem.brand.withValues(alpha: 0.26),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            offset: const Offset(0, 4),
            blurRadius: 11,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    colors: [
                      sem.gold.withValues(alpha: 0.35),
                      sem.gold.withValues(alpha: 0.08),
                    ],
                  ),
                ),
                child: Icon(
                  Icons.card_giftcard_rounded,
                  color: sem.gold,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Phần thưởng tuần',
                style: AppTextStyles.labelLarge.copyWith(
                  color: sem.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
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
                  gradient: maxRank <= 3
                      ? LinearGradient(
                          colors: [
                            sem.brand.withValues(alpha: 0.22),
                            sem.brand.withValues(alpha: 0.06),
                          ],
                        )
                      : null,
                  color: maxRank <= 3 ? null : sem.cardMuted,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: maxRank <= 3
                        ? sem.brand.withValues(alpha: 0.45)
                        : sem.border.withValues(alpha: 0.65),
                  ),
                  boxShadow: maxRank <= 3
                      ? [
                          BoxShadow(
                            color: sem.brand.withValues(alpha: 0.18),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      maxRank <= 3 ? 'Top $maxRank' : 'Top $maxRank',
                      style: AppTextStyles.labelMedium.copyWith(
                          color: maxRank <= 3
                              ? sem.brand
                              : sem.textSecondary),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.diamond_rounded,
                        size: 14, color: sem.brand),
                    const SizedBox(width: 2),
                    Text('$diamonds',
                        style: AppTextStyles.labelMedium
                            .copyWith(color: sem.brand)),
                    if (badge != null) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.workspace_premium_rounded,
                          size: 14, color: sem.gold),
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

  Widget _buildStickyMyPosition(BuildContext context, int rank, int xp) {
    final sem = context.colors;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: sem.textOnBrand.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: sem.brand.withValues(alpha: 0.38),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: sem.textOnBrand.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: sem.textOnBrand.withValues(alpha: 0.35),
              ),
            ),
            child: Center(
              child: Text('#$rank',
                  style: AppTextStyles.h4.copyWith(color: sem.textOnBrand)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Vị trí của bạn',
                    style:
                        AppTextStyles.labelLarge.copyWith(color: sem.textOnBrand)),
                Text('$xp XP tuần này',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: sem.textOnBrand.withValues(alpha: 0.7))),
              ],
            ),
          ),
          Icon(Icons.arrow_upward_rounded,
              color: sem.success, size: 24),
        ],
      ),
    );
  }

  Widget _buildMyRankCard(BuildContext context) {
    final sem = context.colors;
    final rank = _myRank?['globalRank'] ?? _myRank?['rank'];
    final totalXP = _myRank?['totalXP'] ?? 0;
    if (rank == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: sem.textOnBrand.withValues(alpha: 0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: sem.brand.withValues(alpha: 0.42),
            blurRadius: 22,
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
              color: sem.textOnBrand.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: sem.textOnBrand.withValues(alpha: 0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text('#$rank',
                  style: AppTextStyles.h3.copyWith(color: sem.textOnBrand)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hạng của bạn',
                    style: AppTextStyles.h4.copyWith(color: sem.textOnBrand)),
                const SizedBox(height: 4),
                Text('$totalXP XP tổng',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: sem.textOnBrand.withValues(alpha: 0.7))),
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
    final t = context.colors;
    final on = t.textOnBrand;
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                on.withValues(alpha: 0.28),
                on.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: on.withValues(alpha: 0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                offset: const Offset(0, 3),
                blurRadius: 5,
              ),
            ],
          ),
          child: Center(
            child: Text(value,
                style: AppTextStyles.h3.copyWith(color: on)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: AppTextStyles.caption
                .copyWith(color: on.withValues(alpha: 0.6), fontSize: 10)),
      ],
    );
  }
}

class _CountdownSeparator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final on = context.colors.textOnBrand;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
          ':',
          style: AppTextStyles.h3.copyWith(
              color: on.withValues(alpha: 0.6))),
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

  Color _medalColor(BuildContext context) {
    final sem = context.colors;
    if (rank == 1) return sem.gold;
    if (rank == 2) return sem.textSecondary;
    return sem.warning;
  }

  String get _medal {
    if (rank == 1) return '🥇';
    if (rank == 2) return '🥈';
    return '🥉';
  }

  @override
  Widget build(BuildContext context) {
    final sem = context.colors;
    final medalColor = _medalColor(context);
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
        avatarFrameIdHint: entry['avatarFrameId'] as String?,
      );
    }

    return Column(
      children: [
        Text(_medal, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 6),
        LeaderboardUserAvatar(
          displayName: name,
          imageUrl: entry['avatar'] as String?,
          avatarFrameId: entry['avatarFrameId'] as String?,
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
                  .copyWith(color: sem.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        Text(
          '$weeklyXp XP',
          style: AppTextStyles.caption.copyWith(color: sem.textSecondary),
        ),
        const SizedBox(height: 8),
        Container(
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                medalColor.withValues(alpha: 0.95),
                medalColor.withValues(alpha: 0.45),
                medalColor.withValues(alpha: 0.28),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            border: Border.all(
              color: sem.textOnBrand.withValues(alpha: 0.22),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: medalColor.withValues(alpha: 0.45),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: AppTextStyles.h3.copyWith(color: sem.textOnBrand),
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
    final sem = context.colors;
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
        avatarFrameIdHint: entry['avatarFrameId'] as String?,
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            sem.brand.withValues(alpha: 0.08),
            sem.card,
          ],
        ),
        border: Border.all(
          color: sem.brand.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  sem.cardMuted,
                  sem.card,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: sem.border.withValues(alpha: 0.65),
              ),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: AppTextStyles.labelLarge.copyWith(
                  color: sem.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          LeaderboardUserAvatar(
            displayName: name,
            imageUrl: entry['avatar'] as String?,
            avatarFrameId: entry['avatarFrameId'] as String?,
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
                    .copyWith(color: sem.textPrimary),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  sem.gold.withValues(alpha: 0.35),
                  sem.gold.withValues(alpha: 0.1),
                ],
              ),
              border: Border.all(
                color: sem.gold.withValues(alpha: 0.45),
              ),
              boxShadow: [
                BoxShadow(
                  color: sem.gold.withValues(alpha: 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.star_rounded, color: sem.gold, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${entry['weeklyXp'] ?? 0}',
                  style: AppTextStyles.numberMedium.copyWith(
                    color: sem.gold,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
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

  Color _rankAccent(BuildContext context, int r) {
    final sem = context.colors;
    if (r == 1) return sem.gold;
    if (r == 2) return sem.textSecondary;
    if (r == 3) return sem.warning;
    return sem.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final sem = context.colors;
    final rankColor = _rankAccent(context, rank);
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
        avatarFrameIdHint: entry['avatarFrameId'] as String?,
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isTopThree
                ? rankColor.withValues(alpha: 0.14)
                : sem.brand.withValues(alpha: 0.06),
            sem.card,
          ],
        ),
        border: Border.all(
          color: isTopThree
              ? rankColor.withValues(alpha: 0.55)
              : sem.border.withValues(alpha: 0.65),
          width: isTopThree ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isTopThree
                ? rankColor.withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: 0.28),
            blurRadius: isTopThree ? 12 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: isTopThree
                  ? RadialGradient(
                      colors: [
                        rankColor.withValues(alpha: 0.55),
                        rankColor.withValues(alpha: 0.15),
                      ],
                    )
                  : null,
              color: isTopThree ? null : sem.cardMuted,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isTopThree
                    ? rankColor.withValues(alpha: 0.6)
                    : sem.border.withValues(alpha: 0.65),
              ),
              boxShadow: isTopThree
                  ? [
                      BoxShadow(
                        color: rankColor.withValues(alpha: 0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: isTopThree
                  ? Icon(Icons.emoji_events_rounded,
                      color: sem.textOnBrand, size: 24)
                  : Text(
                      '#$rank',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: sem.textSecondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          LeaderboardUserAvatar(
            displayName: name,
            imageUrl: entry['avatar'] as String?,
            avatarFrameId: entry['avatarFrameId'] as String?,
            size: 44,
            onTap: userId != null && userId.isNotEmpty ? openProfile : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap:
                      userId != null && userId.isNotEmpty ? openProfile : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Text(
                    entry['fullName'] ?? 'Anonymous',
                    style: AppTextStyles.labelLarge.copyWith(
                        color: isTopThree ? rankColor : sem.textPrimary),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (entry['currentStreak'] != null &&
                        entry['currentStreak'] > 0) ...[
                      Icon(Icons.local_fire_department_rounded,
                          size: 14, color: sem.warning),
                      const SizedBox(width: 4),
                      Text('${entry['currentStreak']}',
                          style: AppTextStyles.caption
                              .copyWith(color: sem.textSecondary)),
                      const SizedBox(width: 12),
                    ],
                    if (entry['coins'] != null) ...[
                      const GtuCoinIcon(size: 14),
                      const SizedBox(width: 4),
                      Text('${entry['coins']}',
                          style: AppTextStyles.caption
                              .copyWith(color: sem.textSecondary)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  sem.gold.withValues(alpha: 0.38),
                  sem.gold.withValues(alpha: 0.1),
                ],
              ),
              border: Border.all(
                color: sem.gold.withValues(alpha: 0.45),
              ),
              boxShadow: [
                BoxShadow(
                  color: sem.gold.withValues(alpha: 0.22),
                  blurRadius: 7,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.star_rounded, color: sem.gold, size: 18),
                const SizedBox(width: 4),
                Text(
                  '${entry['totalXP'] ?? 0}',
                  style: AppTextStyles.numberMedium.copyWith(
                    color: sem.gold,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty state — tránh dùng widget chung phẳng.
class _LeaderboardEmptyState extends StatelessWidget {
  const _LeaderboardEmptyState();

  @override
  Widget build(BuildContext context) {
    final sem = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    sem.gold.withValues(alpha: 0.4),
                    sem.card,
                  ],
                ),
                border: Border.all(
                  color: sem.brand.withValues(alpha: 0.35),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                Icons.emoji_events_rounded,
                size: 52,
                color: sem.gold.withValues(alpha: 0.95),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Chưa có dữ liệu',
              style: AppTextStyles.h4.copyWith(
                color: sem.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bảng xếp hạng sẽ được cập nhật khi có người dùng',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: sem.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
