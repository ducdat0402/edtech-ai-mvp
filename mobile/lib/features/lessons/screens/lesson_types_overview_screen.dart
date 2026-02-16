import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/theme/theme.dart';

/// Screen showing all available lesson types for a learning node.
/// Displays completion status per type and navigates to the specific viewer.
class LessonTypesOverviewScreen extends StatefulWidget {
  final String nodeId;
  final String title;

  const LessonTypesOverviewScreen({
    super.key,
    required this.nodeId,
    required this.title,
  });

  @override
  State<LessonTypesOverviewScreen> createState() =>
      _LessonTypesOverviewScreenState();
}

class _LessonTypesOverviewScreenState extends State<LessonTypesOverviewScreen> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _contents = [];
  List<String> _completedTypes = [];
  bool _isLessonComplete = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);

      // Fetch lesson type contents and progress in parallel
      final results = await Future.wait([
        apiService.getLessonTypeContents(widget.nodeId),
        apiService.getLessonTypeProgress(widget.nodeId),
      ]);

      final contentsData = results[0];
      final progressData = results[1];

      if (!mounted) return;

      setState(() {
        _contents = (contentsData['contents'] as List<dynamic>?) ?? [];
        _completedTypes =
            (progressData['completedTypes'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
        _isLessonComplete = progressData['isLessonComplete'] == true;
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

  void _openLessonType(Map<String, dynamic> content) {
    final lessonType = content['lessonType'] as String;
    final lessonData = content['lessonData'] as Map<String, dynamic>? ?? {};
    final endQuiz = content['endQuiz'] as Map<String, dynamic>?;

    context.push('/lessons/${widget.nodeId}/view', extra: {
      'lessonType': lessonType,
      'lessonData': lessonData,
      'title': widget.title,
      'endQuiz': endQuiz,
    }).then((_) {
      // Refresh progress when returning from lesson
      if (mounted) _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.title,
          style:
              AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.purpleNeon))
          : _error != null
              ? _buildErrorState()
              : _contents.isEmpty
                  ? _buildEmptyState()
                  : _buildContentList(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.errorNeon),
          const SizedBox(height: 16),
          Text('Lỗi: $_error',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          GamingButton(
            text: 'Thử lại',
            onPressed: () {
              setState(() {
                _isLoading = true;
                _error = null;
              });
              _loadData();
            },
            icon: Icons.refresh_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.purpleNeon.withOpacity(0.1),
              ),
              child: const Icon(Icons.school_outlined, size: 48, color: AppColors.purpleNeon),
            ),
            const SizedBox(height: 24),
            Text(
              'Chưa có dạng bài học nào',
              style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Bài học này chưa có nội dung. Vui lòng quay lại sau.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentList() {
    final completedCount = _completedTypes.length;
    final totalCount = _contents.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress header
          _buildProgressHeader(completedCount, totalCount),
          const SizedBox(height: 24),

          // Lesson types list
          ...List.generate(_contents.length, (index) {
            final content = _contents[index] as Map<String, dynamic>;
            return _buildLessonTypeCard(content, index);
          }),

          // Completion message
          if (_isLessonComplete) ...[
            const SizedBox(height: 20),
            _buildCompletionBanner(),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressHeader(int completed, int total) {
    final progress = total > 0 ? completed / total : 0.0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.purpleNeon.withOpacity(0.1),
            AppColors.cyanNeon.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.purpleNeon.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.school_rounded, color: AppColors.purpleNeon, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tiến độ bài học',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$completed/$total dạng bài đã hoàn thành',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Percentage badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _isLessonComplete
                      ? AppColors.successNeon.withOpacity(0.15)
                      : AppColors.purpleNeon.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(progress * 100).round()}%',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: _isLessonComplete ? AppColors.successNeon : AppColors.purpleNeon,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.bgTertiary,
              valueColor: AlwaysStoppedAnimation(
                _isLessonComplete ? AppColors.successNeon : AppColors.purpleNeon,
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonTypeCard(Map<String, dynamic> content, int index) {
    final type = content['lessonType'] as String;
    final isCompleted = _completedTypes.contains(type);
    final info = _getTypeInfo(type);

    return GestureDetector(
      onTap: () => _openLessonType(content),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isCompleted
                ? AppColors.successNeon.withOpacity(0.4)
                : AppColors.borderPrimary,
            width: isCompleted ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Type icon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isCompleted
                      ? [AppColors.successNeon, const Color(0xFF2DD4BF)]
                      : [info['color'] as Color, (info['color'] as Color).withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isCompleted ? Icons.check_rounded : info['icon'] as IconData,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info['label'] as String,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isCompleted ? 'Đã hoàn thành' : 'Nhấn để bắt đầu',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isCompleted ? AppColors.successNeon : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Arrow
            Icon(
              Icons.chevron_right_rounded,
              color: isCompleted ? AppColors.successNeon : AppColors.textSecondary,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.successNeon.withOpacity(0.15),
            AppColors.cyanNeon.withOpacity(0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.successNeon.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.successNeon.withOpacity(0.2),
            ),
            child: const Icon(Icons.emoji_events_rounded, color: AppColors.successNeon, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bài học đã hoàn thành!',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.successNeon,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bạn đã hoàn thành tất cả dạng bài trong bài học này.',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getTypeInfo(String type) {
    switch (type) {
      case 'image_quiz':
        return {
          'label': 'Hình ảnh (Quiz)',
          'icon': Icons.quiz_outlined,
          'color': const Color(0xFFE879F9),
        };
      case 'image_gallery':
        return {
          'label': 'Hình ảnh (Thư viện)',
          'icon': Icons.photo_library_outlined,
          'color': const Color(0xFF38BDF8),
        };
      case 'video':
        return {
          'label': 'Video',
          'icon': Icons.play_circle_outline,
          'color': const Color(0xFFFB923C),
        };
      case 'text':
        return {
          'label': 'Văn bản',
          'icon': Icons.article_outlined,
          'color': const Color(0xFF34D399),
        };
      default:
        return {
          'label': type,
          'icon': Icons.school_outlined,
          'color': AppColors.purpleNeon,
        };
    }
  }
}
