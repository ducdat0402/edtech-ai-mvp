import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:edtech_mobile/core/constants/currency_labels.dart';
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

  /// Xóa cache tĩnh khi đăng xuất (tránh flash dữ liệu user cũ khi đăng nhập lại).
  static void clearMemoryCache() => _DashboardScreenState.clearMemoryCache();

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const double _kSectionGap = 24;
  static const double _kSectionInnerPadding = 16;
  /// Dùng làm padding đầu scroll / mép refresh trước khi đo được hero thật.
  static const double _kHeroHeaderFallbackHeight = 172;

  bool _heroMeasurePending = false;
  double? _heroPaintedHeight;

  /// Khoảng cách thẻ chào/động lực → block tiếp (banner thường trống → tránh 24+24).
  static const double _kGapMotivationToNext = 10;

  final ScrollController _dashboardScrollController = ScrollController();

  static void clearMemoryCache() {
    _cachedDashboardData = null;
    _cachedMotivation = null;
    _cachedUserProfile = null;
    _cachedUserRole = 'user';
  }

  Map<String, dynamic>? _dashboardData;
  Map<String, dynamic>? _motivation;
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;

  /// Đang tải lại khi đã có dữ liệu hiển thị (cache) — hiện thanh progress, không xóa nội dung.
  bool _isRefreshing = false;
  String? _error;
  String _userRole = 'user';

  // Keep a short in-memory cache so returning to Home doesn't show skeleton.
  static Map<String, dynamic>? _cachedDashboardData;
  static Map<String, dynamic>? _cachedMotivation;
  static Map<String, dynamic>? _cachedUserProfile;
  static String _cachedUserRole = 'user';

  // Tutorial keys
  final _levelCardKey = GlobalKey();
  final GlobalKey _heroMeasureKey = GlobalKey();
  final _statsRowKey = GlobalKey();
  final _quickActionsKey = GlobalKey();
  final _bottomNavKey = GlobalKey();

  bool get _isContributor => _userRole == 'contributor';

  @override
  void initState() {
    super.initState();
    if (_cachedDashboardData != null) {
      _dashboardData = _cachedDashboardData;
      _motivation = _cachedMotivation;
      _userProfile = _cachedUserProfile;
      _userRole = _cachedUserRole;
      _isLoading = false;
      _error = null;
    }
    _loadDashboard();
  }

  @override
  void dispose() {
    _dashboardScrollController.dispose();
    super.dispose();
  }

  void _scheduleHeroHeightMeasure() {
    if (_heroMeasurePending) return;
    _heroMeasurePending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _heroMeasurePending = false;
      if (!mounted) return;
      final ctx = _heroMeasureKey.currentContext;
      if (ctx == null) return;
      final ro = ctx.findRenderObject();
      if (ro is! RenderBox || !ro.hasSize) return;
      final h = ro.size.height;
      if (_heroPaintedHeight == null ||
          (h - _heroPaintedHeight!).abs() > 0.5) {
        setState(() => _heroPaintedHeight = h);
      }
    });
  }

  void _showDashboardTutorial() {
    if (!mounted || _dashboardData == null) return;

    final targets = [
      TutorialHelper.buildTarget(
        key: _levelCardKey,
        title: 'Cấp độ & kinh nghiệm',
        description:
            'Cấp độ hiển thị dưới avatar. Hoàn thành bài học để nhận XP và lên cấp!',
        icon: Icons.military_tech,
        stepLabel: 'Bước 1/4',
      ),
      TutorialHelper.buildTarget(
        key: _statsRowKey,
        title: 'Tài nguyên của bạn',
        description:
            'Kim cương, đồng GAMISTU và streak nằm dưới lời chào. Chạm kim cương để nạp; chạm đồng GAMISTU để mở Cửa hàng; chạm streak để xem tiến độ.',
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
            'Chuyển nhanh giữa Trang chủ, Thư viện, Của tôi và Profile.',
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
    final hadCachedData = _dashboardData != null;
    setState(() {
      _isLoading = !hadCachedData;
      _isRefreshing = hadCachedData;
      _error = null;
    });
    if (kDebugMode) {
      debugPrint('[DASHBOARD] load start (cached=$hadCachedData)');
    }

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final dashboard =
          await apiService.getDashboard().timeout(const Duration(seconds: 30));
      if (kDebugMode) {
        final subjects = (dashboard['subjects'] as List?)?.length ?? 0;
        debugPrint('[DASHBOARD] primary loaded: subjects=$subjects');
      }

      if (!mounted) return;
      // Hiển thị nội dung chính ngay sau dashboard; profile & motivation song song.
      setState(() {
        _dashboardData = dashboard;
        _isLoading = false;
        _isRefreshing = true;
        _cachedDashboardData = dashboard;
      });

      Future<Map<String, dynamic>?> loadProfile() async {
        try {
          return await apiService
              .getUserProfile()
              .timeout(const Duration(seconds: 20));
        } catch (e) {
          if (kDebugMode) {
            debugPrint('[DASHBOARD] profile load skipped/error: $e');
          }
          return null;
        }
      }

      Future<Map<String, dynamic>?> loadMotivation() async {
        try {
          return await apiService
              .getDailyMotivation()
              .timeout(const Duration(seconds: 20));
        } catch (e) {
          if (kDebugMode) {
            debugPrint('[DASHBOARD] motivation load skipped/error: $e');
          }
          return null;
        }
      }

      final secondary = await Future.wait([loadProfile(), loadMotivation()]);
      final profile = secondary[0] ?? _userProfile ?? _cachedUserProfile;
      final motivation = secondary[1] ?? _motivation ?? _cachedMotivation;

      if (!mounted) return;
      setState(() {
        _userProfile = profile;
        _userRole = profile?['role'] as String? ?? _userRole;
        _motivation = motivation;
        _isRefreshing = false;
        _cachedMotivation = motivation;
        _cachedUserProfile = profile;
        _cachedUserRole = profile?['role'] as String? ?? _userRole;
      });
      if (kDebugMode) {
        debugPrint('[DASHBOARD] render ready, role=$_userRole');
      }
      _showDashboardTutorial();
      _checkWeeklyRewards(apiService);
      // Không chặn luồng load — tránh thêm 1 round-trip API trước khi UI “nhẹ”.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(
          CompetencyGrowthNotifier.checkAndShowIfGained(context, apiService),
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
        _error = hadCachedData ? null : e.toString();
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
        builder: (ctx) {
          final sem = ctx.colors;
          return AlertDialog(
            backgroundColor: sem.card,
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
                  style:
                      AppTextStyles.bodyMedium.copyWith(color: sem.textPrimary),
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
                      style: AppTextStyles.bodySmall
                          .copyWith(color: Colors.amber)),
                ],
                if (rewards.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('và ${rewards.length - 1} phần thưởng khác...',
                        style: AppTextStyles.caption
                            .copyWith(color: sem.textSecondary)),
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
          );
        },
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final hasData = !_isLoading && _error == null && _dashboardData != null;
    if (hasData) {
      _scheduleHeroHeightMeasure();
    }
    final sem = context.colors;
    final stats = hasData
        ? ((_dashboardData!['stats'] as Map<String, dynamic>?) ?? const {})
        : const <String, dynamic>{};
    final subjects = hasData
        ? ((_dashboardData!['subjects'] as List<dynamic>?) ?? const [])
        : const <dynamic>[];

    return Scaffold(
      backgroundColor: sem.bg,
      appBar: null,
      body: Stack(
        children: [
          Positioned.fill(
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
                      controller: _dashboardScrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        _kSectionInnerPadding,
                        hasData
                            ? (_heroPaintedHeight ??
                                _kHeroHeaderFallbackHeight)
                            : 12,
                        _kSectionInnerPadding,
                        24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildContinueLearningSection(
                            _dashboardData!['continueLearning']
                                as Map<String, dynamic>?,
                          ),
                          const SizedBox(height: 14),
                          _buildStatsChipsRow(stats),
                          const SizedBox(height: _kSectionGap),
                          _buildSuggestedSubjectsSection(subjects),
                          const SizedBox(height: _kSectionGap),
                          _buildDailyQuestsSection(
                            _dashboardData!['dailyQuests'] as List<dynamic>?,
                            _dashboardData!['continueLearning']
                                as Map<String, dynamic>?,
                          ),
                          if (_motivation != null &&
                              _motivation!['quote'] != null) ...[
                            const SizedBox(height: _kSectionGap),
                            _buildMotivationCard(_motivation!),
                            const SizedBox(height: _kGapMotivationToNext),
                          ],
                          const SizedBox(height: _kSectionGap),
                          _buildOnboardingBanner(),
                        ],
                      ),
                    ),
                  ),
                FloatingChatBubble(
                  showQuestShopShortcuts: true,
                  shortcutsTutorialKey: _quickActionsKey,
                  hasClaimableQuest: _hasClaimableDailyQuest(
                    _dashboardData?['dailyQuests'] as List<dynamic>?,
                  ),
                ),
              ],
            ),
          ),
          if (hasData)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildHeroHeader(stats),
            ),
          if (_isRefreshing && hasData)
            Positioned(
              top: (_heroPaintedHeight ?? _kHeroHeaderFallbackHeight) - 2,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 3,
                child: LinearProgressIndicator(
                  minHeight: 3,
                  backgroundColor: sem.cardMuted,
                  color: Color.lerp(sem.brand, sem.textOnBrand, 0.55)!,
                ),
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

  Widget _buildHeroHeader(Map<String, dynamic> stats) {
    final sem = context.colors;
    final diamonds = (stats['totalDiamonds'] as num?)?.toInt() ??
        (stats['diamonds'] as num?)?.toInt() ??
        0;
    final totalCoins = (stats['totalCoins'] as num?)?.toInt() ?? 0;
    final streak = (stats['currentStreak'] as num?)?.toInt() ??
        (stats['streak'] as num?)?.toInt() ??
        0;
    final nameRaw = _userProfile?['fullName'] as String?;
    final displayName = (nameRaw != null && nameRaw.trim().isNotEmpty)
        ? nameRaw.trim()
        : 'Bạn học';

    return KeyedSubtree(
      key: _levelCardKey,
      child: Container(
        key: _heroMeasureKey,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              sem.brandStrong,
              sem.brand,
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => context.push('/profile'),
                      child: Column(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: sem.card,
                              border: Border.all(color: sem.gold, width: 1.2),
                            ),
                            child: Center(
                              child: Text(
                                _initials(displayName),
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: sem.textPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: sem.gold.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Lv.${stats['level'] ?? 1}',
                              style: AppTextStyles.caption.copyWith(
                                color:
                                    Theme.of(context).colorScheme.onSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: AppTextStyles.h3.copyWith(
                            color: sem.textOnBrand,
                            fontWeight: FontWeight.w700,
                          ),
                          children: [
                            TextSpan(text: '${_timeGreeting()}, '),
                            TextSpan(
                              text: displayName,
                              style: AppTextStyles.h3.copyWith(
                                color: sem.gold,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _showLevelTitlesDialog,
                      icon: Icon(
                        Icons.notifications_rounded,
                        color: sem.textOnBrand,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  key: _statsRowKey,
                  children: [
                    Expanded(
                      child: _buildHeroMetricChip(
                        icon: Icons.diamond_rounded,
                        iconColor: sem.info,
                        value: '$diamonds',
                        trailingAdd: true,
                        onTap: () => context.push('/payment'),
                        valueFontSize: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildHeroMetricChip(
                        leading: const GtuCoinIcon(size: 18),
                        value: '$totalCoins',
                        onTap: () => context.push('/shop'),
                        valueFontSize: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildHeroMetricChip(
                        icon: Icons.local_fire_department_rounded,
                        iconColor: sem.warning,
                        value: '$streak',
                        onTap: () => context.push('/currency'),
                        valueFontSize: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroMetricChip({
    IconData? icon,
    Color? iconColor,
    Widget? leading,
    required String value,
    bool trailingAdd = false,
    VoidCallback? onTap,
    double valueFontSize = 21,
  }) {
    final sem = context.colors;
    final Widget prefix;
    if (leading != null) {
      prefix = leading;
    } else if (icon != null && iconColor != null) {
      prefix = Icon(
        icon,
        size: 18,
        color: iconColor.withValues(alpha: 0.98),
      );
    } else {
      prefix = const SizedBox(width: 18, height: 18);
    }
    final child = Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.36)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          prefix,
          const SizedBox(width: 4),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                style: AppTextStyles.bodyBold.copyWith(
                  color: sem.textOnBrand,
                  fontSize: valueFontSize,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          if (trailingAdd) ...[
            const SizedBox(width: 4),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(Icons.add, size: 13, color: sem.textOnBrand),
            ),
          ],
        ],
      ),
    );
    if (onTap == null) return child;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: child,
    );
  }

  Widget _buildStatsChipsRow(Map<String, dynamic> stats) {
    final sem = context.colors;
    final completedLessons = (stats['completedLessons'] as num?)?.toInt() ?? 3;
    final streak = (stats['currentStreak'] as num?)?.toInt() ??
        (stats['streak'] as num?)?.toInt() ??
        0;
    final xpDelta = (stats['weeklyXP'] as num?)?.toInt() ??
        (stats['todayXP'] as num?)?.toInt() ??
        180;
    final competency =
        ((stats['competencyUpdates'] as num?)?.toInt() ?? 2).clamp(0, 99);
    return Row(
      children: [
        Expanded(
          child: _buildSmallStatChip(
            icon: Icons.menu_book_rounded,
            value: '$completedLessons',
            iconColor: sem.brand,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSmallStatChip(
            icon: Icons.local_fire_department_rounded,
            value: '$streak',
            iconColor: sem.warning,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSmallStatChip(
            icon: Icons.star_rounded,
            value: '+$xpDelta',
            iconColor: sem.gold,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSmallStatChip(
            icon: Icons.tips_and_updates_outlined,
            value: '$competency',
            iconColor: sem.info,
          ),
        ),
      ],
    );
  }

  Widget _buildSmallStatChip({
    required IconData icon,
    required String value,
    required Color iconColor,
  }) {
    final sem = context.colors;
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: sem.card,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: sem.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.h4.copyWith(
                color: sem.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedSubjectsSection(List<dynamic> subjects) {
    final sem = context.colors;
    final mapped = subjects
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gợi ý cho bạn',
          style: AppTextStyles.h2.copyWith(
            color: sem.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        if (mapped.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: sem.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: sem.border),
            ),
            child: Text(
              'Chưa có môn học phù hợp, hãy khám phá trong Thư viện.',
              style: AppTextStyles.bodySmall.copyWith(
                color: sem.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else
          Column(
            children: mapped.take(2).map((subject) {
              final subjectId = subject['id'] as String?;
              final name = subject['name'] as String? ?? 'Môn học';
              final totalNodes = (subject['totalNodesCount'] as num?)?.toInt();
              final learners = (subject['totalLearners'] as num?)?.toInt();
              final subtitle = '${totalNodes ?? 0} bài · '
                  '${learners != null ? '${(learners / 1000).toStringAsFixed(1)}k' : '--'} người học';
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SubjectListTile(
                  name: name,
                  subtitle: subtitle,
                  leadingIcon: Icons.school_rounded,
                  actionLabel: 'Học',
                  onTap: () {
                    if (subjectId != null) {
                      context.push('/subjects/$subjectId/intro');
                    }
                  },
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  String _timeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    final first = parts.first.substring(0, 1);
    final last = parts.last.substring(0, 1);
    return '$first$last'.toUpperCase();
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
    final progress =
        xpForNextLevel > 0 ? (currentXP / xpForNextLevel).clamp(0.0, 1.0) : 0.0;
    final titleName = _getLevelTitle(currentLevel);

    showDialog(
      context: context,
      builder: (dialogContext) {
        final sem = dialogContext.colors;
        final brandHi = Color.lerp(sem.brand, sem.textOnBrand, 0.55)!;
        return Dialog(
          backgroundColor: sem.card,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                      Icon(Icons.bolt_rounded, color: brandHi, size: 26),
                      const SizedBox(width: 8),
                      Text(
                        'Kinh nghiệm',
                        style: AppTextStyles.h3.copyWith(
                          color: sem.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: sem.cardMuted,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: sem.border.withValues(alpha: 0.65)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tổng XP: $totalXP',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: sem.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tiến độ lên cấp ${currentLevel + 1}: $currentXP / $xpForNextLevel · ${(progress * 100).toStringAsFixed(1)}%',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: sem.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: sem.cardMuted,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(sem.success),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Level hiện tại: $currentLevel',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: sem.textSecondary,
                          ),
                        ),
                        Text(
                          'Danh hiệu: $titleName',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: sem.textPrimary,
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
                          color: sem.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildLevelTitleRow(
                      'Người mới',
                      '1 - 5',
                      Icons.emoji_people,
                      LevelPalette.levelNewbie,
                      currentLevel >= 1 && currentLevel <= 5,
                      sem),
                  _buildLevelTitleRow(
                      'Học viên',
                      '6 - 10',
                      Icons.school,
                      LevelPalette.levelStudent,
                      currentLevel >= 6 && currentLevel <= 10,
                      sem),
                  _buildLevelTitleRow(
                      'Sinh viên',
                      '11 - 20',
                      Icons.menu_book,
                      LevelPalette.levelScholar,
                      currentLevel >= 11 && currentLevel <= 20,
                      sem),
                  _buildLevelTitleRow(
                      'Chuyên gia',
                      '21 - 35',
                      Icons.psychology,
                      LevelPalette.levelExpert,
                      currentLevel >= 21 && currentLevel <= 35,
                      sem),
                  _buildLevelTitleRow(
                      'Bậc thầy',
                      '36 - 50',
                      Icons.workspace_premium,
                      LevelPalette.levelMaster,
                      currentLevel >= 36 && currentLevel <= 50,
                      sem),
                  _buildLevelTitleRow(
                      'Huyền thoại',
                      '51 - 75',
                      Icons.auto_awesome,
                      LevelPalette.levelLegend,
                      currentLevel >= 51 && currentLevel <= 75,
                      sem),
                  _buildLevelTitleRow('Thần đồng', '76+', Icons.diamond,
                      LevelPalette.levelProdigy, currentLevel >= 76, sem),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Đóng',
                        style: TextStyle(color: brandHi),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLevelTitleRow(
    String title,
    String levelRange,
    IconData icon,
    Color tierColor,
    bool isCurrent,
    SemanticColors sem,
  ) {
    final brandHi = Color.lerp(sem.brand, sem.textOnBrand, 0.55)!;
    final muted = LevelPalette.tierAccentMuted(tierColor, sem.card);
    final leftBar = isCurrent ? muted : muted.withValues(alpha: 0.42);
    final iconTint = LevelPalette.tierIconTint(
      tierColor,
      isCurrent: isCurrent,
      towardSurface: sem.card,
      mutedText: sem.textTertiary,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isCurrent ? sem.cardMuted : sem.cardOverlay,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: sem.border.withValues(alpha: 0.65)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: leftBar),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color:
                              muted.withValues(alpha: isCurrent ? 0.14 : 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(icon, color: iconTint, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isCurrent
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: sem.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Cấp $levelRange',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: sem.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isCurrent)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: brandHi.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: brandHi.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            'Hiện tại',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: brandHi,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMotivationCard(Map<String, dynamic> data) {
    final sem = context.colors;
    final quote = data['quote'] as String? ?? '';
    final author = data['quoteAuthor'] as String? ?? '';
    final body = data['body'] as String? ?? '';

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: sem.card,
        border: Border.all(color: sem.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (body.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 20,
                    color: sem.brand,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      body,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: sem.textPrimary,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (quote.isNotEmpty) const SizedBox(height: 14),
            ],
            if (quote.isNotEmpty) ...[
              Text(
                '"$quote"',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: sem.textPrimary,
                  fontStyle: FontStyle.italic,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (author.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '— $author',
                    style: AppTextStyles.caption.copyWith(
                      color: sem.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingBanner() {
    // Onboarding đã được tích hợp vào Personal Mind Map screen
    // Không hiển thị banner ở dashboard nữa
    return const SizedBox.shrink();
  }

  /// Nhãn nút nhiệm vụ: **ĐẾN** khi điều hướng; giữ Nhận / Đã nhận khi có thưởng.
  String _questPrimaryCtaLabel(bool canClaim, bool isClaimed) {
    if (canClaim) return 'Nhận';
    if (isClaimed) return 'Đã nhận';
    return 'ĐẾN';
  }

  void _navigateForQuestType(String questType) {
    switch (questType) {
      case 'earn_coins':
        context.push('/shop');
        return;
      case 'earn_xp':
      case 'complete_items':
      case 'complete_daily_lesson':
      case 'complete_node':
        context.push('/library');
        return;
      case 'maintain_streak':
        context.push('/currency');
        return;
      default:
        context.push('/quests');
    }
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
          backgroundColor: context.colors.error,
        ),
      );
    }
  }

  Future<void> _handleDailyQuestCta({
    required bool canClaim,
    required bool isClaimed,
    required String? questParticipationId,
    required String questType,
  }) async {
    if (isClaimed ||
        questParticipationId == null ||
        questParticipationId.isEmpty) {
      return;
    }
    if (canClaim) {
      try {
        final api = Provider.of<ApiService>(context, listen: false);
        await api.claimQuest(questParticipationId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.celebration, color: context.colors.textOnBrand),
                const SizedBox(width: 8),
                Text(
                  'Đã nhận phần thưởng!',
                  style: TextStyle(
                    color: context.colors.textOnBrand,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            backgroundColor: context.colors.success,
          ),
        );
        await _loadDashboard();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: context.colors.error,
          ),
        );
      }
    } else {
      if (!mounted) return;
      HapticFeedback.lightImpact();
      _navigateForQuestType(questType);
    }
  }

  Widget _buildContinueLearningSection(Map<String, dynamic>? data) {
    final sem = context.colors;
    final lessons = (data?['nextFreeLessons'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final firstLesson = lessons.isNotEmpty ? lessons.first : null;
    final recentSubject = data?['recentSubject'] as Map<String, dynamic>?;
    final continueTitle = (firstLesson?['title'] as String?) ??
        (recentSubject?['name'] as String?) ??
        'Bạn chưa có bài cần học tiếp';
    final progress = ((firstLesson?['progress'] as num?)?.toDouble() ?? 0.45)
        .clamp(0.05, 1.0);
    final lessonInfo = firstLesson != null
        ? '${(firstLesson['estimatedMinutes'] as num?)?.toInt() ?? 10} phút'
        : 'Sẵn sàng bắt đầu';

    final lessonForTap = firstLesson;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: sem.card,
        border: Border.all(color: sem.border),
        boxShadow: [
          BoxShadow(
            color: sem.brand.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: sem.info.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.auto_stories_rounded,
                    color: sem.info,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tiếp tục học',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: sem.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        continueTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.h3.copyWith(
                          height: 1.15,
                          color: sem.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 8,
                                backgroundColor: sem.cardMuted,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  sem.gold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${(progress * 100).round()}%',
                            style: AppTextStyles.caption.copyWith(
                              color: sem.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lessonInfo,
                        style: AppTextStyles.caption.copyWith(
                          color: sem.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    if (lessonForTap != null) {
                      _handleContinueLessonTap(lessonForTap);
                    } else {
                      context.push('/library');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: sem.brand,
                    foregroundColor: sem.textOnBrand,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    textStyle: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  child: const Text('Tiếp'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildTodayLessonTile({
    required Map<String, dynamic> lesson,
    required int index,
    required bool isLast,
    required VoidCallback onTap,
  }) {
    final sem = context.colors;
    final brandHi = Color.lerp(sem.brand, sem.textOnBrand, 0.55)!;
    final title = (lesson['title'] as String?) ?? 'Bài học';
    final isLocked = (lesson['isLocked'] as bool?) ?? false;
    final diamondCost = (lesson['diamondCost'] as num?)?.toInt();
    final expReward = (lesson['expReward'] as num?)?.toInt() ?? 50;
    final isFirst = index == 0;

    final accentGradient = isLocked
        ? null
        : (isFirst
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  sem.success.withValues(alpha: 0.1),
                  sem.cardMuted,
                  sem.cardOverlay.withValues(alpha: 0.9),
                ],
                stops: const [0.0, 0.45, 1.0],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  sem.brand.withValues(alpha: 0.12),
                  sem.cardMuted,
                  sem.cardOverlay.withValues(alpha: 0.95),
                ],
                stops: const [0.0, 0.5, 1.0],
              ));

    final borderColor = isLocked
        ? const Color(0x442D363D)
        : (isFirst
            ? sem.success.withValues(alpha: 0.28)
            : sem.brand.withValues(alpha: 0.24));

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: accentGradient,
              color: accentGradient == null ? sem.cardMuted : null,
              border: Border.all(color: borderColor),
              boxShadow: isLocked
                  ? null
                  : [
                      BoxShadow(
                        color: (isFirst ? sem.success : sem.brand)
                            .withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isLocked)
                        Padding(
                          padding: const EdgeInsets.only(top: 2, right: 10),
                          child: Container(
                            width: 4,
                            height: 36,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              gradient: isFirst
                                  ? LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        sem.success.withValues(alpha: 0.55),
                                        sem.success.withValues(alpha: 0.28),
                                      ],
                                    )
                                  : LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        brandHi.withValues(alpha: 0.45),
                                        sem.brand.withValues(alpha: 0.38),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyBold.copyWith(
                            color: sem.textPrimary,
                            height: 1.35,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isLocked)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Icon(
                                Icons.lock_rounded,
                                size: 16,
                                color: sem.textTertiary,
                              ),
                            ),
                          Container(
                            height: 34,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                            ),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              gradient: isLocked
                                  ? null
                                  : LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        brandHi.withValues(alpha: 0.75),
                                        sem.brand.withValues(alpha: 0.65),
                                      ],
                                    ),
                              color: isLocked ? sem.card : null,
                              border: Border.all(
                                color: isLocked
                                    ? const Color(0x552D363D)
                                    : Colors.transparent,
                              ),
                              boxShadow: isLocked
                                  ? null
                                  : [
                                      BoxShadow(
                                        color:
                                            sem.brand.withValues(alpha: 0.14),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                            ),
                            child: Text(
                              'ĐẾN',
                              style: AppTextStyles.labelSmall.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                                color: isLocked
                                    ? sem.textTertiary
                                    : sem.textOnBrand.withValues(alpha: 0.95),
                                letterSpacing: 0.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isLocked
                              ? sem.card.withValues(alpha: 0.6)
                              : sem.gold.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isLocked
                                ? const Color(0x332D363D)
                                : sem.gold.withValues(alpha: 0.28),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bolt_rounded,
                              size: 15,
                              color: isLocked ? sem.textTertiary : sem.gold,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '+$expReward XP',
                              style: AppTextStyles.caption.copyWith(
                                color: isLocked ? sem.textTertiary : sem.gold,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (isLocked && diamondCost != null)
                        Text(
                          '$diamondCost 💎',
                          style: AppTextStyles.caption.copyWith(
                            color: sem.textTertiary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
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
  }

  Widget _buildDailyQuestsSection(
    List<dynamic>? dailyQuests,
    Map<String, dynamic>? continueLearning,
  ) {
    final quests = (dailyQuests ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    final completedUnclaimed = quests.where((q) {
      final status = q['status'] as String? ?? 'active';
      return status == 'completed';
    }).toList();

    final recentSubject =
        continueLearning?['recentSubject'] as Map<String, dynamic>?;
    final recentSubjectName = recentSubject?['name'] as String?;

    num sumCoins = 0;
    num sumXP = 0;
    for (final q in completedUnclaimed) {
      final quest = q['quest'] as Map<String, dynamic>? ?? const {};
      final rewards = quest['rewards'] as Map<String, dynamic>? ?? const {};
      sumXP += (rewards['xp'] as num?) ?? 0;
      sumCoins += (rewards['coin'] as num?) ?? 0;
    }

    final activeQuestCount = quests.where((q) {
      final s = q['status'] as String? ?? 'active';
      return s == 'active';
    }).length;

    final sem = context.colors;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: sem.card,
        border: Border.all(color: sem.border),
        boxShadow: [
          BoxShadow(
            color: sem.brand.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              _kSectionInnerPadding,
              _kSectionInnerPadding,
              _kSectionInnerPadding,
              10,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: sem.warning.withValues(alpha: 0.14),
                        border: Border.all(color: sem.border),
                      ),
                      child: Icon(
                        Icons.emoji_events_rounded,
                        color: sem.warning,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Nhiệm vụ hôm nay',
                        style: AppTextStyles.h3.copyWith(
                          letterSpacing: 0.15,
                          color: sem.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (quests.isNotEmpty && activeQuestCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: sem.cardMuted,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: sem.border),
                        ),
                        child: Text(
                          '$activeQuestCount đang làm',
                          style: AppTextStyles.caption.copyWith(
                            color: sem.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.15,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Hoàn thành để nhận thêm ${CurrencyLabels.gtuCoin} và XP.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: sem.textPrimary,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                _buildQuestMilestoneRow(
                  completedCount: quests
                      .where((q) => (q['status'] as String?) == 'claimed')
                      .length,
                ),
              ],
            ),
          ),
          if (quests.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                'Không có nhiệm vụ hôm nay.',
                style:
                    AppTextStyles.bodySmall.copyWith(color: sem.textSecondary),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
              child: Column(
                children: quests.asMap().entries.map((entry) {
                  final index = entry.key;
                  final questWrapper = entry.value;
                  final quest =
                      questWrapper['quest'] as Map<String, dynamic>? ??
                          const {};
                  final requirements =
                      quest['requirements'] as Map<String, dynamic>? ??
                          const {};
                  final rewards =
                      quest['rewards'] as Map<String, dynamic>? ?? const {};

                  final title = quest['title'] as String? ?? 'Nhiệm vụ';
                  final questType = quest['type'] as String? ?? '';
                  final subjectHint = (questType == 'complete_daily_lesson' &&
                          recentSubjectName != null &&
                          recentSubjectName.isNotEmpty)
                      ? recentSubjectName
                      : null;
                  final status = questWrapper['status'] as String? ?? 'active';
                  final progressNum = (questWrapper['progress'] as num?) ?? 0;
                  final targetNum = (questWrapper['target'] as num?) ??
                      (requirements['target'] as num?) ??
                      1;

                  final progress = progressNum.toDouble();
                  final target =
                      targetNum.toDouble().clamp(1.0, double.infinity);
                  final percent = (progress / target).clamp(0.0, 1.0);
                  final isCompleted = status == 'completed';
                  final isClaimed = status == 'claimed';

                  final xpReward = (rewards['xp'] as num?)?.toInt();
                  final coinReward = (rewards['coin'] as num?)?.toInt();

                  final canClaim = isCompleted && !isClaimed;

                  return _buildDailyQuestTile(
                    questWrapper: questWrapper,
                    title: title,
                    questType: questType,
                    subjectHint: subjectHint,
                    isCompleted: isCompleted,
                    isClaimed: isClaimed,
                    canClaim: canClaim,
                    percent: percent,
                    progressNum: progressNum,
                    targetNum: targetNum,
                    xpReward: xpReward,
                    coinReward: coinReward,
                    isLast: index == quests.length - 1,
                  );
                }).toList(),
              ),
            ),
          if (completedUnclaimed.isNotEmpty) ...[
            if (quests.isNotEmpty) const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: sem.cardOverlay.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: sem.gold.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.redeem_rounded,
                      size: 20,
                      color: sem.gold.withValues(alpha: 0.95),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Phần thưởng khi xong',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: sem.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: sem.gold.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: sem.gold.withValues(alpha: 0.28),
                            ),
                          ),
                          child: Text(
                            CurrencyLabels.rewardShort(sumCoins.toInt()),
                            style: AppTextStyles.caption.copyWith(
                              color: sem.gold,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: sem.gold.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: sem.gold.withValues(alpha: 0.28),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.bolt_rounded,
                                size: 14,
                                color: sem.gold,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '+${sumXP.toInt()} XP',
                                style: AppTextStyles.caption.copyWith(
                                  color: sem.gold,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDailyQuestTile({
    required Map<String, dynamic> questWrapper,
    required String title,
    required String questType,
    required String? subjectHint,
    required bool isCompleted,
    required bool isClaimed,
    required bool canClaim,
    required double percent,
    required num progressNum,
    required num targetNum,
    required int? xpReward,
    required int? coinReward,
    required bool isLast,
  }) {
    final sem = context.colors;
    final brandHi = Color.lerp(sem.brand, sem.textOnBrand, 0.55)!;
    final participationId = questWrapper['id'] as String?;

    final Color bg;
    final Color borderColor;
    final List<BoxShadow>? cardShadow;

    if (isClaimed) {
      bg = sem.cardMuted;
      borderColor = sem.border;
      cardShadow = null;
    } else if (canClaim) {
      bg = sem.success.withValues(alpha: 0.08);
      borderColor = sem.success.withValues(alpha: 0.38);
      cardShadow = [
        BoxShadow(
          color: sem.success.withValues(alpha: 0.06),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
    } else {
      bg = sem.card;
      borderColor = sem.border;
      cardShadow = [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];
    }

    void onCardTap() {
      unawaited(
        _handleDailyQuestCta(
          canClaim: canClaim,
          isClaimed: isClaimed,
          questParticipationId: participationId,
          questType: questType,
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isClaimed ? null : onCardTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: bg,
              border: Border.all(color: borderColor),
              boxShadow: cardShadow,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted || isClaimed
                              ? sem.success.withValues(alpha: 0.14)
                              : sem.card.withValues(alpha: 0.8),
                          border: Border.all(
                            color: isCompleted || isClaimed
                                ? sem.success.withValues(alpha: 0.45)
                                : const Color(0x552D363D),
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            isClaimed
                                ? Icons.verified_rounded
                                : isCompleted
                                    ? Icons.check_rounded
                                    : Icons.radio_button_unchecked_rounded,
                            size: 15,
                            color: isCompleted || isClaimed
                                ? sem.success.withValues(alpha: 0.85)
                                : sem.textTertiary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (subjectHint != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: brandHi.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: brandHi.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Text(
                                  subjectHint,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.caption.copyWith(
                                    color: brandHi,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                            ],
                            Text(
                              title,
                              style: AppTextStyles.bodyBold.copyWith(
                                fontSize: 14,
                                height: 1.35,
                                color: isClaimed
                                    ? sem.textTertiary
                                    : (isCompleted || canClaim
                                        ? sem.textPrimary
                                        : sem.textSecondary),
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (xpReward != null || coinReward != null) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  if (coinReward != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: sem.gold.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color:
                                              sem.gold.withValues(alpha: 0.28),
                                        ),
                                      ),
                                      child: Text(
                                        CurrencyLabels.rewardShort(
                                          coinReward.toInt(),
                                        ),
                                        style: AppTextStyles.caption.copyWith(
                                          color: sem.gold,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  if (xpReward != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: sem.gold.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color:
                                              sem.gold.withValues(alpha: 0.28),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.bolt_rounded,
                                            size: 13,
                                            color: sem.gold,
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            '+${xpReward.toInt()} XP',
                                            style:
                                                AppTextStyles.caption.copyWith(
                                              color: sem.gold,
                                              fontSize: 11,
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
                      const SizedBox(width: 8),
                      _buildDailyQuestCtaPill(
                        canClaim: canClaim,
                        isClaimed: isClaimed,
                      ),
                    ],
                  ),
                  if (!isCompleted && !isClaimed) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: percent,
                        minHeight: 8,
                        backgroundColor: sem.cardMuted,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(sem.gold),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      targetNum.toInt() >= 100
                          ? '${progressNum.toInt()} / ${targetNum.toInt()} hoàn thành'
                          : '${progressNum.toInt()} / ${targetNum.toInt()}',
                      style: AppTextStyles.caption.copyWith(
                        color: sem.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestMilestoneRow({required int completedCount}) {
    final sem = context.colors;
    return Row(
      children: List.generate(4, (index) {
        final unlocked = completedCount > index;
        return Expanded(
          child: Row(
            children: [
              if (index > 0)
                Expanded(
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: unlocked ? sem.brand : sem.border,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: unlocked ? sem.brand : sem.cardMuted,
                  border: Border.all(
                    color: unlocked ? sem.brand : sem.border,
                  ),
                ),
                child: Icon(
                  Icons.card_giftcard_rounded,
                  size: 14,
                  color: unlocked ? sem.textOnBrand : sem.textTertiary,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildDailyQuestCtaPill({
    required bool canClaim,
    required bool isClaimed,
  }) {
    final sem = context.colors;
    final brandHi = Color.lerp(sem.brand, sem.textOnBrand, 0.55)!;
    final label = _questPrimaryCtaLabel(canClaim, isClaimed);
    if (isClaimed) {
      return Container(
        height: 34,
        constraints: const BoxConstraints(minWidth: 72),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: sem.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0x552D363D)),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 11,
              color: sem.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (canClaim) {
      return Container(
        height: 34,
        constraints: const BoxConstraints(minWidth: 72),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: sem.success.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: sem.success.withValues(alpha: 0.18),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 11,
              color: Colors.black87,
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return Container(
      height: 34,
      constraints: const BoxConstraints(minWidth: 72),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            brandHi.withValues(alpha: 0.75),
            sem.brand.withValues(alpha: 0.65),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: sem.brand.withValues(alpha: 0.14),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 11,
            color: sem.textOnBrand.withValues(alpha: 0.95),
            letterSpacing: 0.35,
          ),
          textAlign: TextAlign.center,
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
    final sem = context.colors;
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
              icon: Icon(Icons.search, color: sem.textSecondary),
              tooltip: 'Tìm môn học',
              onPressed: () => _showSubjectSearchDialog(subjects),
            ),
            if (_isContributor) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => context.push('/library/my-contributions'),
                child: Row(
                  children: [
                    Icon(Icons.list_alt, size: 16, color: sem.info),
                    const SizedBox(width: 4),
                    Text(
                      'Đóng góp',
                      style: AppTextStyles.caption.copyWith(color: sem.info),
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
    final sem = context.colors;
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 0,
        color: sem.info.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: sem.info.withValues(alpha: 0.3),
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            context.push('/library');
          },
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: sem.info.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.add, size: 28, color: sem.info),
                ),
                const SizedBox(height: 8),
                Text(
                  'Thêm môn học',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: sem.info,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Đóng góp mới',
                  style: AppTextStyles.caption.copyWith(
                    color: sem.info.withValues(alpha: 0.7),
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
