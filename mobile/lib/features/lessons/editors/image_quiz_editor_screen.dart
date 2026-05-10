import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:edtech_mobile/theme/theme.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/core/widgets/app_bar_leading_back_home.dart';
import 'quiz_editor_screen.dart';

class ImageQuizEditorScreen extends StatefulWidget {
  final String subjectId;
  final String domainId;
  final String? topicName;
  final String? topicId;
  final String? nodeId;
  final String? initialTitle;
  final String? initialDescription;
  final Map<String, dynamic>? initialLessonData;
  final Map<String, dynamic>? initialEndQuiz;
  final bool isEditMode;
  final Map<String, dynamic>? originalLessonData;
  final Map<String, dynamic>? originalEndQuiz;

  const ImageQuizEditorScreen({
    super.key,
    required this.subjectId,
    required this.domainId,
    this.topicName,
    this.topicId,
    this.nodeId,
    this.initialTitle,
    this.initialDescription,
    this.initialLessonData,
    this.initialEndQuiz,
    this.isEditMode = false,
    this.originalLessonData,
    this.originalEndQuiz,
  });

  @override
  State<ImageQuizEditorScreen> createState() => _ImageQuizEditorScreenState();
}

class _ImageQuizEditorScreenState extends State<ImageQuizEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imagePicker = ImagePicker();

  List<_SlideData> _slides = [_SlideData()];
  final Map<int, bool> _uploadingImages = {}; // Track upload state per slide
  final Set<int> _generatingSlideExplanations = {};

  @override
  void initState() {
    super.initState();
    _prefillData();
  }

  void _prefillData() {
    if (widget.initialTitle != null) {
      _titleController.text = widget.initialTitle!;
    }
    if (widget.initialDescription != null) {
      _descriptionController.text = widget.initialDescription!;
    }

    final data = widget.initialLessonData;
    if (data == null) return;

    final slides = data['slides'] as List?;
    if (slides != null && slides.isNotEmpty) {
      // Dispose existing default slides
      for (final s in _slides) {
        s.dispose();
      }
      _slides = slides.map((s) {
        final slide = s as Map<String, dynamic>;
        final sd = _SlideData();
        sd.imageUrlController.text = slide['imageUrl'] as String? ?? '';
        sd.questionController.text = slide['question'] as String? ?? '';
        sd.hintController.text = slide['hint'] as String? ?? '';
        sd.correctAnswer = slide['correctAnswer'] as int? ?? 0;
        final options = slide['options'] as List? ?? [];
        for (int i = 0; i < options.length && i < 4; i++) {
          final opt = options[i] as Map<String, dynamic>;
          sd.optionControllers[i].text = opt['text'] as String? ?? '';
          sd.explanationControllers[i].text =
              opt['explanation'] as String? ?? '';
        }
        return sd;
      }).toList();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (final slide in _slides) {
      slide.dispose();
    }
    super.dispose();
  }

  Future<void> _pickAndUploadImage(int slideIndex) async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (!mounted || image == null) return;

      setState(() => _uploadingImages[slideIndex] = true);

      final imageUrl = await apiService.uploadImage(image.path);

      if (mounted) {
        setState(() {
          _slides[slideIndex].imageUrlController.text = imageUrl;
          _uploadingImages[slideIndex] = false;
        });

        final sem = context.colors;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Tải hình ảnh thành công!'),
            backgroundColor: sem.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingImages[slideIndex] = false);
        final sem = context.colors;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải hình: $e'),
            backgroundColor: sem.error,
          ),
        );
      }
    }
  }

  void _addSlide() {
    setState(() {
      _slides.add(_SlideData());
    });
  }

  void _removeSlide(int index) {
    if (_slides.length <= 1) return;
    setState(() {
      _slides[index].dispose();
      _slides.removeAt(index);
    });
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _slides.removeAt(oldIndex);
      _slides.insert(newIndex, item);
    });
  }

  Map<String, dynamic> _buildLessonData() {
    return {
      'slides': _slides.map((s) => s.toJson()).toList(),
    };
  }

  void _navigateToQuizEditor() {
    if (!_formKey.currentState!.validate()) return;

    // Validate at least one slide
    if (_slides.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cần ít nhất 1 slide')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizEditorScreen(
          lessonType: 'image_quiz',
          lessonData: _buildLessonData(),
          title: _titleController.text,
          description: _descriptionController.text,
          subjectId: widget.subjectId,
          domainId: widget.domainId,
          topicName: widget.topicName,
          topicId: widget.topicId,
          nodeId: widget.nodeId,
          initialEndQuiz: widget.initialEndQuiz,
          isEditMode: widget.isEditMode,
          originalLessonData:
              widget.originalLessonData ?? widget.initialLessonData,
          originalEndQuiz: widget.originalEndQuiz ?? widget.initialEndQuiz,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context, String label) {
    final sem = context.colors;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: sem.textSecondary),
      filled: true,
      fillColor: sem.card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: sem.border.withValues(alpha: 0.65)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: sem.border.withValues(alpha: 0.65)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: sem.brand),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sem = context.colors;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: sem.card,
        leading: const AppBarLeadingBackAndHome(),
        leadingWidth: 112,
        automaticallyImplyLeading: false,
        title: Text(
          widget.isEditMode ? 'Sửa bài Image Quiz' : 'Tạo bài Image Quiz',
          style: TextStyle(color: sem.textPrimary, fontSize: 18),
        ),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title field
                    TextFormField(
                      controller: _titleController,
                      style: TextStyle(color: sem.textPrimary),
                      decoration:
                          _inputDecoration(context, 'Tiêu đề bài học'),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Nhập tiêu đề' : null,
                    ),
                    const SizedBox(height: 12),

                    // Description field
                    TextFormField(
                      controller: _descriptionController,
                      style: TextStyle(color: sem.textPrimary),
                      decoration: _inputDecoration(context, 'Mô tả'),
                      maxLines: 3,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Nhập mô tả' : null,
                    ),
                    const SizedBox(height: 20),

                    // Slides header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Slides (${_slides.length})',
                          style: TextStyle(
                            color: sem.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _addSlide,
                          icon: Icon(Icons.add, color: sem.brand),
                          label: Text(
                            'Thêm slide',
                            style: TextStyle(color: sem.brand),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Slides list (ReorderableListView)
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _slides.length,
                      onReorder: _onReorder,
                      proxyDecorator: (child, index, animation) {
                        return Material(
                          color: Colors.transparent,
                          child: child,
                        );
                      },
                      itemBuilder: (listContext, index) {
                        return _buildSlideCard(listContext, index,
                            key: ValueKey('slide_$index'));
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Bottom submit button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: sem.card,
                border: Border(
                  top: BorderSide(
                      color: sem.border.withValues(alpha: 0.65)),
                ),
              ),
              child: ElevatedButton(
                onPressed: _navigateToQuizEditor,
                style: ElevatedButton.styleFrom(
                  backgroundColor: sem.brand,
                  foregroundColor: sem.onBrand,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Tiếp tục → Tạo Quiz',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateSlideAIExplanation(int index) async {
    final slide = _slides[index];
    final questionText = slide.questionController.text.trim();

    if (questionText.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Vui lòng nhập câu hỏi (ít nhất 5 ký tự) trước khi tạo giải thích'),
          backgroundColor: context.colors.warning,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    for (int i = 0; i < 4; i++) {
      if (slide.optionControllers[i].text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vui lòng nhập đáp án ${[
              'A',
              'B',
              'C',
              'D'
            ][i]} trước khi tạo giải thích'),
            backgroundColor: context.colors.warning,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        return;
      }
    }

    setState(() => _generatingSlideExplanations.add(index));

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final result = await apiService.generateQuizExplanations(
        question: questionText,
        options: List.generate(
            4, (i) => {'text': slide.optionControllers[i].text.trim()}),
        correctAnswer: slide.correctAnswer,
        context: _titleController.text.trim(),
      );

      if (!mounted) return;

      final validationIssues =
          (result['validationIssues'] as List?)?.cast<String>() ?? [];
      final suggestedCorrectAnswer = result['suggestedCorrectAnswer'] as int?;
      final suggestedCorrectReason =
          result['suggestedCorrectReason'] as String?;
      final explanations =
          (result['explanations'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      // Show validation issues
      if (validationIssues.isNotEmpty) {
        final shouldContinue =
            await _showValidationIssuesDialog(validationIssues);
        if (!mounted) return;
        if (shouldContinue != true) {
          setState(() => _generatingSlideExplanations.remove(index));
          return;
        }
      }

      // Show answer mismatch
      if (suggestedCorrectAnswer != null &&
          suggestedCorrectAnswer != slide.correctAnswer) {
        final shouldChange = await _showAnswerMismatchDialog(
          currentAnswer: slide.correctAnswer,
          suggestedAnswer: suggestedCorrectAnswer,
          reason: suggestedCorrectReason ?? '',
        );
        if (!mounted) return;
        if (shouldChange == true) {
          setState(() {
            slide.correctAnswer = suggestedCorrectAnswer;
          });
        }
      }

      // Fill in explanations
      for (int i = 0; i < explanations.length && i < 4; i++) {
        final explanation = explanations[i]['explanation'] as String? ?? '';
        if (explanation.isNotEmpty) {
          slide.explanationControllers[i].text = explanation;
        }
      }

      if (mounted) {
        final sem = context.colors;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã tạo lời giải thích thành công!'),
            backgroundColor: sem.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      String errorMsg = 'Lỗi tạo giải thích';
      if (e is DioException && e.response?.data != null) {
        final data = e.response!.data;
        final msg = data is Map ? (data['message'] ?? '') : data.toString();
        if (msg.toString().contains('kim cương')) {
          _showDiamondInsufficientDialog(msg.toString());
          setState(() => _generatingSlideExplanations.remove(index));
          return;
        }
        errorMsg = msg.toString();
      } else {
        errorMsg = e.toString();
      }
      if (!mounted) return;
      final semErr = context.colors;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: semErr.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) setState(() => _generatingSlideExplanations.remove(index));
    }
  }

  void _showDiamondInsufficientDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) {
        final sem = ctx.colors;
        return AlertDialog(
          backgroundColor: sem.card,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Text('💎', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text('Không đủ kim cương',
                  style:
                      TextStyle(color: sem.textPrimary, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message,
                  style:
                      TextStyle(color: sem.textSecondary, fontSize: 14)),
              const SizedBox(height: 12),
              Text(
                'Bạn có thể mua thêm kim cương trong phần Cửa hàng.',
                style: TextStyle(color: sem.textTertiary, fontSize: 13),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Đóng',
                  style: TextStyle(color: sem.textSecondary)),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                context.push('/payment');
              },
              icon: const Text('💎', style: TextStyle(fontSize: 16)),
              label: const Text('Mua kim cương'),
              style: ElevatedButton.styleFrom(
                backgroundColor: sem.brand,
                foregroundColor: sem.onBrand,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _showValidationIssuesDialog(List<String> issues) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        final sem = ctx.colors;
        return AlertDialog(
          backgroundColor: sem.card,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: sem.warning),
              const SizedBox(width: 8),
              Text('Phát hiện vấn đề',
                  style: TextStyle(color: sem.textPrimary, fontSize: 17)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: issues
                .map((issue) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• ',
                              style: TextStyle(
                                  color: sem.warning, fontSize: 14)),
                          Expanded(
                              child: Text(issue,
                                  style: TextStyle(
                                      color: sem.textSecondary,
                                      fontSize: 14))),
                        ],
                      ),
                    ))
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Sửa lỗi',
                  style: TextStyle(color: sem.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: sem.warning,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Tiếp tục',
                  style: TextStyle(color: sem.textOnBrand)),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _showAnswerMismatchDialog({
    required int currentAnswer,
    required int suggestedAnswer,
    required String reason,
  }) {
    final labels = ['A', 'B', 'C', 'D'];
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        final sem = ctx.colors;
        return AlertDialog(
          backgroundColor: sem.card,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.error_outline, color: sem.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Cảnh báo: Đáp án có thể sai',
                    style:
                        TextStyle(color: sem.textPrimary, fontSize: 17)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: TextStyle(
                      color: sem.textSecondary, fontSize: 14),
                  children: [
                    const TextSpan(text: 'Bạn đánh dấu: '),
                    TextSpan(
                        text: labels[currentAnswer],
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: sem.textPrimary)),
                    const TextSpan(text: ' là đúng'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                      color: sem.textSecondary, fontSize: 14),
                  children: [
                    const TextSpan(text: 'AI đề xuất: '),
                    TextSpan(
                        text: labels[suggestedAnswer],
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: sem.gold)),
                    const TextSpan(text: ' mới đúng'),
                  ],
                ),
              ),
              if (reason.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: sem.cardMuted,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb_outline,
                          color: sem.gold, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(reason,
                              style: TextStyle(
                                  color: sem.textSecondary, fontSize: 13))),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Giữ ${labels[currentAnswer]}',
                  style: TextStyle(color: sem.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: sem.gold,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Đổi sang ${labels[suggestedAnswer]}',
                  style: TextStyle(
                      color: Theme.of(ctx).colorScheme.onSecondary)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSlideCard(BuildContext context, int index, {Key? key}) {
    final slide = _slides[index];
    final labels = ['A', 'B', 'C', 'D'];
    final sem = context.colors;

    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: sem.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: sem.border.withValues(alpha: 0.65)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Slide header
          Row(
            children: [
              Icon(Icons.drag_handle,
                  color: sem.textTertiary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Slide ${index + 1}',
                style: TextStyle(
                  color: sem.brand,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // AI Explain button
              _generatingSlideExplanations.contains(index)
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: sem.gold,
                        ),
                      ),
                    )
                  : InkWell(
                      onTap: () => _generateSlideAIExplanation(index),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: sem.gold.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: sem.gold.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome,
                                color: sem.gold, size: 14),
                            const SizedBox(width: 4),
                            Text('AI 5💎',
                                style: TextStyle(
                                    color: sem.gold,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
              if (_slides.length > 1)
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      color: sem.error, size: 20),
                  onPressed: () => _removeSlide(index),
                ),
            ],
          ),
          Divider(
              color: sem.border.withValues(alpha: 0.65), height: 20),

          // Image upload/preview
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hình ảnh',
                style: TextStyle(
                  color: sem.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),

              // Show image preview if URL exists
              if (slide.imageUrlController.text.isNotEmpty)
                Container(
                  height: 150,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: sem.border.withValues(alpha: 0.65)),
                    image: DecorationImage(
                      image: NetworkImage(slide.imageUrlController.text),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

              // Upload/Change button
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _uploadingImages[index] == true
                          ? null
                          : () => _pickAndUploadImage(index),
                      icon: _uploadingImages[index] == true
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: context.colors.textOnBrand,
                              ),
                            )
                          : Icon(
                              slide.imageUrlController.text.isEmpty
                                  ? Icons.add_photo_alternate_outlined
                                  : Icons.change_circle_outlined,
                              size: 20,
                            ),
                      label: Text(
                        _uploadingImages[index] == true
                            ? 'Đang tải...'
                            : slide.imageUrlController.text.isEmpty
                                ? 'Chọn hình ảnh'
                                : 'Đổi hình ảnh',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: sem.cardMuted,
                        foregroundColor: sem.brand,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: sem.brand),
                        ),
                      ),
                    ),
                  ),
                  if (slide.imageUrlController.text.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.delete_outline,
                          color: sem.error),
                      onPressed: () {
                        setState(() {
                          slide.imageUrlController.clear();
                        });
                      },
                    ),
                  ],
                ],
              ),

              // Validation message
              if (slide.imageUrlController.text.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 12),
                  child: Text(
                    'Vui lòng chọn hình ảnh',
                    style: TextStyle(color: sem.error, fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Question
          TextFormField(
            controller: slide.questionController,
            style: TextStyle(color: sem.textPrimary),
            decoration: _inputDecoration(context, 'Câu hỏi'),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Nhập câu hỏi' : null,
          ),
          const SizedBox(height: 16),

          // Options
          Text(
            'Các lựa chọn',
            style: TextStyle(
              color: sem.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(4, (optIdx) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Radio<int>(
                        value: optIdx,
                        groupValue: slide.correctAnswer,
                        onChanged: (v) {
                          setState(() {
                            slide.correctAnswer = v ?? 0;
                          });
                        },
                        activeColor: sem.success,
                        fillColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return sem.success;
                          }
                          return sem.textTertiary;
                        }),
                      ),
                      Text(
                        labels[optIdx],
                        style: TextStyle(
                          color: sem.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: slide.optionControllers[optIdx],
                          style: TextStyle(
                              color: sem.textPrimary, fontSize: 14),
                          decoration: _inputDecoration(
                              context, 'Đáp án ${labels[optIdx]}'),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Nhập đáp án'
                              : null,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 56, top: 6),
                    child: TextFormField(
                      controller: slide.explanationControllers[optIdx],
                      style: TextStyle(
                          color: sem.textSecondary, fontSize: 13),
                      decoration:
                          _inputDecoration(context, 'Giải thích (tuỳ chọn)'),
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 8),

          // Hint
          TextFormField(
            controller: slide.hintController,
            style: TextStyle(color: sem.textPrimary),
            decoration: _inputDecoration(context, 'Gợi ý (tuỳ chọn)'),
          ),
        ],
      ),
    );
  }
}

/// Internal data class for a single slide
class _SlideData {
  final imageUrlController = TextEditingController();
  final questionController = TextEditingController();
  final List<TextEditingController> optionControllers =
      List.generate(4, (_) => TextEditingController());
  final List<TextEditingController> explanationControllers =
      List.generate(4, (_) => TextEditingController());
  final hintController = TextEditingController();
  int correctAnswer = 0;

  void dispose() {
    imageUrlController.dispose();
    questionController.dispose();
    for (final c in optionControllers) {
      c.dispose();
    }
    for (final c in explanationControllers) {
      c.dispose();
    }
    hintController.dispose();
  }

  Map<String, dynamic> toJson() {
    return {
      'imageUrl': imageUrlController.text,
      'question': questionController.text,
      'options': List.generate(4, (i) {
        return {
          'text': optionControllers[i].text,
          'explanation': explanationControllers[i].text,
        };
      }),
      'correctAnswer': correctAnswer,
      'hint': hintController.text,
    };
  }
}
