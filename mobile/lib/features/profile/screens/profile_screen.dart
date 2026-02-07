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
  bool _isSwitchingRole = false;
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

  // === Role helpers ===
  String get _currentRole => _profileData?['role'] ?? 'user';
  bool get _isContributor => _currentRole == 'contributor';
  bool get _isAdmin => _currentRole == 'admin';

  Color get _accentColor => _isContributor ? AppColors.contributorBlue : AppColors.purpleNeon;
  Color get _bgPrimary => _isContributor ? AppColors.contributorBgPrimary : AppColors.bgPrimary;
  Color get _bgSecondary => _isContributor ? AppColors.contributorBgSecondary : AppColors.bgSecondary;
  Color get _borderColor => _isContributor ? AppColors.contributorBorder : AppColors.borderPrimary;

  LinearGradient get _primaryGradient =>
      _isContributor ? AppGradients.contributor : AppGradients.primary;

  Future<void> _handleSwitchRole() async {
    final targetRole = _isContributor ? 'user' : 'contributor';
    final targetLabel = targetRole == 'contributor' ? 'Contributor' : 'Learner';

    final shouldSwitch = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _bgSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Chuyển sang $targetLabel',
          style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
        ),
        content: Text(
          targetRole == 'contributor'
              ? 'Chế độ Contributor cho phép bạn đóng góp nội dung: thêm môn học, tạo domain, topic và bài học. Các đóng góp cần được admin duyệt.'
              : 'Chế độ Learner cho phép bạn tập trung vào việc học. Bạn sẽ không thể chỉnh sửa hoặc đóng góp nội dung.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Chuyển',
              style: TextStyle(
                color: targetRole == 'contributor'
                    ? AppColors.contributorBlue
                    : AppColors.purpleNeon,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldSwitch == true) {
      setState(() => _isSwitchingRole = true);
      try {
        final apiService = Provider.of<ApiService>(context, listen: false);
        await apiService.switchRole(targetRole);
        await _loadProfile(); // Reload profile to get updated role
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã chuyển sang chế độ $targetLabel'),
              backgroundColor: targetRole == 'contributor'
                  ? AppColors.contributorBlue
                  : AppColors.successNeon,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: $e'),
              backgroundColor: AppColors.errorNeon,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isSwitchingRole = false);
      }
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
      backgroundColor: _bgPrimary,
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
                      color: _accentColor,
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
                gradient: _primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _accentColor.withOpacity(0.3),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isContributor
                        ? Icons.edit_note
                        : _isAdmin
                            ? Icons.shield
                            : Icons.school,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isContributor
                        ? 'CONTRIBUTOR'
                        : _isAdmin
                            ? 'ADMIN'
                            : 'LEARNER',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Role Switcher (not for admin)
          if (!_isAdmin) _buildRoleSwitcher(),
          const SizedBox(height: 24),

          // Stats Row
          _buildStatsRow(stats, currency),
          const SizedBox(height: 24),

          // Admin Panel Button (only for admin)
          if (_isAdmin)
            _buildMenuCard(
              icon: Icons.admin_panel_settings,
              title: 'Admin Panel',
              subtitle: 'Duyệt đóng góp từ cộng đồng',
              color: AppColors.cyanNeon,
              onTap: () => context.push('/admin/panel'),
            ),

          // Contributor: My Pending Contributions
          if (_isContributor)
            _buildMenuCard(
              icon: Icons.volunteer_activism,
              title: 'Đóng góp của tôi',
              subtitle: 'Xem đóng góp môn học, domain, topic & trạng thái duyệt',
              color: AppColors.contributorBlue,
              onTap: () => context.push('/contributor/my-contributions'),
            ),
          
          // Journey Log Button
          _buildMenuCard(
            icon: Icons.history_edu,
            title: 'Nhật Ký Hành Trình',
            subtitle: _isContributor
                ? 'Lịch sử đóng góp & chỉnh sửa'
                : 'Lịch sử học tập',
            color: _accentColor,
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

  Widget _buildRoleSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          // Learner tab
          Expanded(
            child: GestureDetector(
              onTap: _isSwitchingRole || !_isContributor
                  ? null
                  : () => _handleSwitchRole(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isContributor
                      ? AppColors.purpleNeon.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: !_isContributor
                      ? Border.all(color: AppColors.purpleNeon.withOpacity(0.5))
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.school,
                      size: 18,
                      color: !_isContributor
                          ? AppColors.purpleNeon
                          : AppColors.textTertiary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Learner',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: !_isContributor
                            ? AppColors.purpleNeon
                            : AppColors.textTertiary,
                        fontWeight: !_isContributor
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Contributor tab
          Expanded(
            child: GestureDetector(
              onTap: _isSwitchingRole || _isContributor
                  ? null
                  : () => _handleSwitchRole(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isContributor
                      ? AppColors.contributorBlue.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: _isContributor
                      ? Border.all(color: AppColors.contributorBlue.withOpacity(0.5))
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isSwitchingRole && !_isContributor)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.contributorBlue,
                        ),
                      )
                    else
                      Icon(
                        Icons.edit_note,
                        size: 18,
                        color: _isContributor
                            ? AppColors.contributorBlue
                            : AppColors.textTertiary,
                      ),
                    const SizedBox(width: 6),
                    Text(
                      'Contributor',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: _isContributor
                            ? AppColors.contributorBlue
                            : AppColors.textTertiary,
                        fontWeight: _isContributor
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
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
              colors: [_accentColor.withOpacity(0.3), Colors.transparent],
            ),
          ),
        ),
        // Avatar container
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: _primaryGradient,
            boxShadow: [
              BoxShadow(
                color: _accentColor.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _bgSecondary,
            ),
            child: Center(
              child: Icon(
                _isContributor ? Icons.edit_note : Icons.person,
                size: 50,
                color: AppColors.textSecondary,
              ),
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
        color: _bgSecondary,
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
        color: _bgSecondary,
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
        color: _bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline, color: _accentColor, size: 20),
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
        color: _bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
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
        color: _bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
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
