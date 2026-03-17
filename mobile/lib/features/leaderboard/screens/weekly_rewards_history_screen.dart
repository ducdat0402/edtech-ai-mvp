import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/core/widgets/error_widget.dart';
import 'package:edtech_mobile/theme/theme.dart';

class WeeklyRewardsHistoryScreen extends StatefulWidget {
  const WeeklyRewardsHistoryScreen({super.key});

  @override
  State<WeeklyRewardsHistoryScreen> createState() =>
      _WeeklyRewardsHistoryScreenState();
}

class _WeeklyRewardsHistoryScreenState
    extends State<WeeklyRewardsHistoryScreen> {
  Map<String, dynamic>? _historyData;
  Map<String, dynamic>? _badgesData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final results = await Future.wait([
        api.getWeeklyRewardHistory(limit: 50),
        api.getWeeklyBadges(),
      ]);
      setState(() {
        _historyData = results[0];
        _badgesData = results[1];
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Phần thưởng tuần',
            style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.purpleNeon))
          : _error != null
              ? AppErrorWidget(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(child: _buildStats()),
                      SliverToBoxAdapter(child: _buildBadgeCollection()),
                      SliverToBoxAdapter(child: _buildHistoryHeader()),
                      _buildHistoryList(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStats() {
    final stats = _historyData?['stats'] as Map<String, dynamic>? ?? {};
    final totalDiamonds = stats['totalDiamonds'] ?? 0;
    final totalWeeks = stats['totalWeeks'] ?? 0;
    final bestRank = stats['bestRank'] ?? 0;
    final topThreeCount = stats['topThreeCount'] ?? 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.purpleNeon.withOpacity(0.8),
            AppColors.cyanNeon.withOpacity(0.6),
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
          Text('Tổng quan',
              style: AppTextStyles.h4.copyWith(color: Colors.white)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _StatItem(
                icon: Icons.diamond_rounded,
                iconColor: Colors.lightBlueAccent,
                value: '$totalDiamonds',
                label: 'Kim cương',
              )),
              Expanded(child: _StatItem(
                icon: Icons.calendar_month_rounded,
                iconColor: Colors.greenAccent,
                value: '$totalWeeks',
                label: 'Tuần',
              )),
              Expanded(child: _StatItem(
                icon: Icons.emoji_events_rounded,
                iconColor: Colors.amber,
                value: bestRank > 0 ? '#$bestRank' : '--',
                label: 'Hạng cao nhất',
              )),
              Expanded(child: _StatItem(
                icon: Icons.workspace_premium_rounded,
                iconColor: Colors.orangeAccent,
                value: '$topThreeCount',
                label: 'Top 3',
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeCollection() {
    final collection = _badgesData?['collection'] as List? ?? [];
    if (collection.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('Bộ sưu tập huy hiệu',
              style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary)),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: collection.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final b = collection[i] as Map<String, dynamic>;
              return _BadgeCard(
                name: b['name'] ?? '',
                iconUrl: b['iconUrl'] ?? '🏅',
                count: b['count'] ?? 1,
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildHistoryHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text('Lịch sử phần thưởng',
          style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary)),
    );
  }

  Widget _buildHistoryList() {
    final items = _historyData?['items'] as List? ?? [];
    if (items.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Text('Chưa có phần thưởng nào',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (_, i) {
          final item = items[i] as Map<String, dynamic>;
          return _HistoryItem(item: item);
        },
        childCount: items.length,
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  const _StatItem({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(height: 6),
        Text(value, style: AppTextStyles.numberMedium.copyWith(color: Colors.white)),
        const SizedBox(height: 2),
        Text(label,
            style: AppTextStyles.caption.copyWith(color: Colors.white70, fontSize: 10),
            textAlign: TextAlign.center),
      ],
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final String name;
  final String iconUrl;
  final int count;
  const _BadgeCard({required this.name, required this.iconUrl, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.purpleNeon.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.purpleNeon.withOpacity(0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(iconUrl, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 4),
          Text(name,
              style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
              maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
          if (count > 1)
            Text('${count}x',
                style: AppTextStyles.caption.copyWith(color: AppColors.purpleNeon, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final Map<String, dynamic> item;
  const _HistoryItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final rank = item['rank'] ?? 0;
    final diamonds = item['diamondsAwarded'] ?? 0;
    final weekCode = item['weekCode'] ?? '';
    final badge = item['badgeCode'];
    final xp = item['weeklyXp'] ?? 0;

    Color rankColor;
    if (rank == 1) {
      rankColor = AppColors.rankGold;
    } else if (rank == 2) {
      rankColor = AppColors.rankSilver;
    } else if (rank == 3) {
      rankColor = AppColors.rankBronze;
    } else {
      rankColor = AppColors.textSecondary;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
        border: rank <= 3
            ? Border.all(color: rankColor.withOpacity(0.4))
            : Border.all(color: AppColors.borderPrimary),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: rankColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text('#$rank',
                  style: AppTextStyles.labelLarge.copyWith(color: rankColor)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(weekCode,
                    style: AppTextStyles.labelMedium.copyWith(color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text('$xp XP',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.diamond_rounded, size: 16, color: Colors.lightBlueAccent),
                  const SizedBox(width: 4),
                  Text('+$diamonds',
                      style: AppTextStyles.labelMedium.copyWith(color: Colors.lightBlueAccent)),
                ],
              ),
              if (badge != null)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Icon(Icons.workspace_premium_rounded, size: 18, color: Colors.amber),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
