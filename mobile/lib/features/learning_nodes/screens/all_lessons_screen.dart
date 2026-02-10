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

class _AllLessonsScreenState extends State<AllLessonsScreen> {
  Map<String, dynamic>? _introData;
  List<Map<String, dynamic>> _allLessons = [];
  Set<String> _completedContentIds = {};
  bool _isLoading = true;
  String? _error;
  int _loadedNodes = 0;
  int _totalNodes = 0;
  String _userRole = 'user';

  bool get _isContributor => _userRole == 'contributor' || _userRole == 'admin';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      
      // Load subject intro and user profile in parallel
      final futures = await Future.wait([
        apiService.getSubjectIntro(widget.subjectId),
        apiService.getUserProfile(),
      ]);
      final introData = futures[0];
      final profile = futures[1];
      _userRole = profile['role'] as String? ?? 'user';
      
      setState(() {
        _introData = introData;
      });
      
      // Get learning nodes (these ARE the lessons now)
      final learningNodes = await apiService.getLearningNodesBySubject(widget.subjectId);
      debugPrint('📊 Found ${learningNodes.length} learning nodes');
      
      // Filter out orphan nodes (no topicId) - these are not visible in contributor mind map
      // and shouldn't appear in the learning path
      final validNodes = learningNodes.where((n) {
        final node = n as Map<String, dynamic>;
        final topicId = node['topicId'];
        return topicId != null && topicId.toString().isNotEmpty;
      }).toList();
      debugPrint('📊 Valid nodes (with topicId): ${validNodes.length} / ${learningNodes.length}');
      
