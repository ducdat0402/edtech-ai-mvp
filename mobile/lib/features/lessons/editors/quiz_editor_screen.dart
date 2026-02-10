import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edtech_mobile/theme/colors.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/features/lessons/screens/image_quiz_lesson_screen.dart';
import 'package:edtech_mobile/features/lessons/screens/image_gallery_lesson_screen.dart';
import 'package:edtech_mobile/features/lessons/screens/video_lesson_screen.dart';
import 'package:edtech_mobile/features/lessons/screens/text_lesson_screen.dart';

class QuizEditorScreen extends StatefulWidget {
  final String lessonType;
  final Map<String, dynamic> lessonData;
  final String title;
  final String description;
  final String subjectId;
  final String domainId;
  final String? topicName;
  final String? topicId;
  final String? nodeId; // Existing node ID when adding content to an existing lesson
  final Map<String, dynamic>? initialEndQuiz;
  final bool isEditMode;
  final Map<String, dynamic>? originalLessonData;
  final Map<String, dynamic>? originalEndQuiz;

  const QuizEditorScreen({
    super.key,
    required this.lessonType,
    required this.lessonData,
    required this.title,
    required this.description,
    required this.subjectId,
    required this.domainId,
    this.topicName,
    this.topicId,
    this.nodeId,
    this.initialEndQuiz,
    this.isEditMode = false,
    this.originalLessonData,
    this.originalEndQuiz,
  });

  @override
  State<QuizEditorScreen> createState() => _QuizEditorScreenState();
}

