import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/core/widgets/app_bar_leading_back_home.dart';
import 'package:edtech_mobile/core/widgets/bottom_nav_bar.dart';
import 'package:edtech_mobile/core/widgets/error_widget.dart';
import 'package:edtech_mobile/core/widgets/empty_state.dart';
import 'package:edtech_mobile/features/currency/screens/rewards_history_screen.dart';
import 'package:edtech_mobile/features/achievements/screens/achievements_screen.dart';
import 'package:edtech_mobile/features/chat/widgets/chat_bubble.dart';
import 'package:edtech_mobile/theme/theme.dart';

class CurrencyScreen extends StatefulWidget {
  const CurrencyScreen({super.key});

  @override
  State<CurrencyScreen> createState() => _CurrencyScreenState();
}

class _CurrencyScreenState extends State<CurrencyScreen> {
  Map<String, dynamic>? _currencyData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final data = await apiService.getCurrency();
      setState(() {
        _currencyData = data;
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
        title: Text(
          'Tiền tệ & Phần thưởng',
          style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: _loadCurrency,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primaryLight))
              : _error != null
                  ? AppErrorWidget(
                      message: _error!,
                      onRetry: _loadCurrency,
                    )
                  : _buildContent(),
          const FloatingChatBubble(),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildContent() {
    if (_currencyData == null) {
      return const EmptyStateWidget(
        title: 'Không có dữ liệu tiền tệ',
        icon: Icons.account_balance_wallet,
      );
    }

    final coins = _currencyData!['coins'] as int? ?? 0;
    final diamonds = _currencyData!['diamonds'] as int? ?? 0;
    final xp = _currencyData!['xp'] as int? ?? 0;
    final streak = _currencyData!['currentStreak'] as int? ?? 0;
    final maxStreak = _currencyData!['maxStreak'] as int? ?? 0;
    final shards = _currencyData!['shards'] as Map<String, dynamic>? ?? {};
    final lastActiveDate = _currencyData!['lastActiveDate'] as String?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeaderCard(coins, diamonds, xp, streak),

          const SizedBox(height: 24),

          _buildCurrencyCard(
            title: 'Xu',
            value: coins.toString(),
            icon: Icons.monetization_on,
            color: AppColors.orangeNeon,
            description: 'Kiếm qua học tập, dùng trong Cửa hàng',
          ),

          const SizedBox(height: 16),

          _buildCurrencyCard(
            title: 'Kim cương',
            value: diamonds.toString(),
            icon: Icons.diamond,
            color: AppColors.primaryLight,
            description: 'Mở khóa nội dung & tính năng AI',
          ),

          const SizedBox(height: 16),

          _buildCurrencyCard(
            title: 'Experience Points (XP)',
            value: xp.toString(),
            icon: Icons.star,
            color: AppColors.xpGold,
            description: 'Điểm kinh nghiệm',
          ),

          const SizedBox(height: 16),

          // Streak Card - chuỗi ngày học (tuần + countdown)
          StreakWeekCard(
            currentStreak: streak,
            maxStreak: maxStreak,
            lastActiveDate: lastActiveDate,
          ),

          const SizedBox(height: 24),

          // Shards Section
          _buildShardsSection(shards),

          const SizedBox(height: 24),

          // Info Card
          _buildInfoCard(),

          const SizedBox(height: 24),

          // Rewards History Button
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RewardsHistoryScreen(),
              ),
            ),
            icon: const Icon(Icons.history),
            label: const Text('Xem lịch sử phần thưởng'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),

          const SizedBox(height: 12),

          // Achievements Button
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AchievementsScreen(),
              ),
            ),
            icon: const Icon(Icons.emoji_events),
            label: const Text('Xem thành tựu'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.amber.shade700,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(int coins, int diamonds, int xp, int streak) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.purpleNeon.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Tổng quan',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.monetization_on,
                value: coins.toString(),
                label: 'Xu',
                color: Colors.amber,
              ),
              _buildStatItem(
                icon: Icons.diamond,
                value: diamonds.toString(),
                label: 'Kim cương',
                color: Colors.cyanAccent,
              ),
              _buildStatItem(
                icon: Icons.star,
                value: xp.toString(),
                label: 'XP',
                color: Colors.white,
              ),
              _buildStatItem(
                icon: Icons.local_fire_department,
                value: streak.toString(),
                label: 'Chuỗi ngày',
                color: Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrencyCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String description,
  }) {
    return Card(
      color: AppColors.bgSecondary,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0x332D363D)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.labelLarge.copyWith(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShardsSection(Map<String, dynamic> shards) {
    final shardEntries = shards.entries.toList();

    if (shardEntries.isEmpty) {
      return Card(
        color: AppColors.bgSecondary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0x332D363D)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(
                Icons.diamond_outlined,
                size: 48,
                color: AppColors.textTertiary,
              ),
              const SizedBox(height: 8),
              Text(
                'Chưa có Shards',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Hoàn thành bài học để nhận mảnh!',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textTertiary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      color: AppColors.bgSecondary,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0x332D363D)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.diamond, color: AppColors.primaryLight),
                const SizedBox(width: 8),
                Text(
                  'Mảnh',
                  style:
                      AppTextStyles.h4.copyWith(color: AppColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: shardEntries.map((entry) {
                return _buildShardChip(
                  name: entry.key,
                  count: entry.value as int,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShardChip({required String name, required int count}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.purpleNeon.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: AppColors.primaryLight.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.diamond, size: 20, color: AppColors.primaryLight),
          const SizedBox(width: 8),
          Text(
            _formatShardName(name),
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.purpleNeon,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 0,
      color: AppColors.bgSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0x332D363D)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, color: AppColors.primaryLight),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cách kiếm phần thưởng',
                    style: AppTextStyles.labelLarge
                        .copyWith(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• Hoàn thành bài học để nhận XP và xu\n'
                    '• Xu dùng để mua vật phẩm trong cửa hàng\n'
                    '• Kim cương dùng để mở khóa nội dung & AI\n'
                    '• Học đều đặn để tăng chuỗi ngày',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary, height: 1.45),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatShardName(String name) {
    // Convert "ai-shard" to "AI Shard"
    return name
        .split('-')
        .map((word) =>
            word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
