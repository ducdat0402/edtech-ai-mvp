import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/core/services/auth_service.dart';
import 'package:edtech_mobile/core/widgets/bottom_nav_bar.dart';
import 'package:edtech_mobile/core/widgets/error_widget.dart';
import 'package:edtech_mobile/core/widgets/skeleton_loader.dart';
import 'package:edtech_mobile/theme/theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;
  String? _error;
  String _userRole = 'user';

  bool get _isContributor => _userRole == 'contributor';

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final results = await Future.wait([
        apiService.getDashboard(),
        apiService.getUserProfile(),
      ]);
      setState(() {
        _dashboardData = results[0];
        final profile = results[1];
        _userRole = profile['role'] as String? ?? 'user';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.logout();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.push('/profile'),
            tooltip: 'Profile',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboard,
            tooltip: 'Refresh',
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'logout') {
                _handleLogout();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? _buildSkeletonLoader()
          : _error != null
              ? AppErrorWidget(
                  message: _error!,
                  onRetry: _loadDashboard,
                )
              : _dashboardData == null
                  ? const Center(child: Text('No data available'))
                  : RefreshIndicator(
                      onRefresh: _loadDashboard,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Stats Cards (includes Level and Stats)
                            _buildStatsSection(_dashboardData!['stats'] ?? {}),
                            const SizedBox(height: 24),

                            // Onboarding Banner (if not complete)
                            _buildOnboardingBanner(),
                            const SizedBox(height: 24),

                            // Quick Actions
                            _buildQuickActions(),
                            const SizedBox(height: 24),

                            // Current Learning (nodes in progress)
                            _buildCurrentLearningSection(
                                _dashboardData!['currentLearningNodes'] ?? []),
                            const SizedBox(height: 24),

                            // Daily Quests
                            _buildQuestsSection(
                                _dashboardData!['dailyQuests'] ?? []),
                            const SizedBox(height: 24),

                            // All Subjects
                            _buildSubjectsSection(
                              'Môn học',
                              _dashboardData!['subjects'] ?? [],
                            ),
                          ],
                        ),
                      ),
                    ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildSkeletonLoader() {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonCard(height: 120),
          SizedBox(height: 24),
          SkeletonCard(height: 100),
          SizedBox(height: 24),
          SkeletonCard(height: 150),
          SizedBox(height: 24),
          SkeletonCard(height: 120),
        ],
      ),
    );
  }

  Widget _buildStatsSection(Map<String, dynamic> stats) {
    final level = stats['level'] as int? ?? 1;
    final levelInfo = stats['levelInfo'] as Map<String, dynamic>?;
    final currentXP = levelInfo?['currentXP'] as int? ?? 0;
    final xpForNextLevel = levelInfo?['xpForNextLevel'] as int? ?? 100;
    final totalXP = stats['totalXP'] as int? ?? 0;
    final coins = stats['totalCoins'] ?? stats['coins'] ?? 0;
    final streak = stats['currentStreak'] ?? stats['streak'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Level Card using new widget
        GestureDetector(
          onTap: () => _showLevelTitlesDialog(),
          child: LevelCard(
            level: level,
            title: _getLevelTitle(level),
            currentXP: currentXP,
            xpForNextLevel: xpForNextLevel,
            totalXP: totalXP,
          ),
        ),
        const SizedBox(height: 20),

        // Stats Row with new widgets
        Row(
          children: [
            // XP Display
            Expanded(
              child: _buildStatCard(
                icon: Icons.star_rounded,
                label: 'XP',
                value: totalXP,
                color: AppColors.xpGold,
                onTap: () => context.push('/currency'),
              ),
            ),
            const SizedBox(width: 12),
            // Coins Display
            Expanded(
              child: _buildStatCard(
                icon: Icons.monetization_on_rounded,
                label: 'Coins',
                value: coins is int ? coins : 0,
                color: AppColors.coinGold,
                onTap: () => context.push('/currency'),
              ),
            ),
            const SizedBox(width: 12),
            // Streak Display
            Expanded(
              child: _buildStatCard(
                icon: Icons.local_fire_department_rounded,
                label: 'Streak',
                value: streak is int ? streak : 0,
                color: AppColors.streakOrange,
                onTap: () => context.push('/currency'),
                suffix: '🔥',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required int value,
    required Color color,
    VoidCallback? onTap,
    String? suffix,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderPrimary),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$value',
                  style: AppTextStyles.numberMedium.copyWith(color: color),
                ),
                if (suffix != null) ...[
                  const SizedBox(width: 2),
                  Text(suffix, style: const TextStyle(fontSize: 14)),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.labelSmall,
            ),
          ],
        ),
      ),
    );
  }

  String _getLevelTitle(int level) {
    if (level <= 5) return 'Người mới';
    if (level <= 10) return 'Học viên';
    if (level <= 20) return 'Sinh viên';
    if (level <= 35) return 'Chuyên gia';
    if (level <= 50) return 'Bậc thầy';
    if (level <= 75) return 'Huyền thoại';
    return 'Thần đồng';
  }

  void _showLevelTitlesDialog() {
    final currentLevel = (_dashboardData?['stats']?['level'] as int?) ?? 1;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.military_tech,
                        color: Colors.amber.shade700, size: 28),
                    const SizedBox(width: 8),
                    const Text(
                      'Danh hiệu',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Level hiện tại: $currentLevel',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 16),
                _buildLevelTitleRow('Người mới', '1 - 5', Icons.emoji_people,
                    Colors.green, currentLevel >= 1 && currentLevel <= 5),
                _buildLevelTitleRow('Học viên', '6 - 10', Icons.school,
                    Colors.blue, currentLevel >= 6 && currentLevel <= 10),
                _buildLevelTitleRow('Sinh viên', '11 - 20', Icons.menu_book,
                    Colors.indigo, currentLevel >= 11 && currentLevel <= 20),
                _buildLevelTitleRow('Chuyên gia', '21 - 35', Icons.psychology,
                    Colors.purple, currentLevel >= 21 && currentLevel <= 35),
                _buildLevelTitleRow(
                    'Bậc thầy',
                    '36 - 50',
                    Icons.workspace_premium,
                    Colors.orange,
                    currentLevel >= 36 && currentLevel <= 50),
                _buildLevelTitleRow(
                    'Huyền thoại',
                    '51 - 75',
                    Icons.auto_awesome,
                    Colors.red,
                    currentLevel >= 51 && currentLevel <= 75),
                _buildLevelTitleRow('Thần đồng', '76+', Icons.diamond,
                    Colors.amber, currentLevel >= 76),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Đóng'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLevelTitleRow(String title, String levelRange, IconData icon,
      Color color, bool isCurrent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCurrent
              ? [color.withOpacity(0.2), color.withOpacity(0.1)]
              : [color.withOpacity(0.08), color.withOpacity(0.03)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCurrent ? color : color.withOpacity(0.3),
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(isCurrent ? 0.3 : 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                    color: color.withOpacity(isCurrent ? 1 : 0.8),
                  ),
                ),
                Text(
                  'Level $levelRange',
                  style: TextStyle(
                    fontSize: 11,
                    color: color.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          if (isCurrent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Hiện tại',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOnboardingBanner() {
    // Onboarding đã được tích hợp vào Personal Mind Map screen
    // Không hiển thị banner ở dashboard nữa
    return const SizedBox.shrink();
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: AppTextStyles.h3,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.task_alt_rounded,
                label: 'Quests',
                color: AppColors.cyanNeon,
                onTap: () => context.push('/quests'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                icon: Icons.leaderboard_rounded,
                label: 'Leaderboard',
                color: AppColors.purpleNeon,
                onTap: () => context.push('/leaderboard'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                icon: Icons.account_balance_wallet_rounded,
                label: 'Currency',
                color: AppColors.coinGold,
                onTap: () => context.push('/currency'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuestsSection(List<dynamic> quests) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Daily Quests',
              style: AppTextStyles.h3,
            ),
            TextButton(
              onPressed: () => context.push('/quests'),
              child: const Text('Xem tất cả'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (quests.isEmpty)
          const Text('No quests available')
        else
          ...quests.take(3).map((quest) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.task_alt),
                  title: Text(quest['quest']?['title'] ?? 'Quest'),
                  subtitle: Text(
                    'Progress: ${quest['progress'] ?? 0}/${quest['target'] ?? 0}',
                  ),
                  trailing: quest['status'] == 'completed'
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                  onTap: () => context.push('/quests'),
                ),
              )),
      ],
    );
  }

  Widget _buildCurrentLearningSection(List<dynamic> nodes) {
    if (nodes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Topic đang học',
          style: AppTextStyles.h3,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: nodes.length,
            itemBuilder: (context, index) {
              final node = nodes[index];
              final nodeId = node['id'] as String?;
              final title = node['title'] as String? ?? 'Bài học';
              final subjectName = node['subjectName'] as String? ?? '';
              final progress = node['progress'] as int? ?? 0;
              final icon = node['icon'] as String? ?? '📖';

              return SlideIn(
                delay: Duration(milliseconds: 50 * index),
                beginOffset: const Offset(30, 0),
                child: Container(
                  width: 280,
                  margin: const EdgeInsets.only(right: 12),
                  child: Card(
                    elevation: 2,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        if (nodeId != null) {
                          context.push('/nodes/$nodeId');
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  icon,
                                  style: const TextStyle(fontSize: 24),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        subjectName,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        title,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          height: 1.3,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            const SizedBox(height: 12),
                            // Progress bar
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Tiến độ',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    Text(
                                      '$progress%',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: progress / 100,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.blue.shade400,
                                  ),
                                  minHeight: 6,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectsSection(String title, List<dynamic> subjects) {
    final totalCount = subjects.length + (_isContributor ? 1 : 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: AppTextStyles.h3),
            if (_isContributor) ...[
              const Spacer(),
              GestureDetector(
                onTap: () => context.push('/contributor/my-contributions'),
                child: Row(
                  children: [
                    const Icon(Icons.list_alt,
                        size: 16, color: AppColors.contributorBlue),
                    const SizedBox(width: 4),
                    Text(
                      'Đóng góp',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.contributorBlue),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        if (subjects.isEmpty && !_isContributor)
          Center(
            child: Column(
              children: [
                Icon(Icons.school_outlined,
                    size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'Chưa có môn học nào',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: totalCount,
              itemBuilder: (context, index) {
                // Add subject card for contributors
                if (_isContributor && index == subjects.length) {
                  return _buildAddSubjectCard();
                }

                final subject = subjects[index];
                final subjectId = subject['id'] as String?;
                final name = subject['name'] as String? ?? 'Môn học';
                final description = subject['description'] as String?;
                final metadata = subject['metadata'] as Map<String, dynamic>?;
                final icon = metadata?['icon'] as String? ?? '📚';
                final totalNodesCount = subject['totalNodesCount'] as int? ?? 0;
                final availableNodesCount =
                    subject['availableNodesCount'] as int? ?? 0;

                return SlideIn(
                  delay: Duration(milliseconds: 50 * index),
                  beginOffset: const Offset(30, 0),
                  child: Container(
                    width: 280,
                    margin: const EdgeInsets.only(right: 12),
                    child: Card(
                      elevation: 2,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          if (subjectId != null) {
                            context.push('/subjects/$subjectId/intro');
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Icon
                                  Text(
                                    icon,
                                    style: const TextStyle(fontSize: 32),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (description != null &&
                                  description.isNotEmpty) ...[
                                const SizedBox(height: 8),
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
                              if (totalNodesCount > 0) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.book,
                                        size: 14, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$availableNodesCount/$totalNodesCount bài học',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildAddSubjectCard() {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 0,
        color: AppColors.contributorBlue.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: AppColors.contributorBlue.withOpacity(0.3),
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            context.push('/contributor/create-subject');
          },
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.contributorBlue.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add,
                      size: 28, color: AppColors.contributorBlue),
                ),
                const SizedBox(height: 8),
                Text(
                  'Thêm môn học',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.contributorBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Đóng góp mới',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.contributorBlue.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderPrimary),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
