import 'package:flutter/material.dart';
import 'package:edtech_mobile/core/widgets/app_bar_leading_back_home.dart';
import 'package:edtech_mobile/theme/theme.dart';
import 'package:edtech_mobile/features/lessons/editors/image_quiz_editor_screen.dart';
import 'package:edtech_mobile/features/lessons/editors/image_gallery_editor_screen.dart';
import 'package:edtech_mobile/features/lessons/editors/video_editor_screen.dart';
import 'package:edtech_mobile/features/lessons/editors/text_editor_screen.dart';

class LessonTypePickerScreen extends StatefulWidget {
  final String subjectId;
  final String domainId;
  final String? topicName;
  final String? topicId;
  final String? preselectedType;
  final String? nodeId; // Existing node ID to add content to
  final String?
      existingLessonNodeId; // ID of lesson node to check existing types
  final String? existingLessonType; // Current lesson type of the node

  const LessonTypePickerScreen({
    super.key,
    required this.subjectId,
    required this.domainId,
    this.topicName,
    this.topicId,
    this.preselectedType,
    this.nodeId,
    this.existingLessonNodeId,
    this.existingLessonType,
  });

  @override
  State<LessonTypePickerScreen> createState() => _LessonTypePickerScreenState();
}

class _LessonTypePickerScreenState extends State<LessonTypePickerScreen> {
  bool _autoNavigated = false;

  @override
  void initState() {
    super.initState();
    // Auto-navigate to the specific editor if a type is preselected
    if (widget.preselectedType != null) {
      _autoNavigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _navigateToEditor(context, widget.preselectedType!);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.colors;
    // If preselected and not yet navigated, show loading
    if (widget.preselectedType != null && !_autoNavigated) {
      return Scaffold(
        backgroundColor: t.bg,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        title: const Text('Chọn dạng bài học'),
        backgroundColor: t.bg,
        foregroundColor: t.textPrimary,
        elevation: 0,
        leading: const AppBarLeadingBackAndHome(),
        leadingWidth: 112,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.topicName != null) ...[
              Text(
                'Tạo bài học cho: ${widget.topicName}',
                style: TextStyle(color: t.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              'Chọn dạng bài học bạn muốn tạo',
              style: TextStyle(
                  color: t.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
                children: [
                  _buildTypeCard(
                    context,
                    icon: Icons.quiz_outlined,
                    title: 'Hình ảnh\n(Quiz)',
                    description:
                        'Câu hỏi trắc nghiệm kèm hình ảnh, swipe qua nhiều câu',
                    color: t.brand,
                    onTap: () => _navigateToEditor(context, 'image_quiz'),
                  ),
                  _buildTypeCard(
                    context,
                    icon: Icons.photo_library_outlined,
                    title: 'Hình ảnh\n(Thư viện)',
                    description: 'Nhiều hình ảnh kèm mô tả chi tiết',
                    color: t.gold,
                    onTap: () => _navigateToEditor(context, 'image_gallery'),
                  ),
                  _buildTypeCard(
                    context,
                    icon: Icons.play_circle_outline,
                    title: 'Video',
                    description:
                        'Video bài giảng kèm tóm tắt và nội dung chính',
                    color: t.warning,
                    onTap: () => _navigateToEditor(context, 'video'),
                  ),
                  _buildTypeCard(
                    context,
                    icon: Icons.article_outlined,
                    title: 'Văn bản',
                    description: 'Bài viết với câu hỏi xen kẽ và tổng kết',
                    color: t.info,
                    onTap: () => _navigateToEditor(context, 'text'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    final t = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 36),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: t.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: t.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToEditor(BuildContext context, String type) {
    // Check if this lesson type already exists for this lesson node
    if (widget.existingLessonType != null &&
        widget.existingLessonType == type) {
      _showAlreadyExistsDialog(context, type);
      return;
    }

    Widget screen;
    switch (type) {
      case 'image_quiz':
        screen = ImageQuizEditorScreen(
            subjectId: widget.subjectId,
            domainId: widget.domainId,
            topicName: widget.topicName,
            topicId: widget.topicId,
            nodeId: widget.nodeId);
        break;
      case 'image_gallery':
        screen = ImageGalleryEditorScreen(
            subjectId: widget.subjectId,
            domainId: widget.domainId,
            topicName: widget.topicName,
            topicId: widget.topicId,
            nodeId: widget.nodeId);
        break;
      case 'video':
        screen = VideoEditorScreen(
            subjectId: widget.subjectId,
            domainId: widget.domainId,
            topicName: widget.topicName,
            topicId: widget.topicId,
            nodeId: widget.nodeId);
        break;
      case 'text':
        screen = TextEditorScreen(
            subjectId: widget.subjectId,
            domainId: widget.domainId,
            topicName: widget.topicName,
            topicId: widget.topicId,
            nodeId: widget.nodeId);
        break;
      default:
        return;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  void _showAlreadyExistsDialog(BuildContext context, String type) {
    final t = context.colors;
    final typeLabel = _getTypeLabel(type);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: t.warning, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Dạng bài học đã tồn tại',
                style: TextStyle(
                    color: t.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: t.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: t.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: t.success, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Dạng bài học "$typeLabel" đã tồn tại và được phê duyệt.',
                      style: TextStyle(color: t.textPrimary, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Bạn có thể:',
              style: TextStyle(
                  color: t.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14),
            ),
            const SizedBox(height: 8),
            _buildOption(Icons.edit_outlined, 'Chỉnh sửa dạng bài học này'),
            const SizedBox(height: 6),
            _buildOption(
                Icons.add_circle_outline, 'Tạo dạng bài học khác còn thiếu'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Đóng', style: TextStyle(color: t.textSecondary)),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(IconData icon, String text) {
    final t = context.colors;
    return Row(
      children: [
        Icon(icon, color: t.brand, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: t.textSecondary, fontSize: 13),
          ),
        ),
      ],
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'image_quiz':
        return 'Quiz';
      case 'image_gallery':
        return 'Hình ảnh';
      case 'video':
        return 'Video';
      case 'text':
        return 'Văn bản';
      default:
        return type;
    }
  }
}
