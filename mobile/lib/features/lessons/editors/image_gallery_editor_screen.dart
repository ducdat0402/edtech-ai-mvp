import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:edtech_mobile/theme/colors.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'quiz_editor_screen.dart';

class ImageGalleryEditorScreen extends StatefulWidget {
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

  const ImageGalleryEditorScreen({
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
  State<ImageGalleryEditorScreen> createState() =>
      _ImageGalleryEditorScreenState();
}

class _ImageGalleryEditorScreenState extends State<ImageGalleryEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imagePicker = ImagePicker();

  List<_ImageCardData> _images = [_ImageCardData()];
  Map<int, bool> _uploadingImages = {}; // Track upload state per image

  @override
  void initState() {
    super.initState();
    _prefillData();
  }

  void _prefillData() {
    final data = widget.initialLessonData;
    if (data == null) return;

    final images = data['images'] as List?;
    if (images != null && images.isNotEmpty) {
      for (final img in _images) {
        img.dispose();
      }
      _images = images.map((img) {
        final m = img as Map<String, dynamic>;
        final card = _ImageCardData();
        card.urlController.text = m['url'] as String? ?? '';
        card.descriptionController.text = m['description'] as String? ?? '';
        return card;
      }).toList();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (final img in _images) {
      img.dispose();
    }
    super.dispose();
  }

  Future<void> _pickAndUploadImage(int imageIndex) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _uploadingImages[imageIndex] = true);

      final apiService = Provider.of<ApiService>(context, listen: false);
      final imageUrl = await apiService.uploadImage(image.path);

      if (mounted) {
        setState(() {
          _images[imageIndex].urlController.text = imageUrl;
          _uploadingImages[imageIndex] = false;
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
        setState(() => _uploadingImages[imageIndex] = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải hình: $e'),
            backgroundColor: AppColors.errorNeon,
          ),
        );
      }
    }
  }

  void _addImage() {
    setState(() {
      _images.add(_ImageCardData());
    });
  }

  void _removeImage(int index) {
    if (_images.length <= 1) return;
    setState(() {
      _images[index].dispose();
      _images.removeAt(index);
    });
  }

  Map<String, dynamic> _buildLessonData() {
    return {
      'images': _images.map((img) => img.toJson()).toList(),
    };
  }

  void _navigateToQuizEditor() {
    if (!_formKey.currentState!.validate()) return;

    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cần ít nhất 1 hình ảnh')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizEditorScreen(
          lessonType: 'image_gallery',
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
          widget.isEditMode ? 'Sửa bài Image Gallery' : 'Tạo bài Image Gallery',
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
                    // Title
                    TextFormField(
                      controller: _titleController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: _inputDecoration('Tiêu đề bài học'),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Nhập tiêu đề' : null,
                    ),
                    const SizedBox(height: 12),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: _inputDecoration('Mô tả'),
                      maxLines: 3,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Nhập mô tả' : null,
                    ),
                    const SizedBox(height: 20),

                    // Images header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Hình ảnh (${_images.length})',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _addImage,
                          icon: const Icon(Icons.add_photo_alternate,
                              color: AppColors.purpleNeon),
                          label: const Text(
                            'Thêm hình',
                            style: TextStyle(color: AppColors.purpleNeon),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Image cards
                    ...List.generate(_images.length, (index) {
                      return _buildImageCard(index);
                    }),
                  ],
                ),
              ),
            ),

            // Bottom button
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

  Widget _buildImageCard(int index) {
    final img = _images[index];

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
                'Hình ${index + 1}',
                style: const TextStyle(
                  color: AppColors.purpleNeon,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_images.length > 1)
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.errorNeon, size: 20),
                  onPressed: () => _removeImage(index),
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
              if (img.urlController.text.isNotEmpty)
                Container(
                  height: 200,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderPrimary),
                    image: DecorationImage(
                      image: NetworkImage(img.urlController.text),
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
                              img.urlController.text.isEmpty
                                  ? Icons.add_photo_alternate_outlined
                                  : Icons.change_circle_outlined,
                              size: 20,
                            ),
                      label: Text(
                        _uploadingImages[index] == true
                            ? 'Đang tải...'
                            : img.urlController.text.isEmpty
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
                  if (img.urlController.text.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.errorNeon),
                      onPressed: () {
                        setState(() {
                          img.urlController.clear();
                        });
                      },
                    ),
                  ],
                ],
              ),
              
              // Validation message
              if (img.urlController.text.isEmpty)
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

          // Description
          TextFormField(
            controller: img.descriptionController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: _inputDecoration('Mô tả hình ảnh'),
            maxLines: 3,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Nhập mô tả hình ảnh' : null,
          ),
        ],
      ),
    );
  }
}

class _ImageCardData {
  final urlController = TextEditingController();
  final descriptionController = TextEditingController();

  void dispose() {
    urlController.dispose();
    descriptionController.dispose();
  }

  Map<String, dynamic> toJson() {
    return {
      'url': urlController.text,
      'description': descriptionController.text,
    };
  }
}
