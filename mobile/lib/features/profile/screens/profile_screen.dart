import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:edtech_mobile/core/config/api_config.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/core/services/auth_service.dart';
import 'package:edtech_mobile/core/services/tutorial_service.dart';
import 'package:edtech_mobile/core/tutorial/tutorial_helper.dart';
import 'package:edtech_mobile/core/widgets/app_bar_leading_back_home.dart';
import 'package:edtech_mobile/core/widgets/bottom_nav_bar.dart';
import 'package:edtech_mobile/core/widgets/error_widget.dart';
import 'package:edtech_mobile/features/chat/widgets/chat_bubble.dart';
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
  List<dynamic> _badgeCollection = [];
  bool _isLoading = true;
  bool _isSwitchingRole = false;
  bool _avatarBusy = false;
  String? _error;
  final ImagePicker _imagePicker = ImagePicker();

  // Tutorial keys
  final _statsRowKey = GlobalKey();
  final _roleSwitcherKey = GlobalKey();
  final _menuCardsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _showProfileTutorial() {
    if (!mounted || _profileData == null) return;

    final targets = [
      TutorialHelper.buildTarget(
        key: _statsRowKey,
        title: 'Thống kê của bạn',
        description: 'Xem XP tích lũy, Coins kiếm được và chuỗi Streak.',
        icon: Icons.bar_chart,
        stepLabel: 'Bước 1/3',
      ),
      TutorialHelper.buildTarget(
        key: _roleSwitcherKey,
        title: 'Chuyển vai trò',
        description:
            'Learner để học bài, Contributor để đóng góp nội dung cho cộng đồng.',
        icon: Icons.swap_horiz,
        stepLabel: 'Bước 2/3',
      ),
      TutorialHelper.buildTarget(
        key: _menuCardsKey,
        title: 'Menu chức năng',
        description:
            'Nhật ký hành trình, đóng góp của bạn, mua kim cương và hơn thế nữa!',
        icon: Icons.menu,
        stepLabel: 'Bước 3/3',
        align: ContentAlign.top,
      ),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      TutorialHelper.showTutorial(
        context: context,
        tutorialId: TutorialService.profileTutorial,
        targets: targets,
      );
    });
  }

  Future<void> _loadProfile() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);

      final results = await Future.wait<dynamic>([
        apiService.getUserProfile(),
        apiService.getCurrency(),
        apiService.getDashboardSummary(),
        apiService.getWeeklyBadges().catchError((_) => <String, dynamic>{}),
      ]);

      setState(() {
        _profileData = results[0] as Map<String, dynamic>;
        _currencyData = results[1] as Map<String, dynamic>;
        final summary = results[2] as Map<String, dynamic>;
        final statsRaw = summary['stats'];
        _dashboardStats =
            statsRaw is Map ? Map<String, dynamic>.from(statsRaw) : null;
        final badgesData = results[3] as Map<String, dynamic>? ?? {};
        _badgeCollection = badgesData['collection'] as List? ?? [];
        _isLoading = false;
      });
      _showProfileTutorial();
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

  Color get _accentColor =>
      _isContributor ? AppColors.contributorBlue : AppColors.purpleNeon;
  Color get _bgPrimary =>
      _isContributor ? AppColors.contributorBgPrimary : AppColors.bgPrimary;
  Color get _bgSecondary =>
      _isContributor ? AppColors.contributorBgSecondary : AppColors.bgSecondary;
  Color get _borderColor =>
      _isContributor ? AppColors.contributorBorder : AppColors.borderPrimary;

  LinearGradient get _primaryGradient =>
      _isContributor ? AppGradients.contributor : AppGradients.primary;

  String? _avatarUrlResolved() {
    final raw = _profileData?['avatarUrl'] as String?;
    final u = ApiConfig.absoluteMediaUrl(raw);
    return u.isEmpty ? null : u;
  }

  Future<void> _showAvatarSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: _bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_library_rounded, color: _accentColor),
              title: Text('Chọn ảnh từ thư viện',
                  style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadAvatar(ImageSource.gallery);
              },
            ),
            if (!kIsWeb)
              ListTile(
                leading: Icon(Icons.camera_alt_rounded, color: _accentColor),
                title: Text('Chụp ảnh',
                    style: TextStyle(color: AppColors.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadAvatar(ImageSource.camera);
                },
              ),
            if ((_profileData?['avatarUrl'] as String?)?.isNotEmpty ?? false)
              ListTile(
                leading:
                    const Icon(Icons.delete_outline, color: AppColors.errorNeon),
                title: Text('Xóa ảnh đại diện',
                    style: TextStyle(color: AppColors.errorNeon)),
                onTap: () {
                  Navigator.pop(ctx);
                  _removeAvatar();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    if (_avatarBusy) return;
    final api = Provider.of<ApiService>(context, listen: false);
    setState(() => _avatarBusy = true);
    try {
      final x = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 88,
      );
      if (x == null) {
        if (mounted) setState(() => _avatarBusy = false);
        return;
      }
      String path;
      if (kIsWeb) {
        final bytes = await x.readAsBytes();
        path = await api.uploadImageBytes(bytes,
            filename: x.name.isNotEmpty ? x.name : 'avatar.jpg');
      } else {
        path = await api.uploadImage(x.path);
      }
      if (path.isEmpty) throw Exception('Upload thất bại');
      final updated = await api.updateUserProfile(avatarUrl: path);
      if (!mounted) return;
      setState(() {
        _profileData = {...?_profileData, ...updated};
        _avatarBusy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đã cập nhật ảnh đại diện'),
          backgroundColor: AppColors.successNeon.withValues(alpha: 0.9),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _avatarBusy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi ảnh: $e'),
            backgroundColor: AppColors.errorNeon,
          ),
        );
      }
    }
  }

  Future<void> _removeAvatar() async {
    if (_avatarBusy) return;
    final api = Provider.of<ApiService>(context, listen: false);
    setState(() => _avatarBusy = true);
    try {
      final updated = await api.updateUserProfile(avatarUrl: '');
      if (!mounted) return;
      setState(() {
        _profileData = {...?_profileData, ...updated};
        _avatarBusy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đã xóa ảnh đại diện'),
          backgroundColor: AppColors.textSecondary.withValues(alpha: 0.9),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _avatarBusy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: AppColors.errorNeon,
          ),
        );
      }
    }
  }

  Future<void> _editDisplayName() async {
    final current =
        (_profileData?['fullName'] as String?)?.trim() ?? '';
    final controller = TextEditingController(text: current);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bgSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Đổi tên hiển thị',
            style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary)),
        content: TextField(
          controller: controller,
          maxLength: 120,
          autofocus: true,
          style: AppTextStyles.bodyMedium
              .copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Tên của bạn',
            hintStyle:
                TextStyle(color: AppColors.textTertiary),
            counterStyle: TextStyle(color: AppColors.textTertiary),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _accentColor, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Lưu',
                style: TextStyle(
                    color: _accentColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) {
      controller.dispose();
      return;
    }
    final name = controller.text.trim();
    controller.dispose();
    if (name.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tên không được để trống'),
          backgroundColor: AppColors.errorNeon,
        ),
      );
      return;
    }
    final api = Provider.of<ApiService>(context, listen: false);
    try {
      final updated = await api.updateUserProfile(fullName: name);
      if (!mounted) return;
      setState(() => _profileData = {...?_profileData, ...updated});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đã cập nhật tên'),
          backgroundColor: AppColors.successNeon.withValues(alpha: 0.9),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: AppColors.errorNeon,
          ),
        );
      }
    }
  }

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
          style:
              AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy',
                style: TextStyle(color: AppColors.textSecondary)),
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
        // Không gọi lại _loadProfile(): nó kéo getDashboard + toàn bộ nodes — rất chậm.
        // PATCH switch-role đã trả về user cập nhật (gồm role).
        final raw = await apiService.switchRole(targetRole);
        if (!mounted) return;
        final updated = Map<String, dynamic>.from(raw as Map);
        setState(() {
          _profileData = {...?_profileData, ...updated};
        });
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
        title: Text('Đăng xuất',
            style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary)),
        content: Text(
          'Bạn có chắc chắn muốn đăng xuất?',
          style:
              AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Đăng xuất',
                style: TextStyle(color: AppColors.errorNeon)),
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
        leading: const AppBarLeadingBackAndHome(),
        leadingWidth: 112,
        automaticallyImplyLeading: false,
        title: Text('Profile',
            style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary)),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.errorNeon.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout,
                  color: AppColors.errorNeon, size: 20),
            ),
            tooltip: 'Đăng xuất',
            onPressed: () => _handleLogout(),
          ),
        ],
      ),
      body: Stack(
        children: [
          _isLoading
              ? _buildLoadingState()
              : _error != null
                  ? AppErrorWidget(message: _error!, onRetry: _loadProfile)
                  : _profileData == null
                      ? const Center(
                          child: Text('No data available',
                              style: AppTextStyles.bodyMedium))
                      : RefreshIndicator(
                          onRefresh: _loadProfile,
                          color: _accentColor,
                          child: _buildContent(),
                        ),
          const FloatingChatBubble(),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 4),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.purpleNeon),
          const SizedBox(height: 16),
          Text('Đang tải...',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary)),
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

          // Tên hiển thị + đổi tên
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  _profileData!['fullName'] ??
                      _profileData!['email'] ??
                      'User',
                  textAlign: TextAlign.center,
                  style:
                      AppTextStyles.h2.copyWith(color: AppColors.textPrimary),
                ),
              ),
              IconButton(
                onPressed: _editDisplayName,
                tooltip: 'Đổi tên',
                icon: Icon(Icons.edit_rounded,
                    color: _accentColor, size: 22),
              ),
            ],
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

          if (!_isAdmin)
            KeyedSubtree(
              key: _roleSwitcherKey,
              child: _buildRoleSwitcher(),
            ),
          const SizedBox(height: 24),

          KeyedSubtree(
            key: _statsRowKey,
            child: _buildStatsRow(stats, currency),
          ),
          const SizedBox(height: 24),

          if (_badgeCollection.isNotEmpty) ...[
            _buildBadgeCollectionSection(),
            const SizedBox(height: 24),
          ],

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
              subtitle:
                  'Xem đóng góp môn học, domain, topic & trạng thái duyệt',
              color: AppColors.contributorBlue,
              onTap: () => context.push('/contributor/my-contributions'),
            ),

          Column(
            key: _menuCardsKey,
            children: [
              _buildMenuCard(
                icon: Icons.history_edu,
                title: 'Nhật ký hành trình',
                subtitle: _isContributor
                    ? 'Lịch sử đóng góp & chỉnh sửa'
                    : 'Lịch sử học tập',
                color: _accentColor,
                onTap: () => context.go('/profile/journey'),
              ),
              _buildMenuCard(
                icon: Icons.workspace_premium,
                title: 'Nhận kim cương',
                subtitle: 'Mở khóa chức năng nâng cao',
                color: AppColors.coinGold,
                onTap: () => context.push('/payment'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Profile Info Card
          _buildProfileInfoCard(),
          const SizedBox(height: 16),

          // Onboarding Data
          if (_profileData!['onboardingData'] != null) _buildOnboardingCard(),

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
                      ? Border.all(
                          color: AppColors.contributorBlue.withOpacity(0.5))
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isSwitchingRole && !_isContributor)
                      const SizedBox(
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
    final imgUrl = _avatarUrlResolved();
    return Stack(
      alignment: Alignment.center,
      children: [
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
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _avatarBusy ? null : _showAvatarSheet,
            customBorder: const CircleBorder(),
            child: Container(
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
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: imgUrl != null
                    ? CachedNetworkImage(
                        imageUrl: imgUrl,
                        fit: BoxFit.cover,
                        width: 102,
                        height: 102,
                        placeholder: (_, __) => Container(
                          color: _bgSecondary,
                          child: const Center(
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.purpleNeon,
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => ColoredBox(
                          color: _bgSecondary,
                          child: Icon(
                            _isContributor ? Icons.edit_note : Icons.person,
                            size: 50,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    : ColoredBox(
                        color: _bgSecondary,
                        child: Center(
                          child: Icon(
                            _isContributor ? Icons.edit_note : Icons.person,
                            size: 50,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ),
        if (_avatarBusy)
          Positioned.fill(
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          right: 8,
          bottom: 8,
          child: IgnorePointer(
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _accentColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.camera_alt_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(
      Map<String, dynamic> stats, Map<String, dynamic> currency) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.star_rounded,
            label: 'XP',
            value: '${stats['totalXP'] ?? currency['xp'] ?? 0}',
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

  Widget _buildBadgeCollectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.workspace_premium_rounded,
                color: Colors.amber, size: 20),
            const SizedBox(width: 8),
            Text('Huy hiệu',
                style: AppTextStyles.labelLarge
                    .copyWith(color: AppColors.textPrimary)),
            const Spacer(),
            GestureDetector(
              onTap: () => context.push('/weekly-rewards-history'),
              child: Text('Xem tất cả',
                  style: AppTextStyles.caption.copyWith(color: _accentColor)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _badgeCollection.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final b = _badgeCollection[i] as Map<String, dynamic>;
              final count = b['count'] ?? 1;
              return Container(
                width: 70,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _bgSecondary,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(b['iconUrl'] ?? '🏅',
                        style: const TextStyle(fontSize: 24)),
                    const SizedBox(height: 4),
                    if (count > 1)
                      Text('${count}x',
                          style: AppTextStyles.caption.copyWith(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold)),
                    Text(b['name'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary, fontSize: 9)),
                  ],
                ),
              );
            },
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
            style:
                AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
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
        title: Text(title,
            style: AppTextStyles.labelLarge
                .copyWith(color: AppColors.textPrimary)),
        subtitle: Text(subtitle,
            style:
                AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
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
              Text('Thông tin cá nhân',
                  style:
                      AppTextStyles.h4.copyWith(color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.badge_outlined, 'Tên',
              _profileData!['fullName'] ?? 'Chưa cập nhật'),
          const Divider(color: AppColors.borderPrimary, height: 24),
          _buildInfoRow(
              Icons.email_outlined, 'Email', _profileData!['email'] ?? ''),
          if (_profileData!['phone'] != null) ...[
            const Divider(color: AppColors.borderPrimary, height: 24),
            _buildInfoRow(Icons.phone_outlined, 'Số điện thoại',
                _profileData!['phone'] ?? ''),
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
              Text(label,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textTertiary)),
              const SizedBox(height: 4),
              Text(value,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOnboardingCard() {
    final onboardingData =
        _profileData!['onboardingData'] as Map<String, dynamic>? ?? {};

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
              const Icon(Icons.school_outlined,
                  color: AppColors.successNeon, size: 20),
              const SizedBox(width: 8),
              Text('Thông tin học tập',
                  style:
                      AppTextStyles.h4.copyWith(color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          if (onboardingData['nickname'] != null)
            _buildInfoRow(Icons.badge_outlined, 'Biệt danh',
                onboardingData['nickname'] ?? ''),
          if (onboardingData['currentLevel'] != null) ...[
            const Divider(color: AppColors.borderPrimary, height: 24),
            _buildInfoRow(Icons.trending_up_outlined, 'Trình độ',
                onboardingData['currentLevel'] ?? ''),
          ],
          if (onboardingData['targetGoal'] != null) ...[
            const Divider(color: AppColors.borderPrimary, height: 24),
            _buildInfoRow(Icons.flag_outlined, 'Mục tiêu',
                onboardingData['targetGoal'] ?? ''),
          ],
          if (onboardingData['dailyTime'] != null) ...[
            const Divider(color: AppColors.borderPrimary, height: 24),
            _buildInfoRow(Icons.access_time_outlined, 'Thời gian/ngày',
                '${onboardingData['dailyTime']} phút'),
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
              const Icon(Icons.quiz_outlined,
                  color: AppColors.warningNeon, size: 20),
              const SizedBox(width: 8),
              Text('Placement Test',
                  style:
                      AppTextStyles.h4.copyWith(color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          if (score != null)
            _buildInfoRow(Icons.score_outlined, 'Điểm số', '$score%'),
          if (level != null) ...[
            const Divider(color: AppColors.borderPrimary, height: 24),
            _buildInfoRow(
                Icons.leaderboard_outlined, 'Level', level.toUpperCase()),
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
            const Icon(Icons.logout, color: AppColors.errorNeon),
            const SizedBox(width: 8),
            Text(
              'Đăng xuất',
              style:
                  AppTextStyles.labelLarge.copyWith(color: AppColors.errorNeon),
            ),
          ],
        ),
      ),
    );
  }
}
