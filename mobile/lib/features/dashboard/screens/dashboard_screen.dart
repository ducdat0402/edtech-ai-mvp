import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/core/services/competency_growth_notifier.dart';
import 'package:edtech_mobile/core/services/tutorial_service.dart';
import 'package:edtech_mobile/core/tutorial/tutorial_helper.dart';
import 'package:edtech_mobile/core/widgets/bottom_nav_bar.dart';
import 'package:edtech_mobile/core/widgets/error_widget.dart';
import 'package:edtech_mobile/core/widgets/lesson_unlock_sheet.dart';
import 'package:edtech_mobile/core/widgets/skeleton_loader.dart';
import 'package:edtech_mobile/theme/theme.dart';
import 'package:edtech_mobile/features/chat/widgets/chat_bubble.dart';

class DashboardScreen extends StatefulWidget {
  /// Bắt buộc hiện hướng dẫn lần đầu (khi về từ onboarding / tạo lộ trình mà chưa hoàn thành).
  final bool showTutorial;

  const DashboardScreen({super.key, this.showTutorial = false});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _dashboardData;
  Map<String, dynamic>? _motivation;
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;
  String? _error;
  String _userRole = 'user';

  // Tutorial keys
  final _levelCardKey = GlobalKey();
  final _statsRowKey = GlobalKey();
  final _quickActionsKey = GlobalKey();
  final _bottomNavKey = GlobalKey();

