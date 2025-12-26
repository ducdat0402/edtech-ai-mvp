import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/core/widgets/bottom_nav_bar.dart';
import 'package:edtech_mobile/core/widgets/error_widget.dart';
import 'package:edtech_mobile/core/widgets/empty_state.dart';
import 'package:edtech_mobile/core/widgets/skeleton_loader.dart';

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

    setState(() {
      _isClaiming = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.claimQuest(userQuestId);

      // Reload quests
      await _loadQuests();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã nhận phần thưởng! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isClaiming = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Quests'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Hôm nay', icon: Icon(Icons.today)),
            Tab(text: 'Lịch sử', icon: Icon(Icons.history)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadQuests,
          ),
        ],
      ),
      body: _isLoading
          ? _buildSkeletonLoader()
          : _error != null
              ? AppErrorWidget(
                  message: _error!,
                  onRetry: _loadQuests,
                )
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

  Widget _buildSkeletonLoader() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) => SkeletonCard(height: 150),
    );
  }

  Widget _buildDailyQuestsTab() {
    if (_dailyQuests == null || _dailyQuests!.isEmpty) {
      return const EmptyQuestsWidget();
    }

    return RefreshIndicator(
      onRefresh: _loadQuests,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _dailyQuests!.length,
        itemBuilder: (context, index) {
          final questData = _dailyQuests![index] as Map<String, dynamic>;
          return _QuestCard(
            questData: questData,
            onClaim: () => _claimQuest(questData['id'] as String),
            isClaiming: _isClaiming,
          );
        },
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_questHistory == null || _questHistory!.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.history,
        title: 'Chưa có lịch sử quest',
        message: 'Lịch sử quest sẽ được hiển thị ở đây',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadQuests,
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

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quest['title'] ?? 'Quest',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (quest['description'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          quest['description'] ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isClaimed)
                  const Icon(Icons.check_circle, color: Colors.green, size: 32),
              ],
            ),
            const SizedBox(height: 16),
            // Progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tiến độ: $progress / $target',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      '${((progress / target) * 100).clamp(0, 100).round()}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (progress / target).clamp(0.0, 1.0),
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 8,
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isClaiming ? null : onClaim,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: isClaiming
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Nhận phần thưởng',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              )
            else if (isClaimed)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: const Center(
                  child: Text(
                    'Đã nhận phần thưởng',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewards(Map<String, dynamic> rewards) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.star, color: Colors.amber, size: 20),
          const SizedBox(width: 8),
          Text(
            'Phần thưởng: ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.amber.shade900,
            ),
          ),
          if (rewards['xp'] != null) ...[
            const SizedBox(width: 4),
            Text(
              '+${rewards['xp']} XP',
              style: TextStyle(
                fontSize: 14,
                color: Colors.amber.shade900,
              ),
            ),
          ],
          if (rewards['coin'] != null) ...[
            const SizedBox(width: 8),
            const Icon(Icons.monetization_on, size: 16, color: Colors.orange),
            const SizedBox(width: 4),
            Text(
              '+${rewards['coin']}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.amber.shade900,
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
        return Icons.checklist;
      case 'maintain_streak':
        return Icons.local_fire_department;
      case 'earn_coins':
        return Icons.monetization_on;
      case 'earn_xp':
        return Icons.star;
      case 'complete_node':
        return Icons.book;
      case 'complete_daily_lesson':
        return Icons.calendar_today;
      default:
        return Icons.task_alt;
    }
  }

  Color _getQuestColor(String type) {
    switch (type) {
      case 'complete_items':
        return Colors.blue;
      case 'maintain_streak':
        return Colors.orange;
      case 'earn_coins':
        return Colors.amber;
      case 'earn_xp':
        return Colors.purple;
      case 'complete_node':
        return Colors.green;
      case 'complete_daily_lesson':
        return Colors.teal;
      default:
        return Colors.grey;
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: status == 'claimed' ? Colors.green.shade50 : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(quest['title'] ?? 'Quest'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (completedAt != null)
              Text('Hoàn thành: ${_formatDate(completedAt)}'),
            if (claimedAt != null)
              Text('Đã nhận: ${_formatDate(claimedAt)}'),
          ],
        ),
        trailing: status == 'claimed'
            ? const Icon(Icons.check_circle, color: Colors.green)
            : null,
      ),
    );
  }

  IconData _getQuestIcon(String type) {
    switch (type) {
      case 'complete_items':
        return Icons.checklist;
      case 'maintain_streak':
        return Icons.local_fire_department;
      case 'earn_coins':
        return Icons.monetization_on;
      case 'earn_xp':
        return Icons.star;
      case 'complete_node':
        return Icons.book;
      case 'complete_daily_lesson':
        return Icons.calendar_today;
      default:
        return Icons.task_alt;
    }
  }

  Color _getQuestColor(String type) {
    switch (type) {
      case 'complete_items':
        return Colors.blue;
      case 'maintain_streak':
        return Colors.orange;
      case 'earn_coins':
        return Colors.amber;
      case 'earn_xp':
        return Colors.purple;
      case 'complete_node':
        return Colors.green;
      case 'complete_daily_lesson':
        return Colors.teal;
      default:
        return Colors.grey;
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

