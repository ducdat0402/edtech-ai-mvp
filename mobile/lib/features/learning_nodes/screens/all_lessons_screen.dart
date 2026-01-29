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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      
      // Load subject intro for subject info
      final introData = await apiService.getSubjectIntro(widget.subjectId);
      
      setState(() {
        _introData = introData;
      });
      
      // Load completed content items for this subject
      try {
        final completedIds = await apiService.getCompletedContentItemsBySubject(widget.subjectId);
        _completedContentIds = completedIds.toSet();
        debugPrint('📋 Loaded ${_completedContentIds.length} completed content IDs');
      } catch (e) {
        debugPrint('⚠️ Could not load completed items: $e');
        _completedContentIds = {};
      }
      
      // Get actual learning nodes using the learning nodes API
      // This returns real LearningNode entities that have content items
      final learningNodes = await apiService.getLearningNodesBySubject(widget.subjectId);
      debugPrint('📊 Found ${learningNodes.length} learning nodes');
      
      if (learningNodes.isEmpty) {
        debugPrint('❌ No learning nodes found');
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      // Sort nodes by order
      final sortedNodes = List<Map<String, dynamic>>.from(
        learningNodes.map((n) => Map<String, dynamic>.from(n as Map)),
      );
      sortedNodes.sort((a, b) {
        final orderA = a['order'] as int? ?? 999;
        final orderB = b['order'] as int? ?? 999;
        return orderA.compareTo(orderB);
      });
      
      setState(() {
        _totalNodes = sortedNodes.length;
      });
      
      // Fetch content items for each learning node
      final List<Map<String, dynamic>> allLessons = [];
      int lessonOrder = 1;
      
      for (int i = 0; i < sortedNodes.length; i++) {
        final node = sortedNodes[i];
        final nodeId = node['id'] as String;
        final nodeTitle = node['title'] as String? ?? 'Node ${i + 1}';
        
        try {
          final contentItems = await apiService.getContentByNode(nodeId);
          debugPrint('📚 Node "$nodeTitle" (id: $nodeId) has ${contentItems.length} content items');
          
          // Include all content types that are lessons (exclude boss_quiz)
          for (final item in contentItems) {
            final itemMap = Map<String, dynamic>.from(item as Map);
            final type = itemMap['type'] as String? ?? 'concept';
            final format = itemMap['format'] as String? ?? 'text';
            
            debugPrint('   - Item: ${itemMap['title']}, type: $type, format: $format');
            
            // Include concepts, examples, and hidden_reward (exclude only boss_quiz/quiz format)
            if (type != 'boss_quiz' && format != 'quiz') {
              final contentId = itemMap['id'] as String;
              itemMap['displayOrder'] = lessonOrder++;
              itemMap['nodeTitle'] = nodeTitle;
              itemMap['nodeOrder'] = node['order'] ?? (i + 1);
              // Mark as completed if in the completed set
              itemMap['isCompleted'] = _completedContentIds.contains(contentId);
              allLessons.add(itemMap);
            }
          }
          
          setState(() {
            _loadedNodes = i + 1;
          });
        } catch (e) {
          debugPrint('❌ Error loading content for node $nodeId: $e');
        }
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

  /// Check if a lesson is unlocked based on sequential unlock rules:
  /// - First lesson is always unlocked
  /// - A lesson that is completed is unlocked
  /// - A lesson is unlocked if the previous lesson is completed
  bool _isLessonUnlocked(int lessonIndex) {
    // First lesson is always unlocked
    if (lessonIndex == 0) return true;
    
    // If this lesson is already completed, it's unlocked
    final contentId = _allLessons[lessonIndex]['id'] as String;
    if (_completedContentIds.contains(contentId)) return true;
    
    // Check if previous lesson is completed
    final previousContentId = _allLessons[lessonIndex - 1]['id'] as String;
    return _completedContentIds.contains(previousContentId);
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
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _allLessons.length + 1, // +1 for header
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildHeader();
          }
          final lessonIndex = index - 1;
          final isUnlocked = _isLessonUnlocked(lessonIndex);
          return _buildLessonCard(_allLessons[lessonIndex], lessonIndex + 1, isUnlocked);
        },
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
    final contentId = lesson['id'] as String;
    final title = lesson['title'] as String? ?? 'Bài học $displayIndex';
    final nodeTitle = lesson['nodeTitle'] as String? ?? '';

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
      statusText = 'Nhấn để học';
    } else {
      statusColor = Colors.grey;
      statusIcon = Icons.lock;
      statusText = 'Hoàn thành bài trước để mở khóa';
    }

    return InkWell(
      onTap: isUnlocked
          ? () {
              HapticFeedback.lightImpact();
              // Navigate to content viewer for this lesson
              context.push('/content/$contentId');
            }
          : () {
              // Show locked message
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
                  // Number circle - always show number
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
                  // Connecting line to next item
                  Container(
                    width: 2,
                    height: 60,
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
                child: Row(
                  children: [
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Node/Topic name
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
                          const SizedBox(height: 6),
                          Row(
                            children: [
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
                            ],
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