  bool get _isContributor => _userRole == 'contributor';

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  void _showDashboardTutorial() {
    if (!mounted || _dashboardData == null) return;

    final targets = [
      TutorialHelper.buildTarget(
        key: _levelCardKey,
        title: 'Cấp độ & kinh nghiệm',
        description:
            'Đây là cấp độ hiện tại của bạn. Hoàn thành bài học để nhận XP và lên cấp!',
        icon: Icons.military_tech,
        stepLabel: 'Bước 1/4',
      ),
      TutorialHelper.buildTarget(
        key: _statsRowKey,
        title: 'Tài nguyên của bạn',
        description:
            'Kim cương, xu và chuỗi ngày nằm bên phải thanh trên. Chạm để nạp tiền, cửa hàng hoặc ví.',
        icon: Icons.account_balance_wallet,
        stepLabel: 'Bước 2/4',
      ),
      TutorialHelper.buildTarget(
        key: _quickActionsKey,
        title: 'Thêm: nhiệm vụ, cam kết tuần, xếp hạng…',
        description:
            'Nhấn nút mở rộng (icon lưới) phía trên chat để mở Nhiệm vụ, Cam kết tuần, Xếp hạng và Cửa hàng.',
        icon: Icons.apps_rounded,
        stepLabel: 'Bước 3/4',
        align: ContentAlign.top,
      ),
      TutorialHelper.buildTarget(
        key: _bottomNavKey,
        title: 'Thanh điều hướng',
        description:
            'Chuyển nhanh giữa Tổng quan, Môn học và Bạn bè. Hồ sơ: chạm avatar trên thanh trên cùng.',
        icon: Icons.navigation,
        stepLabel: 'Bước 4/4',
        align: ContentAlign.top,
      ),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      TutorialHelper.showTutorial(
        context: context,
        tutorialId: TutorialService.dashboardTutorial,
        targets: targets,
        force: widget.showTutorial,
      );
    });
  }

  Future<void> _loadDashboard() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    if (kDebugMode) {
      debugPrint('[DASHBOARD] load start');
    }

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      // Load critical data first so dashboard can render quickly.
      final dashboard = await apiService
          .getDashboard()
          .timeout(const Duration(seconds: 30));
      if (kDebugMode) {
        final subjects = (dashboard['subjects'] as List?)?.length ?? 0;
        debugPrint('[DASHBOARD] primary loaded: subjects=$subjects');
      }

      // Non-critical requests should not block dashboard rendering.
      Map<String, dynamic>? profile;
      Map<String, dynamic>? motivation;
      try {
        profile = await apiService
            .getUserProfile()
            .timeout(const Duration(seconds: 20));
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[DASHBOARD] profile load skipped/error: $e');
        }
      }
      try {
        motivation = await apiService
            .getDailyMotivation()
            .timeout(const Duration(seconds: 20));
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[DASHBOARD] motivation load skipped/error: $e');
        }
      }

      if (!mounted) return;
      setState(() {
        _dashboardData = dashboard;
        _userProfile = profile;
        _userRole = profile?['role'] as String? ?? 'user';
        _motivation = motivation;
        _isLoading = false;
      });
      if (kDebugMode) {
        debugPrint('[DASHBOARD] render ready, role=$_userRole');
      }
      _showDashboardTutorial();
      _checkWeeklyRewards(apiService);
      await CompetencyGrowthNotifier.checkAndShowIfGained(context, apiService);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      if (kDebugMode) {
        debugPrint('[DASHBOARD] load failed: $e');
      }
    }
  }

  Future<void> _checkWeeklyRewards(ApiService api) async {
    try {
      final rewards = await api.getUnnotifiedRewards();
      if (!mounted || rewards.isEmpty) return;
      final r = rewards.first as Map<String, dynamic>;
      final rank = r['rank'] ?? 0;
      final diamonds = r['diamondsAwarded'] ?? 0;
      final badge = r['badgeCode'];
      final week = r['weekCode'] ?? '';

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.bgSecondary,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 28),
              SizedBox(width: 8),
              Expanded(child: Text('Phần thưởng tuần!')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Chúc mừng! Bạn đạt hạng #$rank tuần $week',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.diamond_rounded,
                      color: Colors.lightBlueAccent, size: 24),
                  const SizedBox(width: 6),
                  Text('+$diamonds',
                      style: AppTextStyles.h3
                          .copyWith(color: Colors.lightBlueAccent)),
                ],
              ),
              if (badge != null) ...[
                const SizedBox(height: 8),
                const Icon(Icons.workspace_premium_rounded,
                    color: Colors.amber, size: 32),
                Text('Huy hiệu: ${badge.toString().replaceAll('_', ' ')}',
                    style:
                        AppTextStyles.bodySmall.copyWith(color: Colors.amber)),
              ],
              if (rewards.length > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('và ${rewards.length - 1} phần thưởng khác...',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary)),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.push('/weekly-rewards-history');
              },
              child: const Text('Xem chi tiết'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tuyệt vời!'),
            ),
          ],
        ),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final hasData = !_isLoading && _error == null && _dashboardData != null;

    return Scaffold(
      appBar: null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasData)
            _buildPinnedLevelHeader(
              (_dashboardData!['stats'] as Map<String, dynamic>?) ?? {},
            ),
          Expanded(
            child: Stack(
              children: [
                if (_isLoading)
                  _buildSkeletonLoader()
                else if (_error != null)
                  AppErrorWidget(
                    message: _error!,
                    onRetry: _loadDashboard,
                  )
                else if (_dashboardData == null)
                  const Center(child: Text('Chưa có dữ liệu'))
                else
                  RefreshIndicator(
                    onRefresh: _loadDashboard,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_motivation != null &&
                              _motivation!['quote'] != null) ...[
                            _buildMotivationCard(_motivation!),
                            const SizedBox(height: 24),
                          ],
                          _buildOnboardingBanner(),
                          const SizedBox(height: 24),
                          _buildContinueLearningSection(
                            _dashboardData!['continueLearning']
                                as Map<String, dynamic>?,
                          ),
                          const SizedBox(height: 24),
                          _buildDailyQuestsSection(
                            _dashboardData!['dailyQuests'] as List<dynamic>?,
                          ),
                        ],
                      ),
                    ),
                  ),
                FloatingChatBubble(
                  showQuestShopShortcuts: true,
                  shortcutsTutorialKey: _quickActionsKey,
                  hasClaimableQuest: _hasClaimableDailyQuest(
                    _dashboardData!['dailyQuests'] as List<dynamic>?,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: KeyedSubtree(
        key: _bottomNavKey,
        child: const BottomNavBar(currentIndex: 0),
      ),
    );
  }

  /// Thanh cố định trên cùng: level + avatar + refresh/menu (thay cho AppBar).
  Widget _buildPinnedLevelHeader(Map<String, dynamic> stats) {
    final level = stats['level'] as int? ?? 1;
    final levelInfo = stats['levelInfo'] as Map<String, dynamic>?;
    final currentXP = levelInfo?['currentXP'] as int? ?? 0;
    final xpForNextLevel = levelInfo?['xpForNextLevel'] as int? ?? 100;
    final totalXP = stats['totalXP'] as int? ?? 0;
    final rawName = _userProfile?['fullName'] as String?;
    final displayName = (rawName != null && rawName.trim().isNotEmpty)
        ? rawName.trim()
        : 'Bạn học';
    final levelColor = AppColors.getLevelColor(level);
    final coins = stats['totalCoins'] ?? stats['coins'] ?? 0;
    final diamonds = stats['totalDiamonds'] ?? stats['diamonds'] ?? 0;
    final streak = stats['currentStreak'] ?? stats['streak'] ?? 0;

    return KeyedSubtree(
      key: _levelCardKey,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppGradients.forLevel(level),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
          boxShadow: [
            BoxShadow(
              color: levelColor.withOpacity(0.28),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 2, 8, 6),
            child: LevelCard(
              topBarStrip: true,
              level: level,
              title: _getLevelTitle(level),
              currentXP: currentXP,
              xpForNextLevel: xpForNextLevel,
              totalXP: totalXP,
              displayName: displayName,
              avatarUrl: _userProfile?['avatarUrl'] as String?,
              onAvatarTap: () => context.push('/profile'),
              onShowTitles: () => _showLevelTitlesDialog(),
              stripCoins: coins is int ? coins : int.tryParse('$coins') ?? 0,
              stripDiamonds:
                  diamonds is int ? diamonds : int.tryParse('$diamonds') ?? 0,
              stripStreak:
                  streak is int ? streak : int.tryParse('$streak') ?? 0,
              onStripCoinsTap: () => context.push('/shop'),
              onStripDiamondsTap: () => context.push('/payment'),
              onStripStreakTap: () => context.push('/currency'),
              stripResourcesKey: _statsRowKey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return const SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonCard(height: 150),
          SizedBox(height: 24),
          SkeletonCard(height: 120),
        ],
      ),
    );
  }

  /// Nhiệm vụ hoàn thành, chờ nhận thưởng (status `completed` từ API).
  bool _hasClaimableDailyQuest(List<dynamic>? list) {
    if (list == null) return false;
    for (final e in list) {
      if (e is Map && (e['status'] as String?) == 'completed') {
        return true;
      }
    }
    return false;
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
    final stats = _dashboardData?['stats'] as Map<String, dynamic>?;
    final currentLevel = stats?['level'] as int? ?? 1;
    final levelInfo = stats?['levelInfo'] as Map<String, dynamic>?;
    final currentXP = levelInfo?['currentXP'] as int? ?? 0;
    final xpForNextLevel = levelInfo?['xpForNextLevel'] as int? ?? 100;
    final totalXP = stats?['totalXP'] as int? ?? 0;
    final progress = xpForNextLevel > 0
        ? (currentXP / xpForNextLevel).clamp(0.0, 1.0)
        : 0.0;
    final titleName = _getLevelTitle(currentLevel);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.bgSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.bolt_rounded,
                        color: AppColors.cyanNeon, size: 26),
                    const SizedBox(width: 8),
                    Text(
                      'Kinh nghiệm',
                      style: AppTextStyles.h3.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.bgTertiary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderPrimary),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tổng XP: $totalXP',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tiến độ lên cấp ${currentLevel + 1}: $currentXP / $xpForNextLevel · ${(progress * 100).toStringAsFixed(1)}%',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: AppColors.borderPrimary,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.purpleNeon,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Level hiện tại: $currentLevel',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        'Danh hiệu: $titleName',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.military_tech,
                        color: Colors.amber.shade700, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      'Danh hiệu theo cấp',
                      style: AppTextStyles.h3.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
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
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Đóng',
                      style: TextStyle(color: AppColors.cyanNeon),
                    ),
                  ),
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
                  'Cấp $levelRange',
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

  Widget _buildMotivationCard(Map<String, dynamic> data) {
    final quote = data['quote'] as String? ?? '';
    final author = data['quoteAuthor'] as String? ?? '';
    final body = data['body'] as String? ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.purpleNeon.withOpacity(0.15),
            AppColors.cyanNeon.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.purpleNeon.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (body.isNotEmpty) ...[
            Text(
              body,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('💬', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '"$quote"',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    if (author.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '— $author',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textTertiary),
                        ),
                      ),
                  ],
                ),
              ),
            ],
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

  Future<void> _handleContinueLessonTap(Map<String, dynamic> lesson) async {
    final nodeId = lesson['id'] as String?;
    final title = lesson['title'] as String? ?? 'Bài học';
    if (nodeId == null || nodeId.isEmpty) return;

    try {
      final isLocked = lesson['isLocked'] as bool? ?? true;
      if (isLocked) {
        final api = Provider.of<ApiService>(context, listen: false);
        final opened = await LessonUnlockSheet.show(
          context: context,
          api: api,
          nodeId: nodeId,
          title: title,
        );
        if (!opened) return;
      }
      if (!mounted) return;
      await context.push('/lessons/$nodeId/types', extra: {'title': title});
      if (mounted) _loadDashboard();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: AppColors.errorNeon,
        ),
      );
    }
  }

  Widget _buildContinueLearningSection(Map<String, dynamic>? data) {
    final lessons = (data?['nextFreeLessons'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    final remaining = (data?['remainingFreeLessonsToday'] as num?)?.toInt();
    final freeTotal = (data?['freeLessonsPerDay'] as num?)?.toInt() ?? 2;

    final remainingText = remaining == null
        ? 'Chưa rõ miễn phí còn lại'
        : '${remaining}/${freeTotal} miễn phí còn lại';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    'Bài học hôm nay',
                    style: AppTextStyles.h3,
                  ),
                ),
                Text(
                  remainingText,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.xpGold,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          if (lessons.isEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Bạn chưa có bài phù hợp để tiếp tục ngay.',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
              child: Column(
                children: lessons.asMap().entries.map((entry) {
                  final index = entry.key;
                  final lesson = entry.value;

                  final title = (lesson['title'] as String?) ?? 'Bài học';
                  final isLocked = (lesson['isLocked'] as bool?) ?? false;
                  final diamondCost = (lesson['diamondCost'] as num?)?.toInt();

                  // Dashboard hiện chỉ trả `title/icon/isLocked/diamondCost`.
                  // Nếu backend sau này thêm expReward thì UI sẽ tự dùng giá trị đó.
                  final expReward =
                      (lesson['expReward'] as num?)?.toInt() ?? 50;

                  final subtitle = lesson['subtitle'] as String?;

                  final isFirst = index == 0;

                  return InkWell(
                    onTap: () => _handleContinueLessonTap(lesson),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      margin: EdgeInsets.only(
                        bottom: index == lessons.length - 1 ? 0 : 10,
                      ),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isLocked
                            ? AppColors.bgTertiary
                            : (isFirst ? const Color(0xFF1F9D55).withOpacity(0.22) : AppColors.bgTertiary),
                        border: Border.all(
                          color: isLocked
                              ? AppColors.borderPrimary.withOpacity(0.9)
                              : AppColors.successNeon.withOpacity(0.35),
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isLocked ? Colors.transparent : AppColors.successNeon.withOpacity(0.18),
                              border: Border.all(
                                color: isLocked
                                    ? AppColors.borderPrimary.withOpacity(0.9)
                                    : AppColors.successNeon.withOpacity(0.5),
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                isLocked ? Icons.lock_rounded : Icons.play_arrow_rounded,
                                size: 22,
                                color: isLocked ? AppColors.textTertiary : AppColors.successNeon,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.bodyBold.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                if (subtitle != null && subtitle.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: isLocked ? AppColors.textTertiary : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '+$expReward XP',
                                style: AppTextStyles.caption.copyWith(
                                  color: isLocked ? AppColors.textTertiary : AppColors.xpGold,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (isLocked && diamondCost != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  '$diamondCost 💎',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textTertiary,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDailyQuestsSection(List<dynamic>? dailyQuests) {
    final quests = (dailyQuests ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    final completedUnclaimed = quests.where((q) {
      final status = q['status'] as String? ?? 'active';
      return status == 'completed';
    }).toList();

    num sumCoins = 0;
    num sumXP = 0;
    for (final q in completedUnclaimed) {
      final quest = q['quest'] as Map<String, dynamic>? ?? const {};
      final rewards = quest['rewards'] as Map<String, dynamic>? ?? const {};
      sumXP += (rewards['xp'] as num?) ?? 0;
      sumCoins += (rewards['coin'] as num?) ?? 0;
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderPrimary),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    'Nhiệm vụ hôm nay',
                    style: AppTextStyles.h3,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.purpleNeon.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.purpleNeon.withOpacity(0.35),
                    ),
                  ),
                  child: Text(
                    'Đặc biệt',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.purpleNeon,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (quests.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Không có nhiệm vụ hôm nay.',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
              )
            else
              Column(
                children: quests.asMap().entries.map((entry) {
                  final index = entry.key;
                  final questWrapper = entry.value;
                  final quest = questWrapper['quest'] as Map<String, dynamic>? ?? const {};
                  final requirements = quest['requirements'] as Map<String, dynamic>? ?? const {};
                  final rewards = quest['rewards'] as Map<String, dynamic>? ?? const {};

                  final title = quest['title'] as String? ?? 'Nhiệm vụ';
                  final status = questWrapper['status'] as String? ?? 'active';
                  final progressNum = (questWrapper['progress'] as num?) ?? 0;
                  final targetNum =
                      (questWrapper['target'] as num?) ?? (requirements['target'] as num?) ?? 1;

                  final progress = progressNum.toDouble();
                  final target = targetNum.toDouble().clamp(1.0, double.infinity);
                  final percent = (progress / target).clamp(0.0, 1.0);
                  final isCompleted = status == 'completed';
                  final isClaimed = status == 'claimed';

                  final xpReward = (rewards['xp'] as num?)?.toInt();
                  final coinReward = (rewards['coin'] as num?)?.toInt();

                  final canClaim = isCompleted && !isClaimed;

                  return Container(
                    margin: EdgeInsets.only(bottom: index == quests.length - 1 ? 0 : 10),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isCompleted || isClaimed
                                    ? AppColors.successNeon.withOpacity(0.16)
                                    : Colors.transparent,
                                border: Border.all(
                                  color: isCompleted || isClaimed
                                      ? AppColors.successNeon.withOpacity(0.6)
                                      : AppColors.borderPrimary.withOpacity(0.9),
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  isCompleted
                                      ? Icons.check_rounded
                                      : isClaimed
                                          ? Icons.check_rounded
                                          : Icons.circle_outlined,
                                  size: 14,
                                  color: isCompleted || isClaimed
                                      ? AppColors.successNeon
                                      : AppColors.textTertiary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    title,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: isCompleted || isClaimed
                                          ? AppColors.textPrimary
                                          : AppColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (xpReward != null || coinReward != null) ...[
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        if (coinReward != null) ...[
                                          Text(
                                            '+${coinReward.toInt()} xu',
                                            style: AppTextStyles.caption.copyWith(
                                              color: AppColors.coinGold,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          if (xpReward != null) const SizedBox(width: 8),
                                        ],
                                        if (xpReward != null)
                                          Text(
                                            '+${xpReward.toInt()} XP',
                                            style: AppTextStyles.caption.copyWith(
                                              color: AppColors.xpGold,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              height: 30,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  backgroundColor: canClaim
                                      ? AppColors.successNeon
                                      : AppColors.bgTertiary,
                                  foregroundColor:
                                      canClaim ? Colors.black : AppColors.textSecondary,
                                  elevation: canClaim ? 4 : 0,
                                  textStyle: AppTextStyles.labelSmall.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                                onPressed: () async {
                                  if (canClaim) {
                                    // Nhận thưởng: dùng cùng API với màn Nhiệm vụ để đồng bộ trạng thái.
                                    try {
                                      final api = Provider.of<ApiService>(
                                        context,
                                        listen: false,
                                      );
                                      await api.claimQuest(
                                        questWrapper['id'] as String,
                                      );
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Row(
                                            children: [
                                              Icon(Icons.celebration,
                                                  color: Colors.white),
                                              SizedBox(width: 8),
                                              Text('Đã nhận phần thưởng!'),
                                            ],
                                          ),
                                          backgroundColor: AppColors.successNeon,
                                        ),
                                      );
                                      await _loadDashboard();
                                    } catch (e) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Lỗi: $e'),
                                          backgroundColor: AppColors.errorNeon,
                                        ),
                                      );
                                    }
                                  } else {
                                    // Chưa hoàn thành: dẫn tới màn Nhiệm vụ để user xem chi tiết.
                                    if (!mounted) return;
                                    HapticFeedback.lightImpact();
                                    context.push('/quests');
                                  }
                                },
                                child: Text(
                                  canClaim
                                      ? 'Nhận'
                                      : (isClaimed ? 'Đã nhận' : 'Đến'),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (!isCompleted && !isClaimed) ...[
                          const SizedBox(height: 10),
                          LinearProgressIndicator(
                            value: percent,
                            minHeight: 8,
                            backgroundColor: AppColors.bgTertiary,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.cyanNeon.withOpacity(0.9),
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${progressNum.toInt()} / ${targetNum.toInt()} hoàn thành',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            if (completedUnclaimed.isNotEmpty) ...[
              const SizedBox(height: 14),
              Divider(color: AppColors.borderPrimary.withOpacity(0.6)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    'Phần thưởng khi xong',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '+${sumCoins.toInt()} xu ',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.coinGold,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text: '+${sumXP.toInt()} XP',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.xpGold,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildCurrentLearningSection(List<dynamic> nodes) {
    if (nodes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chủ đề đang học',
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

  // ignore: unused_element
  Widget _buildSubjectsSection(String title, List<dynamic> subjects) {
    final totalCount = subjects.length + (_isContributor ? 1 : 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: AppTextStyles.h3),
            const Spacer(),
            // Search button
            IconButton(
              icon: const Icon(Icons.search, color: AppColors.textSecondary),
              tooltip: 'Tìm môn học',
              onPressed: () => _showSubjectSearchDialog(subjects),
            ),
            if (_isContributor) ...[
              const SizedBox(width: 4),
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

  Future<void> _showSubjectSearchDialog(List<dynamic> subjects) async {
    final searchController = TextEditingController();
    List<dynamic> filtered = List<dynamic>.from(subjects);

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            void applyAndSetState() {
              final q = searchController.text.toLowerCase().trim();
              filtered = q.isEmpty
                  ? List<dynamic>.from(subjects)
                  : subjects
                      .where((s) =>
                          (s['name'] as String? ?? '')
                              .toLowerCase()
                              .contains(q) ||
                          (s['description'] as String? ?? '')
                              .toLowerCase()
                              .contains(q))
                      .toList();
              setState(() {});
            }

            return AlertDialog(
              title: const Text('Tìm môn học'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: searchController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Nhập tên hoặc mô tả môn học',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (_) => applyAndSetState(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.maxFinite,
                    height: 260,
                    child: filtered.isEmpty
                        ? const Center(
                            child: Text('Không tìm thấy môn phù hợp'),
                          )
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final subject = filtered[index];
                              final subjectId = subject['id'] as String?;
                              final name =
                                  subject['name'] as String? ?? 'Môn học';
                              final description =
                                  subject['description'] as String?;
                              final metadata =
                                  subject['metadata'] as Map<String, dynamic>?;
                              final icon = metadata?['icon'] as String? ?? '📚';

                              return ListTile(
                                leading: Text(icon,
                                    style: const TextStyle(fontSize: 24)),
                                title: Text(name),
                                subtitle: description != null
                                    ? Text(
                                        description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      )
                                    : null,
                                onTap: () {
                                  Navigator.pop(context);
                                  if (subjectId != null) {
                                    context.push('/subjects/$subjectId/intro');
                                  }
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Đóng'),
                ),
              ],
            );
          },
        );
      },
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
