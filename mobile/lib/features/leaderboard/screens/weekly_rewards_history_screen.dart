import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/core/widgets/app_bar_leading_back_home.dart';
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
    setState(() {
      _isLoading = true;
      _error = null;
    });
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
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
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
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryLight.withValues(alpha: 0.45),
                    AppColors.primaryLight.withValues(alpha: 0.08),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.purpleNeon.withValues(alpha: 0.22),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.history_rounded,
                color: AppColors.primaryLight,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Phần thưởng tuần',
                style: AppTextStyles.h4.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryLight))
          : _error != null
              ? AppErrorWidget(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.purpleNeon,
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
            AppColors.purpleNeon.withValues(alpha: 0.85),
            AppColors.cyanNeon.withValues(alpha: 0.55),
            AppColors.primaryLight.withValues(alpha: 0.35),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.purpleNeon.withValues(alpha: 0.38),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            offset: const Offset(0, 5),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Tổng quan',
            style: AppTextStyles.h4.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _StatItem(
                icon: Icons.diamond_rounded,
                iconColor: AppColors.primaryLight,
                value: '$totalDiamonds',
                label: 'Kim cương',
              )),
              Expanded(
                  child: _StatItem(
                icon: Icons.calendar_month_rounded,
                iconColor: AppColors.successNeon,
                value: '$totalWeeks',
                label: 'Tuần',
              )),
              Expanded(
                  child: _StatItem(
                icon: Icons.emoji_events_rounded,
                iconColor: AppColors.xpGold,
                value: bestRank > 0 ? '#$bestRank' : '--',
                label: 'Hạng cao nhất',
              )),
              Expanded(
                  child: _StatItem(
                icon: Icons.workspace_premium_rounded,
                iconColor: AppColors.orangeNeon,
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
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.orangeNeon.withValues(alpha: 0.35),
                      AppColors.orangeNeon.withValues(alpha: 0.1),
                    ],
                  ),
                  border: Border.all(
                    color: AppColors.orangeNeon.withValues(alpha: 0.4),
                  ),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppColors.xpGold,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Bộ sưu tập huy hiệu',
                style: AppTextStyles.h4.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                colors: [
                  AppColors.purpleNeon.withValues(alpha: 0.35),
                  AppColors.purpleNeon.withValues(alpha: 0.08),
                ],
              ),
              border: Border.all(
                color: AppColors.purpleNeon.withValues(alpha: 0.35),
              ),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: AppColors.primaryLight,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Lịch sử phần thưởng',
            style: AppTextStyles.h4.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    final items = _historyData?['items'] as List? ?? [];
    if (items.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primaryLight.withValues(alpha: 0.35),
                        AppColors.bgSecondary,
                      ],
                    ),
                    border: Border.all(
                      color: AppColors.purpleNeon.withValues(alpha: 0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.card_giftcard_rounded,
                    size: 48,
                    color: AppColors.primaryLight.withValues(alpha: 0.95),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Chưa có phần thưởng nào',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.h4.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tham gia bảng XP hàng tuần để nhận kim cương và huy hiệu.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
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
        Text(value,
            style: AppTextStyles.numberMedium.copyWith(color: Colors.white)),
        const SizedBox(height: 2),
        Text(label,
            style: AppTextStyles.caption
                .copyWith(color: Colors.white70, fontSize: 10),
            textAlign: TextAlign.center),
      ],
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final String name;
  final String iconUrl;
  final int count;
  const _BadgeCard(
      {required this.name, required this.iconUrl, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.purpleNeon.withValues(alpha: 0.12),
            AppColors.bgSecondary,
          ],
        ),
        border: Border.all(
          color: AppColors.purpleNeon.withValues(alpha: 0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(iconUrl, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 4),
          Text(name,
              style:
                  AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center),
          if (count > 1)
            Text('${count}x',
                style: AppTextStyles.caption.copyWith(
                    color: AppColors.purpleNeon, fontWeight: FontWeight.bold)),
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            rank <= 3
                ? rankColor.withValues(alpha: 0.12)
                : AppColors.purpleNeon.withValues(alpha: 0.06),
            AppColors.bgSecondary,
          ],
        ),
        border: Border.all(
          color: rank <= 3
              ? rankColor.withValues(alpha: 0.45)
              : const Color(0x332D363D),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            offset: const Offset(0, 4),
            blurRadius: 9,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  rankColor.withValues(alpha: 0.45),
                  rankColor.withValues(alpha: 0.12),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: rankColor.withValues(alpha: 0.5),
              ),
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
                    style: AppTextStyles.labelMedium
                        .copyWith(color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text('$xp XP',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.diamond_rounded,
                      size: 16, color: AppColors.primaryLight),
                  const SizedBox(width: 4),
                  Text('+$diamonds',
                      style: AppTextStyles.labelMedium
                          .copyWith(color: AppColors.primaryLight)),
                ],
              ),
              if (badge != null)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Icon(Icons.workspace_premium_rounded,
                      size: 18, color: AppColors.xpGold),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