class _QuizEditorScreenState extends State<QuizEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  List<_QuestionData> _questions = [];
  bool _isSubmitting = false;

  static const int _minQuestions = 5;
  static const int _maxQuestions = 7;

  @override
  void initState() {
    super.initState();
    _prefillData();
  }

  void _prefillData() {
    final endQuiz = widget.initialEndQuiz;
    if (endQuiz != null) {
      final questions = endQuiz['questions'] as List?;
      if (questions != null && questions.isNotEmpty) {
        _questions = questions.map((q) {
          final m = q as Map<String, dynamic>;
          final qd = _QuestionData();
          qd.questionController.text = m['question'] as String? ?? '';
          qd.correctAnswer = m['correctAnswer'] as int? ?? 0;
          final options = m['options'] as List? ?? [];
          for (int i = 0; i < options.length && i < 4; i++) {
            final opt = options[i] as Map<String, dynamic>;
            qd.optionControllers[i].text = opt['text'] as String? ?? '';
            qd.explanationControllers[i].text = opt['explanation'] as String? ?? '';
          }
          return qd;
        }).toList();
        // Ensure minimum questions
        while (_questions.length < _minQuestions) {
          _questions.add(_QuestionData());
        }
        return;
      }
    }
    // Default: start with 5 empty questions
    for (int i = 0; i < _minQuestions; i++) {
      _questions.add(_QuestionData());
    }
  }

  @override
  void dispose() {
    for (final q in _questions) {
      q.dispose();
    }
    super.dispose();
  }

  void _addQuestion() {
    if (_questions.length >= _maxQuestions) return;
    setState(() {
      _questions.add(_QuestionData());
    });
  }

  void _removeQuestion(int index) {
    if (_questions.length <= _minQuestions) return;
    setState(() {
      _questions[index].dispose();
      _questions.removeAt(index);
    });
  }

  void _onAISuggest() {
    // TODO: Integrate AI quiz generation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('AI quiz generation coming soon'),
        backgroundColor: AppColors.bgTertiary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// Preview lesson as learner would see it
  void _previewLesson() {
    final lessonData = widget.lessonData;
    final title = widget.title;
    // Build endQuiz from current editor state
    final endQuiz = {
      'questions': _questions.map((q) => q.toJson()).toList(),
      'passingScore': 70,
    };

    Widget viewer;
    switch (widget.lessonType) {
      case 'image_quiz':
        viewer = ImageQuizLessonScreen(nodeId: '', lessonData: lessonData, title: title, endQuiz: endQuiz);
        break;
      case 'image_gallery':
        viewer = ImageGalleryLessonScreen(nodeId: '', lessonData: lessonData, title: title, endQuiz: endQuiz);
        break;
      case 'video':
        viewer = VideoLessonScreen(nodeId: '', lessonData: lessonData, title: title, endQuiz: endQuiz);
        break;
      case 'text':
      default:
        viewer = TextLessonScreen(nodeId: '', lessonData: lessonData, title: title, endQuiz: endQuiz);
        break;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => viewer),
    );
  }

  /// Compare with existing lesson (if nodeId exists)
  void _compareLessons() {
    // Show a comparison bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgPrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _LessonComparisonSheet(
        lessonType: widget.lessonType,
        newLessonData: widget.lessonData,
        newTitle: widget.title,
        newDescription: widget.description,
        newQuiz: _questions.map((q) => q.toJson()).toList(),
        originalLessonData: widget.originalLessonData,
        originalEndQuiz: widget.originalEndQuiz,
        isEditMode: widget.isEditMode,
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_questions.length < _minQuestions) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cần ít nhất $_minQuestions câu hỏi'),
          backgroundColor: AppColors.errorNeon,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final endQuiz = {
        'questions': _questions.map((q) => q.toJson()).toList(),
        'passingScore': 70,
      };

      if (widget.isEditMode && widget.nodeId != null) {
        // Edit mode: submit as lesson content edit contribution
        final editData = {
          'nodeId': widget.nodeId,
          'lessonType': widget.lessonType,
          'lessonData': widget.lessonData,
          'endQuiz': endQuiz,
          'reason': 'Chỉnh sửa nội dung dạng ${widget.lessonType}',
        };
        await apiService.createLessonContentEditContribution(editData);
      } else {
        // Create mode: submit as new lesson contribution
        final data = {
          'lessonType': widget.lessonType,
          'lessonData': widget.lessonData,
          'endQuiz': endQuiz,
          'title': widget.title,
          'description': widget.description,
          'subjectId': widget.subjectId,
          'domainId': widget.domainId,
          if (widget.topicId != null) 'topicId': widget.topicId,
          if (widget.topicName != null) 'topicName': widget.topicName,
          if (widget.nodeId != null) 'nodeId': widget.nodeId,
        };
        await apiService.createLessonContribution(data);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isEditMode
              ? 'Đã gửi chỉnh sửa thành công! Chờ admin duyệt.'
              : 'Đã gửi đóng góp thành công!'),
          backgroundColor: AppColors.successGlow,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      // Pop back to the contributor mind map or previous screen
      Navigator.of(context)
        ..pop() // pop QuizEditorScreen
        ..pop(); // pop the lesson editor screen
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
          backgroundColor: AppColors.errorNeon,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.bgSecondary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderPrimary),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderPrimary),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.purpleNeon),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgSecondary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.isEditMode ? 'Sửa bài test cuối bài' : 'Bài test cuối bài',
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 18),
        ),
        actions: [
          TextButton.icon(
            onPressed: _onAISuggest,
            icon:
                const Icon(Icons.auto_awesome, color: AppColors.orangeNeon, size: 20),
            label: const Text(
              'AI Gợi ý',
              style: TextStyle(color: AppColors.orangeNeon),
            ),
          ),
        ],
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Header info bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.bgSecondary.withOpacity(0.5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Bài test cuối bài (${_minQuestions}-${_maxQuestions} câu)',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _questions.length >= _minQuestions
                          ? AppColors.successNeon.withOpacity(0.15)
                          : AppColors.warningNeon.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_questions.length}/$_maxQuestions',
                      style: TextStyle(
                        color: _questions.length >= _minQuestions
                            ? AppColors.successNeon
                            : AppColors.warningNeon,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question cards
                    ...List.generate(_questions.length, (index) {
                      return _buildQuestionCard(index);
                    }),

                    // Add question button
                    if (_questions.length < _maxQuestions)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: OutlinedButton.icon(
                            onPressed: _addQuestion,
                            icon: const Icon(Icons.add,
                                color: AppColors.purpleNeon),
                            label: const Text(
                              'Thêm câu hỏi',
                              style: TextStyle(color: AppColors.purpleNeon),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: AppColors.purpleNeon, width: 1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Bottom action buttons: Preview, Compare, Submit
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.bgSecondary,
                border: Border(
                  top: BorderSide(color: AppColors.borderPrimary),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Preview & Compare row
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _previewLesson,
                          icon: const Icon(Icons.visibility_outlined, size: 18),
                          label: const Text('Xem trước'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.cyanNeon,
                            side: const BorderSide(color: AppColors.cyanNeon),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _compareLessons,
                          icon: const Icon(Icons.compare_arrows_outlined, size: 18),
                          label: const Text('So sánh'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.orangeNeon,
                            side: const BorderSide(color: AppColors.orangeNeon),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submit,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded, size: 18),
                      label: Text(
                        _isSubmitting
                            ? 'Đang gửi...'
                            : widget.isEditMode
                                ? 'Gửi chỉnh sửa'
                                : 'Gửi đóng góp',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.successGlow,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppColors.successGlow.withValues(alpha: 0.4),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(int index) {
    final question = _questions[index];
    final labels = ['A', 'B', 'C', 'D'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Câu ${index + 1}',
                style: const TextStyle(
                  color: AppColors.purpleNeon,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_questions.length > _minQuestions)
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.errorNeon, size: 20),
                  onPressed: () => _removeQuestion(index),
                ),
            ],
          ),
          const Divider(color: AppColors.borderPrimary, height: 20),

          // Question text
          TextFormField(
            controller: question.questionController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: _inputDecoration('Câu hỏi'),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Nhập câu hỏi' : null,
          ),
          const SizedBox(height: 12),

          // Options
          ...List.generate(4, (optIdx) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Radio<int>(
                        value: optIdx,
                        groupValue: question.correctAnswer,
                        onChanged: (v) {
                          setState(() {
                            question.correctAnswer = v ?? 0;
                          });
                        },
                        activeColor: AppColors.successNeon,
                        fillColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return AppColors.successNeon;
                          }
                          return AppColors.textTertiary;
                        }),
                      ),
                      Text(
                        labels[optIdx],
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: question.optionControllers[optIdx],
                          style: const TextStyle(
                              color: AppColors.textPrimary, fontSize: 14),
                          decoration:
                              _inputDecoration('Đáp án ${labels[optIdx]}'),
                          validator: (v) =>
                              v == null || v.trim().isEmpty
                                  ? 'Nhập đáp án'
                                  : null,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 56, top: 4),
                    child: TextFormField(
                      controller: question.explanationControllers[optIdx],
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                      decoration: _inputDecoration('Giải thích (tuỳ chọn)'),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Comparison bottom sheet showing new vs existing lesson data
class _LessonComparisonSheet extends StatelessWidget {
  final String lessonType;
  final Map<String, dynamic> newLessonData;
  final String newTitle;
  final String newDescription;
  final List<Map<String, dynamic>> newQuiz;
  final Map<String, dynamic>? originalLessonData;
  final Map<String, dynamic>? originalEndQuiz;
  final bool isEditMode;

  const _LessonComparisonSheet({
    required this.lessonType,
    required this.newLessonData,
    required this.newTitle,
    required this.newDescription,
    required this.newQuiz,
    this.originalLessonData,
    this.originalEndQuiz,
    this.isEditMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textTertiary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.compare_arrows, color: AppColors.orangeNeon),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'So sánh bài học',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.borderPrimary),
          // Content
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                // Old version (if in edit mode)
                if (isEditMode && originalLessonData != null) ...[
                  _buildVersionCard(
                    label: 'Phiên bản hiện tại',
                    color: AppColors.textTertiary,
                    title: newTitle,
                    description: '',
                    lessonType: lessonType,
                    details: _buildDetailsFromData(originalLessonData!),
                    quizCount: (originalEndQuiz?['questions'] as List?)?.length ?? 0,
                  ),
                  const SizedBox(height: 12),
                  // Arrow separator
                  const Center(
                    child: Icon(Icons.arrow_downward_rounded, color: AppColors.orangeNeon, size: 28),
                  ),
                  const SizedBox(height: 12),
                ],
                // New version info
                _buildVersionCard(
                  label: isEditMode ? 'Phiên bản mới (đang sửa)' : 'Phiên bản mới (đang tạo)',
                  color: AppColors.successNeon,
                  title: newTitle,
                  description: newDescription,
                  lessonType: lessonType,
                  details: _buildDetailsFromData(newLessonData),
                  quizCount: newQuiz.length,
                ),
                const SizedBox(height: 16),
                // Note about comparison
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.bgTertiary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderPrimary),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.textTertiary, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isEditMode
                              ? 'Sau khi admin duyệt, phiên bản mới sẽ thay thế phiên bản hiện tại. Phiên bản cũ sẽ được lưu vào lịch sử.'
                              : 'Đây là bài học mới. Sau khi được duyệt, nó sẽ xuất hiện trong danh sách bài học.',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionCard({
    required String label,
    required Color color,
    required String title,
    required String description,
    required String lessonType,
    required List<Widget> details,
    required int quizCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          // Title
          Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 8),
          // Lesson type badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.purpleNeon.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _getLessonTypeLabel(lessonType),
              style: const TextStyle(color: AppColors.purpleNeon, fontSize: 12),
            ),
          ),
          const SizedBox(height: 12),
          // Details
          ...details,
          const SizedBox(height: 8),
          // Quiz count
          Row(
            children: [
              const Icon(Icons.quiz_outlined, color: AppColors.orangeNeon, size: 16),
              const SizedBox(width: 6),
              Text(
                'Quiz cuối bài: $quizCount câu hỏi',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getLessonTypeLabel(String type) {
    switch (type) {
      case 'image_quiz': return 'Hình ảnh (Quiz)';
      case 'image_gallery': return 'Hình ảnh (Thư viện)';
      case 'video': return 'Video';
      case 'text': return 'Văn bản';
      default: return type;
    }
  }

  List<Widget> _buildDetailsFromData(Map<String, dynamic> data) {
    switch (lessonType) {
      case 'image_quiz':
        final slides = data['slides'] as List? ?? [];
        return [
          _detailRow(Icons.layers_outlined, '${slides.length} slides'),
        ];
      case 'image_gallery':
        final images = data['images'] as List? ?? [];
        return [
          _detailRow(Icons.photo_library_outlined, '${images.length} hình ảnh'),
        ];
      case 'video':
        final url = data['videoUrl'] as String? ?? '';
        final keyPoints = data['keyPoints'] as List? ?? [];
        return [
          _detailRow(Icons.link, url.isNotEmpty ? 'Có video URL' : 'Chưa có URL'),
          _detailRow(Icons.list, '${keyPoints.length} nội dung chính'),
        ];
      case 'text':
        final sections = data['sections'] as List? ?? [];
        final inlineQuizzes = data['inlineQuizzes'] as List? ?? [];
        return [
          _detailRow(Icons.article_outlined, '${sections.length} phần nội dung'),
          _detailRow(Icons.help_outline, '${inlineQuizzes.length} câu hỏi xen kẽ'),
        ];
      default:
        return [];
    }
  }

  Widget _detailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textTertiary, size: 16),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}

class _QuestionData {
  final questionController = TextEditingController();
  final List<TextEditingController> optionControllers =
      List.generate(4, (_) => TextEditingController());
  final List<TextEditingController> explanationControllers =
      List.generate(4, (_) => TextEditingController());
  int correctAnswer = 0;

  void dispose() {
    questionController.dispose();
    for (final c in optionControllers) {
      c.dispose();
    }
    for (final c in explanationControllers) {
      c.dispose();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'question': questionController.text,
      'options': List.generate(4, (i) {
        return {
          'text': optionControllers[i].text,
          'explanation': explanationControllers[i].text,
        };
      }),
      'correctAnswer': correctAnswer,
    };
  }
}
