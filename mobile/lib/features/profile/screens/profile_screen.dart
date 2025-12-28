import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/core/widgets/streak_display.dart';
import 'package:edtech_mobile/core/widgets/bottom_nav_bar.dart';
import 'package:edtech_mobile/core/widgets/error_widget.dart';
import 'package:edtech_mobile/core/widgets/skeleton_loader.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profileData;
  Map<String, dynamic>? _currencyData;
  Map<String, dynamic>? _dashboardStats;
  bool _isLoading = true;
  String? _error;
  bool _showDetailed = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      
      // Load profile, currency, and dashboard stats
      final results = await Future.wait([
        apiService.getUserProfile(),
        apiService.getCurrency(),
        apiService.getDashboard(),
      ]);

      setState(() {
        _profileData = results[0];
        _currencyData = results[1];
        _dashboardStats = results[2]['stats'];
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
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(_showDetailed ? Icons.expand_less : Icons.expand_more),
            onPressed: () {
              setState(() {
                _showDetailed = !_showDetailed;
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? _buildSkeletonLoader()
          : _error != null
              ? AppErrorWidget(
                  message: _error!,
                  onRetry: _loadProfile,
                )
              : _profileData == null
                  ? const Center(child: Text('No data available'))
                  : RefreshIndicator(
                      onRefresh: _loadProfile,
                      child: _showDetailed
                          ? _buildDetailedView()
                          : _buildMinimalView(),
                    ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 3),
    );
  }

  Widget _buildSkeletonLoader() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SkeletonLoader(
            width: 120,
            height: 120,
            borderRadius: BorderRadius.circular(60),
          ),
          const SizedBox(height: 24),
          SkeletonCard(height: 60),
          const SizedBox(height: 16),
          SkeletonCard(height: 200),
          const SizedBox(height: 16),
          SkeletonCard(height: 100),
        ],
      ),
    );
  }

  Widget _buildMinimalView() {
    final stats = _dashboardStats ?? {};
    final streak = stats['streak'] ?? 0;
    final consecutivePerfect = stats['consecutivePerfect'] ?? 0;
    final weeklyProgress = stats['weeklyProgress'] as Map<String, dynamic>?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Avatar with frame
          _buildAvatarSection(),
          const SizedBox(height: 24),

          // Username & Role
          Text(
            _profileData!['fullName'] ?? _profileData!['email'] ?? 'User',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_profileData!['role'] != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _profileData!['role'] ?? '',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Streak Display
          StreakDisplay(
            streak: streak is int ? streak : int.tryParse(streak.toString()) ?? 0,
            consecutivePerfect: consecutivePerfect is int
                ? consecutivePerfect
                : int.tryParse(consecutivePerfect.toString()) ?? 0,
            weeklyProgress: weeklyProgress,
          ),
          const SizedBox(height: 24),

          // Mini Dashboard Stats
          _buildMiniStats(),
        ],
      ),
    );
  }

  Widget _buildDetailedView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar Section
          _buildAvatarSection(),
          const SizedBox(height: 24),

          // Profile Info
          _buildProfileInfo(),
          const SizedBox(height: 24),

          // Stats Section
          _buildStatsSection(),
          const SizedBox(height: 24),

          // Onboarding Data
          if (_profileData!['onboardingData'] != null)
            _buildOnboardingData(),
          const SizedBox(height: 24),

          // Placement Test Info
          if (_profileData!['placementTestLevel'] != null)
            _buildPlacementTestInfo(),
        ],
      ),
    );
  }

  Widget _buildAvatarSection() {
    final avatarId = _profileData!['avatarId'] as String?;
    final backgroundId = _profileData!['backgroundId'] as String?;
    final frameId = _profileData!['frameId'] as String?;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Background
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: backgroundId != null ? Colors.blue.shade200 : Colors.grey.shade300,
            shape: BoxShape.circle,
            border: Border.all(
              color: frameId != null ? Colors.amber : Colors.grey.shade400,
              width: frameId != null ? 4 : 2,
            ),
          ),
          child: avatarId != null
              ? const Icon(Icons.person, size: 60, color: Colors.white)
              : const Icon(Icons.person, size: 60, color: Colors.grey),
        ),
        // Frame overlay (if equipped)
        if (frameId != null)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.amber,
                  width: 6,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMiniStats() {
    final stats = _dashboardStats ?? {};

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.star,
            label: 'XP',
            value: '${stats['totalXP'] ?? 0}',
            color: Colors.amber,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.monetization_on,
            label: 'Coins',
            value: '${stats['coins'] ?? 0}',
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.local_fire_department,
            label: 'Streak',
            value: '${stats['streak'] ?? 0}',
            color: Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin cá nhân',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _InfoRow(
              icon: Icons.person,
              label: 'Tên',
              value: _profileData!['fullName'] ?? 'Chưa cập nhật',
            ),
            const Divider(),
            _InfoRow(
              icon: Icons.email,
              label: 'Email',
              value: _profileData!['email'] ?? '',
            ),
            if (_profileData!['phone'] != null) ...[
              const Divider(),
              _InfoRow(
                icon: Icons.phone,
                label: 'Số điện thoại',
                value: _profileData!['phone'] ?? '',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    final stats = _dashboardStats ?? {};
    final currency = _currencyData ?? {};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thống kê',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.5,
              children: [
                _StatTile(
                  icon: Icons.star,
                  label: 'XP',
                  value: '${stats['totalXP'] ?? currency['lPoints'] ?? 0}',
                  color: Colors.amber,
                ),
                _StatTile(
                  icon: Icons.monetization_on,
                  label: 'Coins',
                  value: '${stats['coins'] ?? currency['coins'] ?? 0}',
                  color: Colors.orange,
                ),
                _StatTile(
                  icon: Icons.local_fire_department,
                  label: 'Streak',
                  value: '${stats['streak'] ?? currency['currentStreak'] ?? 0}',
                  color: Colors.red,
                ),
                _StatTile(
                  icon: Icons.diamond,
                  label: 'Shards',
                  value: '${currency['shards']?.length ?? 0}',
                  color: Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingData() {
    final onboardingData = _profileData!['onboardingData'] as Map<String, dynamic>? ?? {};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin onboarding',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (onboardingData['nickname'] != null)
              _InfoRow(
                icon: Icons.badge,
                label: 'Biệt danh',
                value: onboardingData['nickname'] ?? '',
              ),
            if (onboardingData['age'] != null) ...[
              const Divider(),
              _InfoRow(
                icon: Icons.cake,
                label: 'Tuổi',
                value: '${onboardingData['age']}',
              ),
            ],
            if (onboardingData['currentLevel'] != null) ...[
              const Divider(),
              _InfoRow(
                icon: Icons.school,
                label: 'Trình độ',
                value: onboardingData['currentLevel'] ?? '',
              ),
            ],
            if (onboardingData['targetGoal'] != null) ...[
              const Divider(),
              _InfoRow(
                icon: Icons.flag,
                label: 'Mục tiêu',
                value: onboardingData['targetGoal'] ?? '',
              ),
            ],
            if (onboardingData['dailyTime'] != null) ...[
              const Divider(),
              _InfoRow(
                icon: Icons.access_time,
                label: 'Thời gian học/ngày',
                value: '${onboardingData['dailyTime']} phút',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlacementTestInfo() {
    final level = _profileData!['placementTestLevel'] as String?;
    final score = _profileData!['placementTestScore'] as int?;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Placement Test',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (score != null)
              _InfoRow(
                icon: Icons.quiz,
                label: 'Điểm số',
                value: '$score%',
              ),
            if (level != null) ...[
              const Divider(),
              _InfoRow(
                icon: Icons.trending_up,
                label: 'Level',
                value: level.toUpperCase(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
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
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

