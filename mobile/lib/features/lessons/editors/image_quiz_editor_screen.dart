import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:edtech_mobile/theme/colors.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'quiz_editor_screen.dart';

class ImageQuizEditorScreen extends StatefulWidget {
  final String subjectId;
  final String domainId;
  final String? topicName;
  final String? topicId;
  final String? nodeId;
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
  Map<int, bool> _uploadingImages = {}; // Track upload state per slide

  @override
  void initState() {
    super.initState();
    _prefillData();
  }

  void _prefillData() {
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
          sd.explanationControllers[i].text = opt['explanation'] as String? ?? '';
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
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _uploadingImages[slideIndex] = true);

      final apiService = Provider.of<ApiService>(context, listen: false);
      final imageUrl = await apiService.uploadImage(image.path);

      if (mounted) {
        setState(() {
          _slides[slideIndex].imageUrlController.text = imageUrl;
          _uploadingImages[slideIndex] = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tải hình ảnh thành công!'),
            backgroundColor: AppColors.successGlow,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingImages[slideIndex] = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải hình: $e'),
            backgroundColor: AppColors.errorNeon,
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
          originalLessonData: widget.originalLessonData ?? widget.initialLessonData,
          originalEndQuiz: widget.originalEndQuiz ?? widget.initialEndQuiz,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, {int? maxLines}) {
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
          widget.isEditMode ? 'Sửa bài Image Quiz' : 'Tạo bài Image Quiz',
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 18),
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
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: _inputDecoration('Tiêu đề bài học'),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Nhập tiêu đề' : null,
                    ),
                    const SizedBox(height: 12),

                    // Description field
                    TextFormField(
                      controller: _descriptionController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: _inputDecoration('Mô tả'),
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
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _addSlide,
                          icon: const Icon(Icons.add, color: AppColors.purpleNeon),
                          label: const Text(
                            'Thêm slide',
                            style: TextStyle(color: AppColors.purpleNeon),
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
                      itemBuilder: (context, index) {
                        return _buildSlideCard(index, key: ValueKey('slide_$index'));
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
              decoration: const BoxDecoration(
                color: AppColors.bgSecondary,
                border: Border(
                  top: BorderSide(color: AppColors.borderPrimary),
                ),
              ),
              child: ElevatedButton(
                onPressed: _navigateToQuizEditor,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purpleNeon,
                  foregroundColor: Colors.white,
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

  Widget _buildSlideCard(int index, {Key? key}) {
    final slide = _slides[index];
    final labels = ['A', 'B', 'C', 'D'];

    return Container(
      key: key,
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
          // Slide header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.drag_handle, color: AppColors.textTertiary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Slide ${index + 1}',
                    style: const TextStyle(
                      color: AppColors.purpleNeon,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (_slides.length > 1)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.errorNeon, size: 20),
                  onPressed: () => _removeSlide(index),
                ),
            ],
          ),
          const Divider(color: AppColors.borderPrimary, height: 20),

          // Image upload/preview
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hình ảnh',
                style: TextStyle(
                  color: AppColors.textSecondary,
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
                    border: Border.all(color: AppColors.borderPrimary),
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
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
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
                        backgroundColor: AppColors.bgTertiary,
                        foregroundColor: AppColors.purpleNeon,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: AppColors.purpleNeon),
                        ),
                      ),
                    ),
                  ),
                  if (slide.imageUrlController.text.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.errorNeon),
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
                const Padding(
                  padding: EdgeInsets.only(top: 8, left: 12),
                  child: Text(
                    'Vui lòng chọn hình ảnh',
                    style: TextStyle(color: AppColors.errorNeon, fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Question
          TextFormField(
            controller: slide.questionController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: _inputDecoration('Câu hỏi'),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Nhập câu hỏi' : null,
          ),
          const SizedBox(height: 16),

          // Options
          const Text(
            'Các lựa chọn',
            style: TextStyle(
              color: AppColors.textSecondary,
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
                          controller: slide.optionControllers[optIdx],
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                          decoration: _inputDecoration('Đáp án ${labels[optIdx]}'),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Nhập đáp án' : null,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 56, top: 6),
                    child: TextFormField(
                      controller: slide.explanationControllers[optIdx],
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      decoration: _inputDecoration('Giải thích (tuỳ chọn)'),
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
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: _inputDecoration('Gợi ý (tuỳ chọn)'),
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
