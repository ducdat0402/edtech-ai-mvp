import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/theme/colors.dart';
import 'package:edtech_mobile/theme/text_styles.dart';

class AllLessonsScreen extends StatefulWidget {
  final String subjectId;

  const AllLessonsScreen({
    super.key,
    required this.subjectId,
  });

  @override
  State<AllLessonsScreen> createState() => _AllLessonsScreenState();
}

class _AllLessonsScreenState extends State<AllLessonsScreen>
    with WidgetsBindingObserver {
  Map<String, dynamic>? _introData;
  bool _isLoading = true;
  String? _error;
  String _userRole = 'user';

  // Hierarchy data parsed from intro
  List<Map<String, dynamic>> _domains = [];

  // Track expanded state
  final Set<String> _expandedDomains = {};
  final Set<String> _expandedTopics = {};

  bool get _isContributor => _userRole == 'contributor' || _userRole == 'admin';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);

      final results = await Future.wait([
        apiService.getSubjectIntro(widget.subjectId),
        apiService.getUserProfile(),
      ]);

      final introData = results[0];
      final profile = results[1];
      _userRole = profile['role'] as String? ?? 'user';

      // Parse hierarchy from knowledge graph
      final graph = introData['knowledgeGraph'] as Map<String, dynamic>;
      final graphNodes = graph['nodes'] as List;
      final domains = _parseHierarchy(graphNodes);

      if (mounted) {
        setState(() {
          _introData = introData;
          _domains = domains;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _parseHierarchy(List<dynamic> graphNodes) {
    final domains = <Map<String, dynamic>>[];
    final topicsByDomain = <String, List<Map<String, dynamic>>>{};

    for (final node in graphNodes) {
      final n = node as Map<String, dynamic>;
      final nodeType = n['nodeType'] as String? ?? '';
      if (nodeType == 'domain') {
        domains.add(Map<String, dynamic>.from(n));
      } else if (nodeType == 'topic') {
        final parentId = n['parentId'] as String? ?? '';
        topicsByDomain.putIfAbsent(parentId, () => []);
        topicsByDomain[parentId]!.add(Map<String, dynamic>.from(n));
      }
    }

    for (final domain in domains) {
      final domainNodeId = domain['id'] as String;
      final topics = topicsByDomain[domainNodeId] ?? [];
      // Sort topics by order
      topics.sort((a, b) =>
          (a['order'] as int? ?? 0).compareTo(b['order'] as int? ?? 0));
      domain['_topics'] = topics;
    }

    domains.sort(
        (a, b) => (a['order'] as int? ?? 0).compareTo(b['order'] as int? ?? 0));

    return domains;
  }

  // Calculate overall stats
  Map<String, int> get _stats {
    int total = 0;
    int completed = 0;
    for (final domain in _domains) {
      final topics = domain['_topics'] as List<Map<String, dynamic>>;
      for (final topic in topics) {
        total += (topic['totalLessons'] as int? ?? 0);
        completed += (topic['completedLessons'] as int? ?? 0);
      }
    }
    return {'total': total, 'completed': completed};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        title: Text(
          _introData?['subject']?['name'] ?? 'Lộ trình tổng quát',
          style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.cyanNeon),
                  SizedBox(height: 16),
                  Text('Đang tải...',
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Lỗi: $_error', style: AppTextStyles.bodyMedium),
                      const SizedBox(height: 16),
                      ElevatedButton(
                          onPressed: _loadData, child: const Text('Thử lại')),
                    ],
                  ),
                )
              : _domains.isEmpty
                  ? const Center(
                      child: Text('Chưa có nội dung',
                          style: TextStyle(color: AppColors.textSecondary)),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildHeader(),
                          if (_isContributor) _buildContributorNotice(),
                          ..._domains.map((d) => _buildDomainTile(d)),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
    );
  }

  // =====================
  // HEADER
  // =====================
  Widget _buildHeader() {
    final stats = _stats;
    final total = stats['total']!;
    final completed = stats['completed']!;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.purpleNeon.withOpacity(0.2),
            AppColors.cyanNeon.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.purpleNeon.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.route_rounded,
                  color: AppColors.purpleNeon, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Lộ trình tổng quát',
                        style: AppTextStyles.h4
                            .copyWith(color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text('Học tuần tự từ cơ bản đến nâng cao',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatBadge(Icons.check_circle, AppColors.successNeon,
                  '$completed', 'Hoàn thành'),
              const SizedBox(width: 12),
              _buildStatBadge(Icons.folder, AppColors.cyanNeon,
                  '${_domains.length}', 'Chương'),
              const SizedBox(width: 12),
              _buildStatBadge(
                  Icons.menu_book, AppColors.purpleNeon, '$total', 'Tổng bài'),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: total > 0 ? completed / total : 0,
              backgroundColor: AppColors.bgSecondary,
              valueColor: const AlwaysStoppedAnimation(AppColors.successNeon),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(
      IconData icon, Color color, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 4),
                Text(value,
                    style: AppTextStyles.labelLarge.copyWith(color: color)),
              ],
            ),
            const SizedBox(height: 2),
            Text(label,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textTertiary),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildContributorNotice() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [Colors.amber.shade50, Colors.orange.shade50]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.amber.shade100, shape: BoxShape.circle),
            child: Icon(Icons.info_outline_rounded,
                color: Colors.amber.shade800, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bạn đang ở chế độ Contributor',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900)),
                const SizedBox(height: 4),
                Text(
                  'Muốn nhận phần thưởng XP và Coin, hãy chuyển sang Learner mode để học và làm bài test nhé!',
                  style: TextStyle(
                      fontSize: 12, color: Colors.amber.shade800, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =====================
  // DOMAIN TILE (Level 1)
  // =====================
  Widget _buildDomainTile(Map<String, dynamic> domain) {
    final domainId = domain['id'] as String;
    final title = domain['title'] as String? ?? '';
    final isExpanded = _expandedDomains.contains(domainId);
    final isCompleted = domain['isCompleted'] as bool? ?? false;
    final topics = domain['_topics'] as List<Map<String, dynamic>>;

    int domainTotal = 0;
    int domainCompleted = 0;
    for (final t in topics) {
      domainTotal += (t['totalLessons'] as int? ?? 0);
      domainCompleted += (t['completedLessons'] as int? ?? 0);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.bgSecondary,
        border: Border.all(
          color: isCompleted
              ? AppColors.successNeon.withOpacity(0.4)
              : isExpanded
                  ? AppColors.purpleNeon.withOpacity(0.4)
                  : AppColors.borderPrimary,
          width: isCompleted || isExpanded ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                if (isExpanded) {
                  _expandedDomains.remove(domainId);
                } else {
                  _expandedDomains.add(domainId);
                }
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isCompleted
                            ? [AppColors.successNeon, const Color(0xFF2DD4BF)]
                            : [AppColors.purpleNeon, AppColors.cyanNeon],
                      ),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      isCompleted ? Icons.check_rounded : Icons.folder_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Title + stats
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: AppTextStyles.labelLarge.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '${topics.length} chủ đề',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.textSecondary),
                            ),
                            if (domainTotal > 0) ...[
                              const Text('  ·  ',
                                  style: TextStyle(
                                      color: AppColors.textTertiary,
                                      fontSize: 12)),
                              Text(
                                '$domainCompleted/$domainTotal bài',
                                style: AppTextStyles.caption.copyWith(
                                  color: isCompleted
                                      ? AppColors.successNeon
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (domainTotal > 0) ...[
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: domainTotal > 0
                                  ? domainCompleted / domainTotal
                                  : 0,
                              backgroundColor: AppColors.borderPrimary,
                              valueColor: AlwaysStoppedAnimation(
                                isCompleted
                                    ? AppColors.successNeon
                                    : AppColors.purpleNeon,
                              ),
                              minHeight: 4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down,
                        color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
          ),
          // Topics
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                const Divider(height: 1, color: AppColors.borderPrimary),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Column(
                      children: topics.map((t) => _buildTopicTile(t)).toList()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =====================
  // TOPIC TILE (Level 2)
  // =====================
  Widget _buildTopicTile(Map<String, dynamic> topic) {
    final topicId = topic['id'] as String;
    final title = topic['title'] as String? ?? '';
    final isExpanded = _expandedTopics.contains(topicId);
    final isCompleted = topic['isCompleted'] as bool? ?? false;
    final totalLessons = topic['totalLessons'] as int? ?? 0;
    final completedLessons = topic['completedLessons'] as int? ?? 0;
    final totalXp = topic['totalXp'] as int? ?? 0;
    final totalCoins = topic['totalCoins'] as int? ?? 0;
    final learningNodes =
        (topic['learningNodes'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isCompleted
            ? AppColors.successNeon.withOpacity(0.06)
            : isExpanded
                ? AppColors.cyanNeon.withOpacity(0.04)
                : AppColors.bgPrimary.withOpacity(0.5),
        border: Border.all(
          color: isCompleted
              ? AppColors.successNeon.withOpacity(0.3)
              : isExpanded
                  ? AppColors.cyanNeon.withOpacity(0.3)
                  : AppColors.borderPrimary.withOpacity(0.5),
        ),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                if (isExpanded) {
                  _expandedTopics.remove(topicId);
                } else {
                  _expandedTopics.add(topicId);
                }
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppColors.successNeon.withOpacity(0.15)
                          : AppColors.cyanNeon.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isCompleted ? Icons.check : Icons.menu_book,
                      color: isCompleted
                          ? AppColors.successNeon
                          : AppColors.cyanNeon,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: AppTextStyles.labelLarge.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text(
                              isCompleted
                                  ? 'Đã hoàn thành'
                                  : '$completedLessons/$totalLessons bài',
                              style: AppTextStyles.caption.copyWith(
                                color: isCompleted
                                    ? AppColors.successNeon
                                    : AppColors.textSecondary,
                              ),
                            ),
                            // Rewards
                            if (!isCompleted &&
                                (totalXp > 0 || totalCoins > 0)) ...[
                              const SizedBox(width: 8),
                              if (totalXp > 0) ...[
                                const Icon(Icons.auto_awesome,
                                    size: 11, color: AppColors.xpGold),
                                const SizedBox(width: 2),
                                Text('+$totalXp',
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.xpGold,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(width: 4),
                              ],
                              if (totalCoins > 0) ...[
                                const Icon(Icons.monetization_on,
                                    size: 11, color: AppColors.orangeNeon),
                                const SizedBox(width: 2),
                                Text('+$totalCoins',
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.orangeNeon,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ],
                            if (isCompleted) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.card_giftcard,
                                  size: 11, color: AppColors.textTertiary),
                              const SizedBox(width: 2),
                              Text('Đã nhận thưởng',
                                  style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textTertiary,
                                      fontSize: 10)),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down,
                        size: 20, color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
          ),
          // Lessons
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: learningNodes.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text('Chưa có bài học.',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textTertiary)),
                  )
                : Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    child: Column(
                      children: List.generate(
                        learningNodes.length,
                        (i) => _buildLessonTile(learningNodes[i], i),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ========================
  // LESSON TILE (Level 3) - with diamond lock status
  // ========================
  Widget _buildLessonTile(Map<String, dynamic> lesson, int index) {
    final nodeId = lesson['id'] as String;
    final title = lesson['title'] as String? ?? '';
    final isCompleted = lesson['isCompleted'] as bool? ?? false;
    final isLocked = lesson['isLocked'] as bool? ?? false;
    final xp = lesson['expReward'] as int? ?? 0;
    final coins = lesson['coinReward'] as int? ?? 0;

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        if (isCompleted) {
          _showCompletedDialog(title, nodeId);
        } else if (isLocked) {
          _showLockedLessonDialog(title);
        } else {
          context.push('/lessons/$nodeId/types',
              extra: {'title': title}).then((_) => _loadData());
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: isCompleted
              ? AppColors.successNeon.withOpacity(0.05)
              : isLocked
                  ? AppColors.bgPrimary.withOpacity(0.3)
                  : AppColors.bgSecondary,
          border: Border.all(
            color: isCompleted
                ? AppColors.successNeon.withOpacity(0.25)
                : isLocked
                    ? AppColors.borderPrimary.withOpacity(0.3)
                    : AppColors.borderPrimary.withOpacity(0.5),
          ),
        ),
        child: Opacity(
          opacity: isLocked ? 0.7 : 1.0,
          child: Row(
            children: [
              // Number / check / lock
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppColors.successNeon.withOpacity(0.15)
                      : isLocked
                          ? Colors.orange.withOpacity(0.1)
                          : AppColors.cyanNeon.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check,
                          color: AppColors.successNeon, size: 16)
                      : isLocked
                          ? Icon(Icons.lock,
                              color: Colors.orange.shade400, size: 14)
                          : Text(
                              '${index + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: AppColors.cyanNeon,
                              ),
                            ),
                ),
              ),
              const SizedBox(width: 10),
              // Title + reward
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: isLocked
                              ? AppColors.textTertiary
                              : isCompleted
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                          fontSize: 13,
                        )),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (isCompleted) ...[
                          const Icon(Icons.check_circle,
                              size: 12, color: AppColors.successNeon),
                          const SizedBox(width: 3),
                          Text('Hoàn thành',
                              style: AppTextStyles.caption.copyWith(
                                  color: AppColors.successNeon, fontSize: 10)),
                          const SizedBox(width: 6),
                          Text('· Nhấn xem lại',
                              style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textTertiary, fontSize: 10)),
                        ] else if (isLocked) ...[
                          Icon(Icons.lock,
                              size: 11, color: Colors.orange.shade400),
                          const SizedBox(width: 3),
                          Text('25 💎 để mở khóa',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange.shade600,
                                  fontWeight: FontWeight.w500)),
                        ] else ...[
                          if (xp > 0) ...[
                            const Icon(Icons.auto_awesome,
                                size: 12, color: AppColors.xpGold),
                            const SizedBox(width: 2),
                            Text('+$xp XP',
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.xpGold,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(width: 6),
                          ],
                          if (coins > 0) ...[
                            const Icon(Icons.monetization_on,
                                size: 12, color: AppColors.orangeNeon),
                            const SizedBox(width: 2),
                            Text('+$coins Xu',
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.orangeNeon,
                                    fontWeight: FontWeight.w600)),
                          ],
                          if (xp == 0 && coins == 0)
                            Text('Nhấn để chọn dạng bài',
                                style: AppTextStyles.caption.copyWith(
                                    color: AppColors.cyanNeon, fontSize: 10)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Trailing
              isLocked
                  ? Icon(Icons.lock_outline,
                      size: 18, color: Colors.orange.shade300)
                  : Icon(
                      isCompleted ? Icons.replay : Icons.play_circle_outline,
                      size: 20,
                      color: isCompleted
                          ? AppColors.textTertiary
                          : AppColors.cyanNeon,
                    ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLockedLessonDialog(String title) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔒', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(title,
                style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Bài học này cần mở khóa bằng kim cương.\nBạn có thể mở khóa từng topic, chương hoặc cả môn để tiết kiệm.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.borderPrimary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Đóng',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context
                          .push('/subjects/${widget.subjectId}/unlock')
                          .then((_) => _loadData());
                    },
                    icon: const Text('💎', style: TextStyle(fontSize: 16)),
                    label: const Text('Mở khóa bài học',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.purpleNeon,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.push('/payment');
              },
              child: const Text('Mua thêm kim cương',
                  style: TextStyle(color: AppColors.cyanNeon, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  void _showCompletedDialog(String title, String nodeId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle,
                color: AppColors.successNeon, size: 56),
            const SizedBox(height: 12),
            Text(title,
                style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Bạn đã hoàn thành bài học này và nhận phần thưởng rồi!',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.push('/lessons/$nodeId/types',
                          extra: {'title': title}).then((_) => _loadData());
                    },
                    icon: const Icon(Icons.replay, color: AppColors.cyanNeon),
                    label: const Text('Xem lại',
                        style: TextStyle(color: AppColors.cyanNeon)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: AppColors.cyanNeon.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.purpleNeon,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Đóng'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
