import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/theme/colors.dart';
import 'package:edtech_mobile/features/lessons/screens/image_quiz_lesson_screen.dart';
import 'package:edtech_mobile/features/lessons/screens/image_gallery_lesson_screen.dart';
import 'package:edtech_mobile/features/lessons/screens/video_lesson_screen.dart';
import 'package:edtech_mobile/features/lessons/screens/text_lesson_screen.dart';
import 'package:edtech_mobile/features/lessons/editors/image_quiz_editor_screen.dart';
import 'package:edtech_mobile/features/lessons/editors/image_gallery_editor_screen.dart';
import 'package:edtech_mobile/features/lessons/editors/video_editor_screen.dart';
import 'package:edtech_mobile/features/lessons/editors/text_editor_screen.dart';

/// Screen showing version history for a specific lesson type of a learning node.
/// Contributors can view past versions and create edits based on any version.
class LessonTypeHistoryScreen extends StatefulWidget {
  final String nodeId;
  final String lessonType;
  final String subjectId;
  final String? domainId;
  final String? topicId;
  final String? lessonTitle;

  const LessonTypeHistoryScreen({
    super.key,
    required this.nodeId,
    required this.lessonType,
    required this.subjectId,
    this.domainId,
    this.topicId,
    this.lessonTitle,
  });

  @override
  State<LessonTypeHistoryScreen> createState() =>
      _LessonTypeHistoryScreenState();
}

