import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:edtech_mobile/core/constants/currency_labels.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/core/widgets/app_bar_leading_back_home.dart';
import 'package:edtech_mobile/core/widgets/bottom_nav_bar.dart';
import 'package:edtech_mobile/core/widgets/error_widget.dart';
import 'package:edtech_mobile/features/chat/widgets/chat_bubble.dart';
import 'package:edtech_mobile/theme/theme.dart';

class DailyQuestsScreen extends StatefulWidget {
  const DailyQuestsScreen({super.key});

  @override
  State<DailyQuestsScreen> createState() => _DailyQuestsScreenState();
}

class _DailyQuestsScreenState extends State<DailyQuestsScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic>? _dailyQuests;
  List<dynamic>? _questHistory;
  /// Cùng nguồn dashboard — dùng `recentSubject` cho nhiệm vụ `complete_daily_lesson`.
  Map<String, dynamic>? _continueLearning;
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;
  bool _isClaiming = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadQuests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadQuests() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);

      final results = await Future.wait([
        apiService.getDashboard(),
        apiService.getQuestHistory(),
      ]);
      final dash = results[0] as Map<String, dynamic>;
      final questHistory = results[1] as List<dynamic>;

      setState(() {
        _dailyQuests = dash['dailyQuests'] as List<dynamic>?;
        _continueLearning = dash['continueLearning'] as Map<String, dynamic>?;
        _questHistory = questHistory;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _claimQuest(String userQuestId) async {
    if (_isClaiming) return;

    setState(() => _isClaiming = true);

    try {
      HapticFeedback.heavyImpact();
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.claimQuest(userQuestId);

      await _loadQuests();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.celebration, color: Colors.white),
                SizedBox(width: 8),
                Text('Đã nhận phần thưởng!'),
              ],
            ),
            backgroundColor: AppColors.successNeon,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: AppColors.errorNeon,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isClaiming = false);
      }
    }
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
        context.push('/library');
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
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.orangeNeon.withValues(alpha: 0.48),
                    AppColors.orangeNeon.withValues(alpha: 0.08),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.orangeNeon.withValues(alpha: 0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.task_alt_rounded,
                color: AppColors.orangeNeon,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Nhiệm vụ hằng ngày',
                style: AppTextStyles.h4.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.orangeNeon.withValues(alpha: 0.14),
                    AppColors.bgSecondary,
                  ],
                ),
                border: Border.all(
                  color: AppColors.orangeNeon.withValues(alpha: 0.28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    offset: const Offset(0, 5),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                padding: const EdgeInsets.all(5),
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.purpleNeon.withValues(alpha: 0.45),
                      AppColors.purpleNeon.withValues(alpha: 0.14),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.purpleNeon.withValues(alpha: 0.28),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textTertiary,
                labelStyle: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: AppTextStyles.labelMedium,
                tabs: const [
                  Tab(
                    height: 44,
                    text: 'Hôm nay',
                    icon: Icon(Icons.today_rounded, size: 20),
                  ),
                  Tab(
                    height: 44,
                    text: 'Lịch sử',
                    icon: Icon(Icons.history_rounded, size: 20),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            icon: Icon(
              Icons.refresh_rounded,
              color: AppColors.primaryLight.withValues(alpha: 0.95),
            ),
            onPressed: _loadQuests,
          ),
        ],
      ),
      body: Stack(
        children: [
          _isLoading
              ? _buildLoadingState()
              : _error != null
                  ? AppErrorWidget(message: _error!, onRetry: _loadQuests)
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildDailyQuestsTab(),
                        _buildHistoryTab(),
                      ],
                    ),
          const FloatingChatBubble(),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primaryLight),
          const SizedBox(height: 16),
          Text('Đang tải nhiệm vụ…',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildDailyQuestsTab() {
    if (_dailyQuests == null || _dailyQuests!.isEmpty) {
      return const _DailyQuestsEmptyGamified();
    }

    return RefreshIndicator(
      onRefresh: _loadQuests,
      color: AppColors.purpleNeon,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _dailyQuests!.length,
        itemBuilder: (context, index) {
          final questData = _dailyQuests![index] as Map<String, dynamic>;
          final quest =
              questData['quest'] as Map<String, dynamic>? ?? const {};
          final questType = quest['type'] as String? ?? '';
          final recentSubject =
              _continueLearning?['recentSubject'] as Map<String, dynamic>?;
          final recentSubjectName = recentSubject?['name'] as String?;
          return StaggeredListItem(
            index: index,
            child: _QuestCard(
              questData: questData,
              onClaim: () => _claimQuest(questData['id'] as String),
              isClaiming: _isClaiming,
              recentSubjectName: recentSubjectName,
              onGo: () {
                HapticFeedback.lightImpact();
                _navigateForQuestType(questType);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_questHistory == null || _questHistory!.isEmpty) {
      return const _QuestHistoryEmptyGamified();
    }

    return RefreshIndicator(
      onRefresh: _loadQuests,
      color: AppColors.purpleNeon,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _questHistory!.length,
        itemBuilder: (context, index) {
          final questData = _questHistory![index] as Map<String, dynamic>;
          return _QuestHistoryCard(questData: questData);
        },
      ),
    );
  }
}

class _QuestCard extends StatelessWidget {
  final Map<String, dynamic> questData;
  final VoidCallback onClaim;
  final bool isClaiming;
  final String? recentSubjectName;
  final VoidCallback onGo;

  const _QuestCard({
    required this.questData,
    required this.onClaim,
    required this.isClaiming,
    required this.onGo,
    this.recentSubjectName,
  });

  @override
  Widget build(BuildContext context) {
    final quest = questData['quest'] as Map<String, dynamic>;
    final progress = questData['progress'] as int? ?? 0;
    final target =
        questData['target'] as int? ?? quest['requirements']?['target'] ?? 1;
    final status = questData['status'] as String? ?? 'active';
    final isCompleted = progress >= target;
    final canClaim = isCompleted && status == 'completed';
    final isClaimed = status == 'claimed';

    final questType = quest['type'] as String? ?? '';
    final subjectHint = (questType == 'complete_daily_lesson' &&
            (recentSubjectName?.isNotEmpty ?? false))
        ? recentSubjectName
        : null;
    final icon = _getQuestIcon(questType);
    final color = _getQuestColor(questType);
    final progressPercent = (progress / target).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: isClaimed ? 0.1 : (canClaim ? 0.14 : 0.06)),
            AppColors.bgSecondary,
          ],
        ),
        border: Border.all(
          color: isClaimed
              ? AppColors.successNeon.withValues(alpha: 0.52)
              : canClaim
                  ? color.withValues(alpha: 0.52)
                  : color.withValues(alpha: 0.2),
          width: canClaim || isClaimed ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: canClaim
                ? color.withValues(alpha: 0.32)
                : Colors.black.withValues(alpha: 0.3),
            blurRadius: canClaim ? 14 : 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Quest icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: RadialGradient(
                      center: const Alignment(-0.35, -0.4),
                      radius: 1.05,
                      colors: [
                        color.withValues(alpha: 0.55),
                        color.withValues(alpha: 0.18),
                        AppColors.bgTertiary,
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.32),
                        offset: const Offset(0, 3),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: color == AppColors.textSecondary
                        ? AppColors.primaryLight
                        : Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (subjectHint != null) ...[
                        Text(
                          subjectHint,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primaryLight,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        quest['title'] ?? 'Nhiệm vụ',
                        style: AppTextStyles.labelLarge
                            .copyWith(color: AppColors.textPrimary),
                      ),
                      if (quest['description'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          quest['description'] ?? '',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isClaimed)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.successNeon.withValues(alpha: 0.45),
                          AppColors.successNeon.withValues(alpha: 0.12),
                        ],
                      ),
                      border: Border.all(
                        color: AppColors.successNeon.withValues(alpha: 0.45),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.successNeon.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            // Progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$progress / $target',
                      style: AppTextStyles.labelMedium
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    Text(
                      '${(progressPercent * 100).round()}%',
                      style: AppTextStyles.labelMedium
                          .copyWith(color: color, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 12,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: Colors.black.withValues(alpha: 0.38),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(1.5),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ColoredBox(color: AppColors.bgTertiary),
                              AnimatedProgressBox(
                                widthFactor: progressPercent,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                                child: Container(
                                  height: 9,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        color.withValues(alpha: 0.95),
                                        color.withValues(alpha: 0.65),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: color.withValues(alpha: 0.45),
                                        blurRadius: 6,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
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
              ],
            ),
            const SizedBox(height: 16),
            // Rewards
            if (quest['rewards'] != null) ...[
              _buildRewards(quest['rewards'] as Map<String, dynamic>),
              const SizedBox(height: 16),
            ],
            // Nhận thưởng / ĐẾN / đã nhận — đồng bộ dashboard
            if (canClaim)
              GamingButton(
                text: 'Nhận phần thưởng',
                onPressed: isClaiming ? null : onClaim,
                isLoading: isClaiming,
                gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.8)]),
                glowColor: color,
                icon: Icons.card_giftcard_rounded,
              )
            else if (isClaimed)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.successNeon.withValues(alpha: 0.22),
                      AppColors.successNeon.withValues(alpha: 0.06),
                    ],
                  ),
                  border: Border.all(
                    color: AppColors.successNeon.withValues(alpha: 0.42),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.successNeon.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.successNeon,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Đã nhận phần thưởng',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.successNeon,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              )
            else
              Align(
                alignment: Alignment.centerRight,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onGo,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.purpleNeon.withValues(alpha: 0.35),
                            AppColors.purpleNeon.withValues(alpha: 0.12),
                          ],
                        ),
                        border: Border.all(
                          color: AppColors.purpleNeon.withValues(alpha: 0.45),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.28),
                            offset: const Offset(0, 3),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Text(
                        'ĐẾN',
                        style: AppTextStyles.labelSmall.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: Colors.white,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewards(Map<String, dynamic> rewards) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.xpGold.withValues(alpha: 0.22),
            AppColors.xpGold.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(
          color: AppColors.xpGold.withValues(alpha: 0.38),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.xpGold.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded,
              color: AppColors.xpGold, size: 20),
          const SizedBox(width: 10),
          Text('Phần thưởng:',
              style:
                  AppTextStyles.labelMedium.copyWith(color: AppColors.xpGold)),
          const Spacer(),
          if (rewards['xp'] != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.xpGold.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star_rounded,
                      size: 14, color: AppColors.xpGold),
                  const SizedBox(width: 4),
                  Text(
                    '+${rewards['xp']} XP',
                    style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.xpGold, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
          if (rewards['coin'] != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.coinGold.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const GtuCoinIcon(size: 14),
                  const SizedBox(width: 4),
                  Text(
                    CurrencyLabels.rewardShort(
                        (rewards['coin'] as num).toInt()),
                    style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.coinGold, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getQuestIcon(String type) {
    switch (type) {
      case 'complete_items':
        return Icons.checklist_rounded;
      case 'maintain_streak':
        return Icons.local_fire_department_rounded;
      case 'earn_coins':
        return Icons.monetization_on_rounded;
      case 'earn_xp':
        return Icons.star_rounded;
      case 'complete_node':
        return Icons.book_rounded;
      case 'complete_daily_lesson':
        return Icons.calendar_today_rounded;
      default:
        return Icons.task_alt_rounded;
    }
  }

  Color _getQuestColor(String type) {
    switch (type) {
      case 'complete_items':
        return AppColors.primaryLight;
      case 'maintain_streak':
        return AppColors.streakOrange;
      case 'earn_coins':
        return AppColors.coinGold;
      case 'earn_xp':
        return AppColors.purpleNeon;
      case 'complete_node':
        return AppColors.successNeon;
      case 'complete_daily_lesson':
        return AppColors.infoNeon;
      default:
        return AppColors.textSecondary;
    }
  }
}

class _QuestHistoryCard extends StatelessWidget {
  final Map<String, dynamic> questData;

  const _QuestHistoryCard({required this.questData});

  @override
  Widget build(BuildContext context) {
    final quest = questData['quest'] as Map<String, dynamic>;
    final status = questData['status'] as String? ?? 'active';
    final completedAt = questData['completedAt'] as String?;
    final claimedAt = questData['claimedAt'] as String?;

    final questType = quest['type'] as String? ?? '';
    final icon = _getQuestIcon(questType);
    final color = _getQuestColor(questType);
    final isClaimed = status == 'claimed';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.1),
            AppColors.bgSecondary,
          ],
        ),
        border: Border.all(
          color: isClaimed
              ? AppColors.successNeon.withValues(alpha: 0.4)
              : color.withValues(alpha: 0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            offset: const Offset(0, 4),
            blurRadius: 9,
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: 0.5),
                color.withValues(alpha: 0.12),
              ],
            ),
            border: Border.all(
              color: color.withValues(alpha: 0.35),
            ),
          ),
          child: Icon(
            icon,
            color: color == AppColors.textSecondary
                ? AppColors.primaryLight
                : Colors.white,
            size: 22,
          ),
        ),
        title: Text(
          quest['title'] ?? 'Nhiệm vụ',
          style:
              AppTextStyles.labelMedium.copyWith(color: AppColors.textPrimary),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (completedAt != null)
              Text(
                'Hoàn thành: ${_formatDate(completedAt)}',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textTertiary),
              ),
            if (claimedAt != null)
              Text(
                'Nhận thưởng: ${_formatDate(claimedAt)}',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.successNeon),
              ),
          ],
        ),
        trailing: isClaimed
            ? const Icon(Icons.check_circle_rounded,
                color: AppColors.successNeon)
            : null,
      ),
    );
  }

  IconData _getQuestIcon(String type) {
    switch (type) {
      case 'complete_items':
        return Icons.checklist_rounded;
      case 'maintain_streak':
        return Icons.local_fire_department_rounded;
      case 'earn_coins':
        return Icons.monetization_on_rounded;
      case 'earn_xp':
        return Icons.star_rounded;
      case 'complete_node':
        return Icons.book_rounded;
      case 'complete_daily_lesson':
        return Icons.calendar_today_rounded;
      default:
        return Icons.task_alt_rounded;
    }
  }

  Color _getQuestColor(String type) {
    switch (type) {
      case 'complete_items':
        return AppColors.primaryLight;
      case 'maintain_streak':
        return AppColors.streakOrange;
      case 'earn_coins':
        return AppColors.coinGold;
      case 'earn_xp':
        return AppColors.purpleNeon;
      case 'complete_node':
        return AppColors.successNeon;
      case 'complete_daily_lesson':
        return AppColors.infoNeon;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}

class _DailyQuestsEmptyGamified extends StatelessWidget {
  const _DailyQuestsEmptyGamified();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.orangeNeon.withValues(alpha: 0.4),
                    AppColors.bgSecondary,
                  ],
                ),
                border: Border.all(
                  color: AppColors.purpleNeon.withValues(alpha: 0.32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                Icons.task_alt_rounded,
                size: 52,
                color: AppColors.orangeNeon.withValues(alpha: 0.95),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Chưa có quest nào hôm nay',
              textAlign: TextAlign.center,
              style: AppTextStyles.h4.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Quests sẽ được tạo tự động mỗi ngày.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestHistoryEmptyGamified extends StatelessWidget {
  const _QuestHistoryEmptyGamified();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.purpleNeon.withValues(alpha: 0.35),
                    AppColors.bgSecondary,
                  ],
                ),
                border: Border.all(
                  color: AppColors.purpleNeon.withValues(alpha: 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(
                Icons.history_rounded,
                size: 48,
                color: AppColors.primaryLight.withValues(alpha: 0.95),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Chưa có lịch sử nhiệm vụ',
              textAlign: TextAlign.center,
              style: AppTextStyles.h4.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hoàn thành và nhận thưởng để thấy lịch sử tại đây.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
