import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/core/widgets/bottom_nav_bar.dart';
import 'package:edtech_mobile/core/widgets/error_widget.dart';
import 'package:edtech_mobile/core/widgets/empty_state.dart';
import 'package:edtech_mobile/theme/theme.dart';

class DailyQuestsScreen extends StatefulWidget {
  const DailyQuestsScreen({super.key});

  @override
  State<DailyQuestsScreen> createState() => _DailyQuestsScreenState();
}

class _DailyQuestsScreenState extends State<DailyQuestsScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic>? _dailyQuests;
  List<dynamic>? _questHistory;
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;
  bool _isClaiming = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadQuests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadQuests() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      
      final dailyQuests = await apiService.getDailyQuests();
      final questHistory = await apiService.getQuestHistory();

      setState(() {
        _dailyQuests = dailyQuests;
        _questHistory = questHistory;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _claimQuest(String userQuestId) async {
    if (_isClaiming) return;

    setState(() => _isClaiming = true);

    try {
      HapticFeedback.heavyImpact();
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.claimQuest(userQuestId);

      await _loadQuests();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.celebration, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Đã nhận phần thưởng!'),
              ],
            ),
            backgroundColor: AppColors.successNeon,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: AppColors.errorNeon,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isClaiming = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Daily Quests', style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.cyanNeon,
          indicatorWeight: 3,
          labelColor: AppColors.textPrimary,
          unselectedLabelColor: AppColors.textTertiary,
          labelStyle: AppTextStyles.labelMedium,
          tabs: const [
            Tab(text: 'Hôm nay', icon: Icon(Icons.today_rounded, size: 20)),
            Tab(text: 'Lịch sử', icon: Icon(Icons.history_rounded, size: 20)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: _loadQuests,
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _error != null
              ? AppErrorWidget(message: _error!, onRetry: _loadQuests)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDailyQuestsTab(),
                    _buildHistoryTab(),
                  ],
                ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.cyanNeon),
          const SizedBox(height: 16),
          Text('Đang tải quests...', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildDailyQuestsTab() {
    if (_dailyQuests == null || _dailyQuests!.isEmpty) {
      return const EmptyQuestsWidget();
    }

    return RefreshIndicator(
      onRefresh: _loadQuests,
      color: AppColors.cyanNeon,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _dailyQuests!.length,
        itemBuilder: (context, index) {
          final questData = _dailyQuests![index] as Map<String, dynamic>;
          return StaggeredListItem(
            index: index,
            child: _QuestCard(
              questData: questData,
              onClaim: () => _claimQuest(questData['id'] as String),
              isClaiming: _isClaiming,
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_questHistory == null || _questHistory!.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.history_rounded,
        title: 'Chưa có lịch sử quest',
        message: 'Lịch sử quest sẽ được hiển thị ở đây',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadQuests,
      color: AppColors.cyanNeon,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _questHistory!.length,
        itemBuilder: (context, index) {
          final questData = _questHistory![index] as Map<String, dynamic>;
          return _QuestHistoryCard(questData: questData);
        },
      ),
    );
  }
}

class _QuestCard extends StatelessWidget {
  final Map<String, dynamic> questData;
  final VoidCallback onClaim;
  final bool isClaiming;

  const _QuestCard({
    required this.questData,
    required this.onClaim,
    required this.isClaiming,
  });

  @override
  Widget build(BuildContext context) {
    final quest = questData['quest'] as Map<String, dynamic>;
    final progress = questData['progress'] as int? ?? 0;
    final target = questData['target'] as int? ?? quest['requirements']?['target'] ?? 1;
    final status = questData['status'] as String? ?? 'active';
    final isCompleted = progress >= target;
    final canClaim = isCompleted && status == 'completed';
    final isClaimed = status == 'claimed';

    final questType = quest['type'] as String? ?? '';
    final icon = _getQuestIcon(questType);
    final color = _getQuestColor(questType);
    final progressPercent = (progress / target).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isClaimed
              ? AppColors.successNeon.withOpacity(0.5)
              : canClaim
                  ? color.withOpacity(0.5)
                  : AppColors.borderPrimary,
          width: canClaim || isClaimed ? 2 : 1,
        ),
        boxShadow: canClaim
            ? [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Quest icon
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quest['title'] ?? 'Quest',
                        style: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary),
                      ),
                      if (quest['description'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          quest['description'] ?? '',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isClaimed)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.successNeon.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded, color: AppColors.successNeon, size: 24),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            // Progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$progress / $target',
                      style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary),
                    ),
                    Text(
                      '${(progressPercent * 100).round()}%',
                      style: AppTextStyles.labelMedium.copyWith(color: color, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Stack(
                  children: [
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.bgTertiary,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    AnimatedProgressBox(
                      widthFactor: progressPercent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.5),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Rewards
            if (quest['rewards'] != null) ...[
              _buildRewards(quest['rewards'] as Map<String, dynamic>),
              const SizedBox(height: 16),
            ],
            // Claim button
            if (canClaim)
              GamingButton(
                text: 'Nhận phần thưởng',
                onPressed: isClaiming ? null : onClaim,
                isLoading: isClaiming,
                gradient: LinearGradient(colors: [color, color.withOpacity(0.8)]),
                glowColor: color,
                icon: Icons.card_giftcard_rounded,
              )
            else if (isClaimed)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.successNeon.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.successNeon.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_rounded, color: AppColors.successNeon, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Đã nhận phần thưởng',
                      style: AppTextStyles.labelMedium.copyWith(color: AppColors.successNeon),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewards(Map<String, dynamic> rewards) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.xpGold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.xpGold.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded, color: AppColors.xpGold, size: 20),
          const SizedBox(width: 10),
          Text('Phần thưởng:', style: AppTextStyles.labelMedium.copyWith(color: AppColors.xpGold)),
          const Spacer(),
          if (rewards['xp'] != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.xpGold.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star_rounded, size: 14, color: AppColors.xpGold),
                  const SizedBox(width: 4),
                  Text(
                    '+${rewards['xp']} XP',
                    style: AppTextStyles.labelSmall.copyWith(color: AppColors.xpGold, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
          if (rewards['coin'] != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.coinGold.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.monetization_on_rounded, size: 14, color: AppColors.coinGold),
                  const SizedBox(width: 4),
                  Text(
                    '+${rewards['coin']}',
                    style: AppTextStyles.labelSmall.copyWith(color: AppColors.coinGold, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getQuestIcon(String type) {
    switch (type) {
      case 'complete_items':
        return Icons.checklist_rounded;
      case 'maintain_streak':
        return Icons.local_fire_department_rounded;
      case 'earn_coins':
        return Icons.monetization_on_rounded;
      case 'earn_xp':
        return Icons.star_rounded;
      case 'complete_node':
        return Icons.book_rounded;
      case 'complete_daily_lesson':
        return Icons.calendar_today_rounded;
      default:
        return Icons.task_alt_rounded;
    }
  }

  Color _getQuestColor(String type) {
    switch (type) {
      case 'complete_items':
        return AppColors.cyanNeon;
      case 'maintain_streak':
        return AppColors.streakOrange;
      case 'earn_coins':
        return AppColors.coinGold;
      case 'earn_xp':
        return AppColors.purpleNeon;
      case 'complete_node':
        return AppColors.successNeon;
      case 'complete_daily_lesson':
        return AppColors.infoNeon;
      default:
        return AppColors.textSecondary;
    }
  }
}

class _QuestHistoryCard extends StatelessWidget {
  final Map<String, dynamic> questData;

  const _QuestHistoryCard({required this.questData});

  @override
  Widget build(BuildContext context) {
    final quest = questData['quest'] as Map<String, dynamic>;
    final status = questData['status'] as String? ?? 'active';
    final completedAt = questData['completedAt'] as String?;
    final claimedAt = questData['claimedAt'] as String?;

    final questType = quest['type'] as String? ?? '';
    final icon = _getQuestIcon(questType);
    final color = _getQuestColor(questType);
    final isClaimed = status == 'claimed';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isClaimed ? AppColors.successNeon.withOpacity(0.3) : AppColors.borderPrimary,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          quest['title'] ?? 'Quest',
          style: AppTextStyles.labelMedium.copyWith(color: AppColors.textPrimary),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (completedAt != null)
              Text(
                'Hoàn thành: ${_formatDate(completedAt)}',
                style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
              ),
            if (claimedAt != null)
              Text(
                'Nhận thưởng: ${_formatDate(claimedAt)}',
                style: AppTextStyles.caption.copyWith(color: AppColors.successNeon),
              ),
          ],
        ),
        trailing: isClaimed
            ? const Icon(Icons.check_circle_rounded, color: AppColors.successNeon)
            : null,
      ),
    );
  }

  IconData _getQuestIcon(String type) {
    switch (type) {
      case 'complete_items':
        return Icons.checklist_rounded;
      case 'maintain_streak':
        return Icons.local_fire_department_rounded;
      case 'earn_coins':
        return Icons.monetization_on_rounded;
      case 'earn_xp':
        return Icons.star_rounded;
      case 'complete_node':
        return Icons.book_rounded;
      case 'complete_daily_lesson':
        return Icons.calendar_today_rounded;
      default:
        return Icons.task_alt_rounded;
    }
  }

  Color _getQuestColor(String type) {
    switch (type) {
      case 'complete_items':
        return AppColors.cyanNeon;
      case 'maintain_streak':
        return AppColors.streakOrange;
      case 'earn_coins':
        return AppColors.coinGold;
      case 'earn_xp':
        return AppColors.purpleNeon;
      case 'complete_node':
        return AppColors.successNeon;
      case 'complete_daily_lesson':
        return AppColors.infoNeon;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
