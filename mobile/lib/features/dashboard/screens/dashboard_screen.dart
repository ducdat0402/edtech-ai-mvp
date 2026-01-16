import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/core/services/auth_service.dart';
import 'package:edtech_mobile/core/widgets/streak_display.dart';
import 'package:edtech_mobile/core/widgets/bottom_nav_bar.dart';
import 'package:edtech_mobile/core/widgets/error_widget.dart';
import 'package:edtech_mobile/core/widgets/skeleton_loader.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final data = await apiService.getDashboard();
      setState(() {
        _dashboardData = data;
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
                            // Streak Display
                            _buildStreakSection(_dashboardData!['stats'] ?? {}),
                            const SizedBox(height: 24),

                            // Stats Cards
                            _buildStatsSection(_dashboardData!['stats'] ?? {}),
                            const SizedBox(height: 24),

                            // Onboarding Banner (if not complete)
                            _buildOnboardingBanner(),
                            const SizedBox(height: 24),

                            // Quick Actions
                            _buildQuickActions(),
                            const SizedBox(height: 24),

                            // Current Learning (nodes in progress)
                            _buildCurrentLearningSection(_dashboardData!['currentLearningNodes'] ?? []),
                            const SizedBox(height: 24),

                            // Daily Quests
                            _buildQuestsSection(_dashboardData!['dailyQuests'] ?? []),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonCard(height: 120),
          const SizedBox(height: 24),
          SkeletonCard(height: 100),
          const SizedBox(height: 24),
          SkeletonCard(height: 150),
          const SizedBox(height: 24),
          SkeletonCard(height: 120),
        ],
      ),
    );
  }

  Widget _buildStreakSection(Map<String, dynamic> stats) {
    final streak = stats['streak'] ?? 0;
    final consecutivePerfect = stats['consecutivePerfect'] ?? 0;
    final weeklyProgress = stats['weeklyProgress'] as Map<String, dynamic>?;

    return StreakDisplay(
      streak: streak is int ? streak : int.tryParse(streak.toString()) ?? 0,
      consecutivePerfect: consecutivePerfect is int
          ? consecutivePerfect
          : int.tryParse(consecutivePerfect.toString()) ?? 0,
      weeklyProgress: weeklyProgress,
    );
  }

  Widget _buildStatsSection(Map<String, dynamic> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Stats',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.star,
                label: 'XP',
                value: '${stats['totalXP'] ?? 0}',
                color: Colors.amber,
                onTap: () => context.push('/currency'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.monetization_on,
                label: 'Coins',
                value: '${stats['coins'] ?? 0}',
                color: Colors.orange,
                onTap: () => context.push('/currency'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.local_fire_department,
                label: 'Streak',
                value: '${stats['streak'] ?? 0}',
                color: Colors.red,
                onTap: () => context.push('/currency'),
              ),
            ),
          ],
        ),
      ],
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
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.task_alt,
                label: 'Quests',
                color: Colors.blue,
                onTap: () => context.push('/quests'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                icon: Icons.leaderboard,
                label: 'Leaderboard',
                color: Colors.purple,
                onTap: () => context.push('/leaderboard'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                icon: Icons.account_tree,
                label: 'Skill Tree',
                color: Colors.teal,
                onTap: () => context.push('/skill-tree'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.account_balance_wallet,
                label: 'Currency',
                color: Colors.amber,
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
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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

              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 12),
                child: Card(
                  elevation: 2,
                  child: InkWell(
                    onTap: () {
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectsSection(String title, List<dynamic> subjects) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (subjects.isEmpty)
          Center(
            child: Column(
              children: [
                Icon(Icons.school_outlined, size: 64, color: Colors.grey.shade400),
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
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                final subject = subjects[index];
                final subjectId = subject['id'] as String?;
                final name = subject['name'] as String? ?? 'Môn học';
                final description = subject['description'] as String?;
                final metadata = subject['metadata'] as Map<String, dynamic>?;
                final icon = metadata?['icon'] as String? ?? '📚';
                final totalNodesCount = subject['totalNodesCount'] as int? ?? 0;
                final availableNodesCount = subject['availableNodesCount'] as int? ?? 0;

                return Container(
                  width: 280,
                  margin: const EdgeInsets.only(right: 12),
                  child: Card(
                    elevation: 2,
                    child: InkWell(
                      onTap: () {
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
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
                            if (description != null && description.isNotEmpty) ...[
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
                                  Icon(Icons.book, size: 14, color: Colors.grey.shade600),
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
                );
              },
            ),
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
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
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