      if (validNodes.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      // Sort nodes by order
      final sortedNodes = List<Map<String, dynamic>>.from(
        validNodes.map((n) => Map<String, dynamic>.from(n as Map)),
      );
      sortedNodes.sort((a, b) {
        final orderA = a['order'] as int? ?? 999;
        final orderB = b['order'] as int? ?? 999;
        return orderA.compareTo(orderB);
      });
      
      setState(() {
        _totalNodes = sortedNodes.length;
      });
      
      // Each learning node is a lesson
      final List<Map<String, dynamic>> allLessons = [];
      
      for (int i = 0; i < sortedNodes.length; i++) {
        final node = sortedNodes[i];
        final nodeId = node['id'] as String;
        
        // Check progress for this node
        bool isCompleted = false;
        try {
          final progress = await apiService.getNodeProgress(nodeId);
          isCompleted = progress['isCompleted'] == true;
        } catch (_) {}
        
        node['displayOrder'] = i + 1;
        node['isCompleted'] = isCompleted;
        _completedContentIds = {
          ..._completedContentIds,
          if (isCompleted) nodeId,
        };
        allLessons.add(node);
        
        setState(() {
          _loadedNodes = i + 1;
        });
      }
      
      debugPrint('✅ Total lessons loaded: ${allLessons.length}');
      
      setState(() {
        _allLessons = allLessons;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading data: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Check if a lesson is unlocked
  bool _isLessonUnlocked(int lessonIndex) {
    if (lessonIndex == 0) return true;
    
    final nodeId = _allLessons[lessonIndex]['id'] as String;
    if (_completedContentIds.contains(nodeId)) return true;
    
    final previousNodeId = _allLessons[lessonIndex - 1]['id'] as String;
    return _completedContentIds.contains(previousNodeId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        title: Text(
          _introData?['subject']?['name'] ?? 'Lộ trình tổng thể',
          style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _error != null
              ? _buildErrorState()
              : _allLessons.isEmpty
                  ? const Center(child: Text('Không có bài học nào', style: TextStyle(color: AppColors.textSecondary)))
                  : _buildLessonsList(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.cyanNeon),
          const SizedBox(height: 16),
          Text(
            'Đang tải bài học...',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          if (_totalNodes > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Node: $_loadedNodes / $_totalNodes',
              style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Lỗi: $_error', style: AppTextStyles.bodyMedium),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonsList() {
    // +1 for header, +1 for contributor banner if applicable
    final extraItems = 1 + (_isContributor ? 1 : 0);
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _allLessons.length + extraItems,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildHeader();
          }
          if (_isContributor && index == 1) {
            return _buildContributorRewardNotice();
          }
          final lessonIndex = index - extraItems;
          final isUnlocked = _isLessonUnlocked(lessonIndex);
          return _buildLessonCard(_allLessons[lessonIndex], lessonIndex + 1, isUnlocked);
        },
      ),
    );
  }

  Widget _buildContributorRewardNotice() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.shade50,
            Colors.orange.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.info_outline_rounded, color: Colors.amber.shade800, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bạn đang ở chế độ Contributor',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hoàn thành bài học ở đây chỉ để xem trước. Muốn nhận phần thưởng XP và Coin, hãy chuyển sang chế độ Learner để học và làm bài test nhé!',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.amber.shade800,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final completedCount = _allLessons.where((n) => n['isCompleted'] == true).length;
    final totalCount = _allLessons.length;
    
    // Count unlocked lessons
    int unlockedCount = 0;
    for (int i = 0; i < _allLessons.length; i++) {
      if (_isLessonUnlocked(i)) unlockedCount++;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.route_rounded, color: AppColors.purpleNeon, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lộ trình tổng quát',
                      style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Học tuần tự từ cơ bản đến nâng cao',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatBadge(
                icon: Icons.check_circle,
                color: AppColors.successNeon,
                value: '$completedCount',
                label: 'Hoàn thành',
              ),
              const SizedBox(width: 12),
              _buildStatBadge(
                icon: Icons.lock_open,
                color: AppColors.cyanNeon,
                value: '$unlockedCount',
                label: 'Đã mở khóa',
              ),
              const SizedBox(width: 12),
              _buildStatBadge(
                icon: Icons.menu_book,
                color: AppColors.purpleNeon,
                value: '$totalCount',
                label: 'Tổng bài học',
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: totalCount > 0 ? completedCount / totalCount : 0,
              backgroundColor: AppColors.bgSecondary,
              valueColor: AlwaysStoppedAnimation(AppColors.successNeon),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
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
                Text(
                  value,
                  style: AppTextStyles.labelLarge.copyWith(color: color),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonCard(Map<String, dynamic> lesson, int displayIndex, bool isUnlocked) {
    final isCompleted = lesson['isCompleted'] as bool? ?? false;
    final nodeId = lesson['id'] as String;
    final title = lesson['title'] as String? ?? 'Bài học $displayIndex';
    final nodeTitle = lesson['nodeTitle'] as String? ?? '';
    final expReward = lesson['expReward'] as int? ?? 0;
    final coinReward = lesson['coinReward'] as int? ?? 0;

    // Determine status colors and icons based on state
    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (isCompleted) {
      statusColor = AppColors.successNeon;
      statusIcon = Icons.check_circle;
      statusText = 'Đã hoàn thành';
    } else if (isUnlocked) {
      statusColor = AppColors.cyanNeon;
      statusIcon = Icons.play_circle_fill;
      statusText = 'Nhấn để chọn dạng bài';
    } else {
      statusColor = Colors.grey;
      statusIcon = Icons.lock;
      statusText = 'Hoàn thành bài trước để mở khóa';
    }

    return InkWell(
      onTap: isUnlocked
          ? () {
              HapticFeedback.lightImpact();
              _showLessonTypePicker(nodeId, title);
            }
          : () {
              HapticFeedback.mediumImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.lock, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Hoàn thành bài ${displayIndex - 1} để mở khóa bài này',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.orange.shade700,
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            },
      child: Opacity(
        opacity: isUnlocked ? 1.0 : 0.6,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left side: Number + Connecting line
            SizedBox(
              width: 48,
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: statusColor, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        '$displayIndex',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          statusColor.withOpacity(0.5),
                          AppColors.borderPrimary.withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Right side: Content card
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isUnlocked ? AppColors.bgSecondary : AppColors.bgSecondary.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCompleted
                        ? AppColors.successNeon.withOpacity(0.3)
                        : isUnlocked
                            ? AppColors.cyanNeon.withOpacity(0.3)
                            : Colors.grey.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (nodeTitle.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    nodeTitle,
                                    style: AppTextStyles.caption.copyWith(
                                      color: isUnlocked ? AppColors.purpleNeon : Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              Text(
                                title,
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: isUnlocked ? AppColors.textPrimary : Colors.grey,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Arrow or lock icon
                        Icon(
                          isUnlocked ? Icons.arrow_forward_ios : Icons.lock_outline,
                          size: 16,
                          color: isUnlocked ? AppColors.textSecondary : Colors.grey,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Rewards row
                    Row(
                      children: [
                        // Status
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            statusText,
                            style: AppTextStyles.caption.copyWith(color: statusColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // XP reward
                        if (expReward > 0) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? AppColors.successNeon.withOpacity(0.1)
                                  : AppColors.xpGold.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  size: 12,
                                  color: isCompleted ? AppColors.successNeon : AppColors.xpGold,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '+$expReward XP',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isCompleted ? AppColors.successNeon : AppColors.xpGold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        // Coin reward
                        if (coinReward > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? AppColors.successNeon.withOpacity(0.1)
                                  : AppColors.orangeNeon.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.monetization_on,
                                  size: 12,
                                  color: isCompleted ? AppColors.successNeon : AppColors.orangeNeon,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '+$coinReward',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isCompleted ? AppColors.successNeon : AppColors.orangeNeon,
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
        ),
      ),
    );
  }

  // ==================
  // Lesson Type Picker
  // ==================

  static const _allLessonTypes = [
    {'key': 'image_quiz', 'label': 'Hình ảnh (Quiz)', 'icon': Icons.quiz_outlined, 'color': Color(0xFFE879F9)},
    {'key': 'image_gallery', 'label': 'Hình ảnh (Thư viện)', 'icon': Icons.photo_library_outlined, 'color': Color(0xFF38BDF8)},
    {'key': 'video', 'label': 'Video', 'icon': Icons.play_circle_outline, 'color': Color(0xFFFB923C)},
    {'key': 'text', 'label': 'Văn bản', 'icon': Icons.article_outlined, 'color': Color(0xFF34D399)},
  ];

  void _showLessonTypePicker(String nodeId, String lessonTitle) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _LessonTypePickerSheet(
        nodeId: nodeId,
        lessonTitle: lessonTitle,
        allLessonTypes: _allLessonTypes,
        isContributor: _isContributor,
      ),
    ).then((_) {
      // Reload data when returning (in case user completed something)
      _loadData();
    });
  }
}

/// Bottom sheet for picking lesson type
class _LessonTypePickerSheet extends StatefulWidget {
  final String nodeId;
  final String lessonTitle;
  final List<Map<String, dynamic>> allLessonTypes;
  final bool isContributor;

  const _LessonTypePickerSheet({
    required this.nodeId,
    required this.lessonTitle,
    required this.allLessonTypes,
    this.isContributor = false,
  });

  @override
  State<_LessonTypePickerSheet> createState() => _LessonTypePickerSheetState();
}

class _LessonTypePickerSheetState extends State<_LessonTypePickerSheet> {
  bool _isLoading = true;
  String? _error;
  List<String> _availableTypes = [];
  Map<String, Map<String, dynamic>> _contentsMap = {};
  List<String> _completedTypes = [];

  @override
  void initState() {
    super.initState();
    _loadLessonTypes();
  }

  Future<void> _loadLessonTypes() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);

      // Fetch lesson type contents and progress in parallel
      final results = await Future.wait([
        apiService.getLessonTypeContents(widget.nodeId),
        apiService.getLessonTypeProgress(widget.nodeId).catchError((_) => <String, dynamic>{}),
      ]);

      final contentsData = results[0];
      final progressData = results[1];

      final contents = (contentsData['contents'] as List<dynamic>?) ?? [];
      final availableTypes = contents.map((c) {
        final m = c as Map<String, dynamic>;
        return m['lessonType'] as String;
      }).toList();

      final contentsMap = <String, Map<String, dynamic>>{};
      for (final c in contents) {
        final m = c as Map<String, dynamic>;
        contentsMap[m['lessonType'] as String] = m;
      }

      final completedTypes = (progressData['completedTypes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      if (!mounted) return;
      setState(() {
        _availableTypes = availableTypes;
        _contentsMap = contentsMap;
        _completedTypes = completedTypes;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _openLessonType(String typeKey) {
    final content = _contentsMap[typeKey];
    if (content == null) return;

    final lessonData = content['lessonData'] as Map<String, dynamic>? ?? {};
    final endQuiz = content['endQuiz'] as Map<String, dynamic>?;

    Navigator.pop(context); // close bottom sheet
    context.push('/lessons/${widget.nodeId}/view', extra: {
      'lessonType': typeKey,
      'lessonData': lessonData,
      'title': widget.lessonTitle,
      'endQuiz': endQuiz,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderPrimary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // Title
          Row(
            children: [
              const Icon(Icons.school_rounded, color: AppColors.purpleNeon, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.lessonTitle,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Chọn dạng bài muốn học',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Contributor notice
          if (widget.isContributor) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.star_rounded, color: Colors.amber.shade700, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bạn đang ở chế độ Contributor. Để nhận phần thưởng, hãy chuyển sang Learner mode để học và làm bài test!',
                      style: TextStyle(fontSize: 11, color: Colors.amber.shade800, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          // Content
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: CircularProgressIndicator(color: AppColors.purpleNeon),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.errorNeon, size: 36),
                  const SizedBox(height: 8),
                  Text('Lỗi tải dạng bài', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.errorNeon)),
                ],
              ),
            )
          else
            ...widget.allLessonTypes.map((type) {
              final key = type['key'] as String;
              final label = type['label'] as String;
              final icon = type['icon'] as IconData;
              final color = type['color'] as Color;
              final isAvailable = _availableTypes.contains(key);
              final isCompleted = _completedTypes.contains(key);

              return _buildTypeCard(
                key: key,
                label: label,
                icon: icon,
                color: color,
                isAvailable: isAvailable,
                isCompleted: isCompleted,
              );
            }),
          // Completed types summary
          if (!_isLoading && _completedTypes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${_completedTypes.length}/${_availableTypes.length} dạng bài đã hoàn thành',
              style: AppTextStyles.caption.copyWith(color: AppColors.successNeon),
            ),
          ],
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildTypeCard({
    required String key,
    required String label,
    required IconData icon,
    required Color color,
    required bool isAvailable,
    required bool isCompleted,
  }) {
    return GestureDetector(
      onTap: isAvailable
          ? () => _openLessonType(key)
          : () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Dạng "$label" chưa có nội dung cho bài này',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: AppColors.textSecondary,
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              );
            },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isAvailable ? AppColors.bgSecondary : AppColors.bgSecondary.withOpacity(0.4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCompleted
                ? AppColors.successNeon.withOpacity(0.4)
                : isAvailable
                    ? color.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.15),
            width: isCompleted ? 2 : 1,
          ),
        ),
        child: Opacity(
          opacity: isAvailable ? 1.0 : 0.45,
          child: Row(
            children: [
              // Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isCompleted
                        ? [AppColors.successNeon, const Color(0xFF2DD4BF)]
                        : [color, color.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isCompleted ? Icons.check_rounded : icon,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              // Label + status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: isAvailable ? AppColors.textPrimary : Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isCompleted
                          ? 'Đã hoàn thành'
                          : isAvailable
                              ? 'Nhấn để học'
                              : 'Chưa có nội dung',
                      style: AppTextStyles.caption.copyWith(
                        color: isCompleted
                            ? AppColors.successNeon
                            : isAvailable
                                ? AppColors.textSecondary
                                : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              // Right indicator
              if (isCompleted)
                const Icon(Icons.check_circle, color: AppColors.successNeon, size: 22)
              else if (isAvailable)
                Icon(Icons.chevron_right_rounded, color: color, size: 22)
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Chưa có',
                    style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
