import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/core/services/auth_service.dart';
import 'package:edtech_mobile/core/widgets/bottom_nav_bar.dart';
import 'package:edtech_mobile/core/widgets/error_widget.dart';
import 'package:edtech_mobile/theme/theme.dart';

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

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      
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

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Đăng xuất', style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary)),
        content: Text(
          'Bạn có chắc chắn muốn đăng xuất?',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Đăng xuất', style: TextStyle(color: AppColors.errorNeon)),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        await authService.logout();

        if (context.mounted) {
          context.go('/login');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi khi đăng xuất: $e'),
              backgroundColor: AppColors.errorNeon,
            ),
          );
        }
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
        title: Text('Profile', style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary)),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.errorNeon.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout, color: AppColors.errorNeon, size: 20),
            ),
            tooltip: 'Đăng xuất',
            onPressed: () => _handleLogout(),
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _error != null
              ? AppErrorWidget(message: _error!, onRetry: _loadProfile)
              : _profileData == null
                  ? Center(child: Text('No data available', style: AppTextStyles.bodyMedium))
                  : RefreshIndicator(
                      onRefresh: _loadProfile,
                      color: AppColors.cyanNeon,
                      child: _buildContent(),
                    ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 3),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.purpleNeon),
          const SizedBox(height: 16),
          Text('Đang tải...', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final stats = _dashboardStats ?? {};
    final currency = _currencyData ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
<<<<<<< Updated upstream
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
          
          // Admin Panel Button (only for admin)
          if (_profileData!['role'] == 'admin') ...[
            const SizedBox(height: 24),
            Card(
              color: Colors.blue.shade50,
              child: ListTile(
                leading: const Icon(Icons.admin_panel_settings, color: Colors.blue),
                title: const Text(
                  'Admin Panel',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                subtitle: const Text('Duyệt đóng góp từ cộng đồng'),
                trailing: const Icon(Icons.chevron_right, color: Colors.blue),
                onTap: () {
                  context.push('/admin/panel');
                },
              ),
            ),
          ],
          const SizedBox(height: 12),
          
          // Journey Log Button
          Card(
            color: Colors.purple.shade50,
            child: ListTile(
              leading: const Icon(Icons.history_edu, color: Colors.purple),
              title: const Text(
                'Nhật Ký Hành Trình',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
              subtitle: const Text('Lịch sử đóng góp & chỉnh sửa'),
              trailing: const Icon(Icons.chevron_right, color: Colors.purple),
              onTap: () {
                context.go('/profile/journey');
              },
            ),
          ),
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
          const SizedBox(height: 24),
          
          // Logout Button
          _buildLogoutButton(),
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
=======
>>>>>>> Stashed changes
          // Avatar Section
          _buildAvatarSection(),
          const SizedBox(height: 20),

          // Username & Level
          Text(
            _profileData!['fullName'] ?? _profileData!['email'] ?? 'User',
            style: AppTextStyles.h2.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          
          // Role Badge
          if (_profileData!['role'] != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: AppGradients.primary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.purpleNeon.withOpacity(0.3),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Text(
                _profileData!['role']?.toUpperCase() ?? '',
                style: AppTextStyles.labelMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          const SizedBox(height: 24),

          // Stats Row
          _buildStatsRow(stats, currency),
          const SizedBox(height: 24),

<<<<<<< Updated upstream
          // Stats Section
          _buildStatsSection(),

          const SizedBox(height: 24),

          // Journey Log Button
          Card(
            color: Colors.purple.shade50,
            child: ListTile(
              leading: const Icon(Icons.history_edu, color: Colors.purple),
              title: const Text(
                'Nhật Ký Hành Trình',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
              subtitle: const Text('Lịch sử đóng góp & chỉnh sửa'),
              trailing: const Icon(Icons.chevron_right, color: Colors.purple),
              onTap: () {
                context.go('/profile/journey');
              },
            ),
          ),
          const SizedBox(height: 24),
=======
          // Admin Panel Button (only for admin)
          if (_profileData!['role'] == 'admin')
            _buildMenuCard(
              icon: Icons.admin_panel_settings,
              title: 'Admin Panel',
              subtitle: 'Duyệt đóng góp từ cộng đồng',
              color: AppColors.cyanNeon,
              onTap: () => context.push('/admin/panel'),
            ),
          
          // Journey Log Button
          _buildMenuCard(
            icon: Icons.history_edu,
            title: 'Nhật Ký Hành Trình',
            subtitle: 'Lịch sử đóng góp & chỉnh sửa',
            color: AppColors.purpleNeon,
            onTap: () => context.go('/profile/journey'),
          ),

          // Premium/Payment Button
          _buildMenuCard(
            icon: Icons.workspace_premium,
            title: 'Nâng cấp Premium',
            subtitle: 'Mở khóa tất cả tính năng',
            color: AppColors.coinGold,
            onTap: () => context.push('/payment'),
          ),

          // Profile Info Card
          _buildProfileInfoCard(),
          const SizedBox(height: 16),
>>>>>>> Stashed changes

          // Onboarding Data
          if (_profileData!['onboardingData'] != null)
            _buildOnboardingCard(),

          // Placement Test Info
          if (_profileData!['placementTestLevel'] != null)
            _buildPlacementTestCard(),

          const SizedBox(height: 24),
          
          // Logout Button
          _buildLogoutButton(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Glow effect
        Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [AppColors.purpleNeon.withOpacity(0.3), Colors.transparent],
            ),
          ),
        ),
        // Avatar container
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppGradients.primary,
            boxShadow: [
              BoxShadow(
                color: AppColors.purpleNeon.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.bgSecondary,
            ),
            child: const Center(
              child: Icon(Icons.person, size: 50, color: AppColors.textSecondary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(Map<String, dynamic> stats, Map<String, dynamic> currency) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.star_rounded,
            label: 'XP',
            value: '${stats['totalXP'] ?? currency['lPoints'] ?? 0}',
            color: AppColors.xpGold,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.monetization_on_rounded,
            label: 'Coins',
            value: '${stats['coins'] ?? currency['coins'] ?? 0}',
            color: AppColors.coinGold,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.local_fire_department_rounded,
            label: 'Streak',
            value: '${stats['streak'] ?? currency['currentStreak'] ?? 0}',
            color: AppColors.streakOrange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.numberMedium.copyWith(color: color),
          ),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: ListTile(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(title, style: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary)),
        subtitle: Text(subtitle, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
        trailing: Icon(Icons.chevron_right, color: color),
      ),
    );
  }

  Widget _buildProfileInfoCard() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline, color: AppColors.cyanNeon, size: 20),
              const SizedBox(width: 8),
              Text('Thông tin cá nhân', style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.badge_outlined, 'Tên', _profileData!['fullName'] ?? 'Chưa cập nhật'),
          Divider(color: AppColors.borderPrimary, height: 24),
          _buildInfoRow(Icons.email_outlined, 'Email', _profileData!['email'] ?? ''),
          if (_profileData!['phone'] != null) ...[
            Divider(color: AppColors.borderPrimary, height: 24),
            _buildInfoRow(Icons.phone_outlined, 'Số điện thoại', _profileData!['phone'] ?? ''),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textTertiary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary)),
              const SizedBox(height: 4),
              Text(value, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOnboardingCard() {
    final onboardingData = _profileData!['onboardingData'] as Map<String, dynamic>? ?? {};

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.school_outlined, color: AppColors.successNeon, size: 20),
              const SizedBox(width: 8),
              Text('Thông tin học tập', style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          if (onboardingData['nickname'] != null)
            _buildInfoRow(Icons.badge_outlined, 'Biệt danh', onboardingData['nickname'] ?? ''),
          if (onboardingData['currentLevel'] != null) ...[
            Divider(color: AppColors.borderPrimary, height: 24),
            _buildInfoRow(Icons.trending_up_outlined, 'Trình độ', onboardingData['currentLevel'] ?? ''),
          ],
          if (onboardingData['targetGoal'] != null) ...[
            Divider(color: AppColors.borderPrimary, height: 24),
            _buildInfoRow(Icons.flag_outlined, 'Mục tiêu', onboardingData['targetGoal'] ?? ''),
          ],
          if (onboardingData['dailyTime'] != null) ...[
            Divider(color: AppColors.borderPrimary, height: 24),
            _buildInfoRow(Icons.access_time_outlined, 'Thời gian/ngày', '${onboardingData['dailyTime']} phút'),
          ],
        ],
      ),
    );
  }

  Widget _buildPlacementTestCard() {
    final level = _profileData!['placementTestLevel'] as String?;
    final score = _profileData!['placementTestScore'] as int?;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.quiz_outlined, color: AppColors.warningNeon, size: 20),
              const SizedBox(width: 8),
              Text('Placement Test', style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          if (score != null)
            _buildInfoRow(Icons.score_outlined, 'Điểm số', '$score%'),
          if (level != null) ...[
            Divider(color: AppColors.borderPrimary, height: 24),
            _buildInfoRow(Icons.leaderboard_outlined, 'Level', level.toUpperCase()),
          ],
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        _handleLogout();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.errorNeon.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.errorNeon.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: AppColors.errorNeon),
            const SizedBox(width: 8),
            Text(
              'Đăng xuất',
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.errorNeon),
            ),
          ],
        ),
      ),
    );
  }
}
