import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/core/widgets/error_widget.dart';
import 'package:edtech_mobile/core/widgets/empty_state.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  List<dynamic> _achievements = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);

      // Check for new achievements first
      await apiService.checkAchievements();

      // Load achievements with status
      final achievements = await apiService.getAchievements();
      setState(() {
        _achievements = achievements;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _claimRewards(String userAchievementId) async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.claimAchievementRewards(userAchievementId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã nhận phần thưởng!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadAchievements(); // Reload to update status
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
    }
  }

  Color _getRarityColor(String rarity) {
    switch (rarity) {
      case 'common':
        return Colors.grey;
      case 'uncommon':
        return Colors.green;
      case 'rare':
        return Colors.blue;
      case 'epic':
        return Colors.purple;
      case 'legendary':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'milestone':
        return Icons.flag;
      case 'streak':
        return Icons.local_fire_department;
      case 'completion':
        return Icons.check_circle;
      case 'perfect_score':
        return Icons.star;
      case 'collection':
        return Icons.collections;
      case 'social':
        return Icons.people;
      case 'quest_master':
        return Icons.task_alt;
      default:
        return Icons.emoji_events;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thành tựu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAchievements,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? AppErrorWidget(
                  message: _error!,
                  onRetry: _loadAchievements,
                )
              : _achievements.isEmpty
                  ? const EmptyStateWidget(
                      title: 'Chưa có thành tựu',
                      icon: Icons.emoji_events,
                      message: 'Hoàn thành các mục tiêu để mở khóa thành tựu!',
                    )
                  : RefreshIndicator(
                      onRefresh: _loadAchievements,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _achievements.length,
                        itemBuilder: (context, index) {
                          return _buildAchievementCard(_achievements[index]);
                        },
                      ),
                    ),
    );
  }

  Widget _buildAchievementCard(Map<String, dynamic> data) {
    final achievement = data['achievement'] as Map<String, dynamic>;
    final unlocked = data['unlocked'] as bool? ?? false;
    final unlockedAt = data['unlockedAt'] as String?;
    final rewardsClaimed = data['rewardsClaimed'] as bool? ?? false;

    final name = achievement['name'] as String? ?? 'Unknown';
    final description = achievement['description'] as String? ?? '';
    final type = achievement['type'] as String? ?? '';
    final rarity = achievement['rarity'] as String? ?? 'common';
    final rewards = achievement['rewards'] as Map<String, dynamic>? ?? {};
    final iconUrl = achievement['iconUrl'] as String?;

    final rarityColor = _getRarityColor(rarity);
    final typeIcon = _getTypeIcon(type);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: unlocked ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: unlocked
            ? BorderSide(color: rarityColor, width: 2)
            : BorderSide.none,
      ),
      child: Opacity(
        opacity: unlocked ? 1.0 : 0.6,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon/Badge
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: unlocked
                      ? rarityColor.withOpacity(0.2)
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                  border: unlocked
                      ? Border.all(color: rarityColor, width: 2)
                      : null,
                ),
                child: iconUrl != null && iconUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          iconUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(typeIcon, color: rarityColor, size: 32),
                        ),
                      )
                    : Icon(typeIcon, color: rarityColor, size: 32),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: unlocked ? null : Colors.grey,
                            ),
                          ),
                        ),
                        if (unlocked)
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          ),
                      ],
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (unlocked && unlockedAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(unlockedAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                    if (unlocked && rewards.isNotEmpty && !rewardsClaimed) ...[
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          final userAchievementId = data['id'] as String?;
                          if (userAchievementId != null) {
                            _claimRewards(userAchievementId);
                          }
                        },
                        icon: const Icon(Icons.card_giftcard, size: 16),
                        label: const Text('Nhận thưởng'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: rarityColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                    if (unlocked && rewardsClaimed) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Đã nhận phần thưởng',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green.shade700,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return 'Mở khóa: ${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