class _LessonTypeHistoryScreenState extends State<LessonTypeHistoryScreen> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _versions = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final data = await apiService.getLessonTypeHistory(
          widget.nodeId, widget.lessonType);
      setState(() {
        _versions = data['versions'] as List? ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _getLessonTypeLabel(String type) {
    switch (type) {
      case 'image_quiz':
        return 'Hình ảnh (Quiz)';
      case 'image_gallery':
        return 'Hình ảnh (Thư viện)';
      case 'video':
        return 'Video';
      case 'text':
        return 'Văn bản';
      default:
        return type;
    }
  }

  void _viewVersion(Map<String, dynamic> version) {
    final lessonData = version['lessonData'] as Map<String, dynamic>? ?? {};
    final endQuiz = version['endQuiz'] as Map<String, dynamic>?;
    final title = widget.lessonTitle ?? 'Phiên bản ${version['version']}';

    Widget viewer;
    switch (widget.lessonType) {
      case 'image_quiz':
        viewer = ImageQuizLessonScreen(
          nodeId: '',
          lessonData: lessonData,
          title: title,
          endQuiz: endQuiz ?? {},
        );
        break;
      case 'image_gallery':
        viewer = ImageGalleryLessonScreen(
          nodeId: '',
          lessonData: lessonData,
          title: title,
          endQuiz: endQuiz ?? {},
        );
        break;
      case 'video':
        viewer = VideoLessonScreen(
          nodeId: '',
          lessonData: lessonData,
          title: title,
          endQuiz: endQuiz ?? {},
        );
        break;
      case 'text':
      default:
        viewer = TextLessonScreen(
          nodeId: '',
          lessonData: lessonData,
          title: title,
          endQuiz: endQuiz ?? {},
        );
        break;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => viewer),
    );
  }

  void _editFromVersion(Map<String, dynamic> version) {
    final lessonData = version['lessonData'] as Map<String, dynamic>? ?? {};
    final endQuiz = version['endQuiz'] as Map<String, dynamic>?;

    Widget editor;
    switch (widget.lessonType) {
      case 'image_quiz':
        editor = ImageQuizEditorScreen(
          subjectId: widget.subjectId,
          domainId: widget.domainId ?? '',
          topicId: widget.topicId,
          nodeId: widget.nodeId,
          initialTitle: widget.lessonTitle,
          initialDescription: '',
          initialLessonData: lessonData,
          initialEndQuiz: endQuiz,
          isEditMode: true,
          originalLessonData: lessonData,
          originalEndQuiz: endQuiz,
        );
        break;
      case 'image_gallery':
        editor = ImageGalleryEditorScreen(
          subjectId: widget.subjectId,
          domainId: widget.domainId ?? '',
          topicId: widget.topicId,
          nodeId: widget.nodeId,
          initialTitle: widget.lessonTitle,
          initialDescription: '',
          initialLessonData: lessonData,
          initialEndQuiz: endQuiz,
          isEditMode: true,
          originalLessonData: lessonData,
          originalEndQuiz: endQuiz,
        );
        break;
      case 'video':
        editor = VideoEditorScreen(
          subjectId: widget.subjectId,
          domainId: widget.domainId ?? '',
          topicId: widget.topicId,
          nodeId: widget.nodeId,
          initialTitle: widget.lessonTitle,
          initialDescription: '',
          initialLessonData: lessonData,
          initialEndQuiz: endQuiz,
          isEditMode: true,
          originalLessonData: lessonData,
          originalEndQuiz: endQuiz,
        );
        break;
      case 'text':
      default:
        editor = TextEditorScreen(
          subjectId: widget.subjectId,
          domainId: widget.domainId ?? '',
          topicId: widget.topicId,
          nodeId: widget.nodeId,
          initialTitle: widget.lessonTitle,
          initialDescription: '',
          initialLessonData: lessonData,
          initialEndQuiz: endQuiz,
          isEditMode: true,
          originalLessonData: lessonData,
          originalEndQuiz: endQuiz,
        );
        break;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => editor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgSecondary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lịch sử chỉnh sửa',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            Text(
              _getLessonTypeLabel(widget.lessonType),
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _versions.isEmpty
                  ? _buildEmpty()
                  : _buildVersionList(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.errorNeon),
          const SizedBox(height: 16),
          Text('Lỗi: $_error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.errorNeon)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadHistory, child: const Text('Thử lại')),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history,
              size: 64, color: AppColors.textTertiary.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text(
            'Chưa có lịch sử chỉnh sửa',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Lịch sử sẽ xuất hiện khi nội dung được chỉnh sửa và duyệt.',
            style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVersionList() {
    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _versions.length,
        itemBuilder: (context, index) {
          final version = _versions[index] as Map<String, dynamic>;
          final isNewest = index == 0;
          return _buildVersionCard(version, isNewest);
        },
      ),
    );
  }

  Widget _buildVersionCard(Map<String, dynamic> version, bool isNewest) {
    final versionNumber = version['version'] as int? ?? 0;
    final createdAt = version['createdAt'] as String? ?? '';
    final note = version['note'] as String? ?? '';
    final lessonData = version['lessonData'] as Map<String, dynamic>? ?? {};

    // Format date
    String dateStr = '';
    try {
      final date = DateTime.parse(createdAt);
      dateStr =
          '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      dateStr = createdAt;
    }

    // Count content items based on type
    String contentSummary = '';
    switch (widget.lessonType) {
      case 'image_quiz':
        final slides = lessonData['slides'] as List? ?? [];
        contentSummary = '${slides.length} slides';
        break;
      case 'image_gallery':
        final images = lessonData['images'] as List? ?? [];
        contentSummary = '${images.length} hình ảnh';
        break;
      case 'video':
        final keyPoints = lessonData['keyPoints'] as List? ?? [];
        contentSummary = '${keyPoints.length} nội dung chính';
        break;
      case 'text':
        final sections = lessonData['sections'] as List? ?? [];
        contentSummary = '${sections.length} phần';
        break;
    }

    final endQuiz = version['endQuiz'] as Map<String, dynamic>?;
    final quizCount = (endQuiz?['questions'] as List?)?.length ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isNewest
              ? AppColors.purpleNeon.withOpacity(0.3)
              : AppColors.borderPrimary,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Version number badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isNewest
                        ? AppColors.purpleNeon.withOpacity(0.15)
                        : AppColors.bgTertiary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'v$versionNumber',
                    style: TextStyle(
                      color: isNewest
                          ? AppColors.purpleNeon
                          : AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isNewest) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.successNeon.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Mới nhất',
                      style: TextStyle(
                          color: AppColors.successNeon,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  dateStr,
                  style: const TextStyle(
                      color: AppColors.textTertiary, fontSize: 12),
                ),
              ],
            ),
          ),
          // Content summary
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (note.isNotEmpty) ...[
                  Text(note,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    const Icon(Icons.description_outlined,
                        size: 14, color: AppColors.textTertiary),
                    const SizedBox(width: 4),
                    Text(contentSummary,
                        style: const TextStyle(
                            color: AppColors.textTertiary, fontSize: 12)),
                    const SizedBox(width: 12),
                    const Icon(Icons.quiz_outlined,
                        size: 14, color: AppColors.textTertiary),
                    const SizedBox(width: 4),
                    Text('$quizCount câu hỏi',
                        style: const TextStyle(
                            color: AppColors.textTertiary, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Action buttons
          const Divider(height: 1, color: AppColors.borderPrimary),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _viewVersion(version),
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text('Xem', style: TextStyle(fontSize: 13)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.cyanNeon,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              Container(width: 1, height: 24, color: AppColors.borderPrimary),
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _editFromVersion(version),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Sửa từ bản này',
                      style: TextStyle(fontSize: 13)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.orangeNeon,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
