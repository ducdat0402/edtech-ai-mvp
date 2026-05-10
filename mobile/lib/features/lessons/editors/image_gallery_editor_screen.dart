import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:edtech_mobile/theme/theme.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/core/widgets/app_bar_leading_back_home.dart';
import 'quiz_editor_screen.dart';

class ImageGalleryEditorScreen extends StatefulWidget {
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

  const ImageGalleryEditorScreen({
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
  State<ImageGalleryEditorScreen> createState() =>
      _ImageGalleryEditorScreenState();
}

class _ImageGalleryEditorScreenState extends State<ImageGalleryEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imagePicker = ImagePicker();

  List<_ImageCardData> _images = [_ImageCardData()];
  final Map<int, bool> _uploadingImages = {}; // Track upload state per image

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
      final apiService = Provider.of<ApiService>(context, listen: false);
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (!mounted || image == null) return;

      setState(() => _uploadingImages[imageIndex] = true);

      final imageUrl = await apiService.uploadImage(image.path);

      if (mounted) {
        setState(() {
          _images[imageIndex].urlController.text = imageUrl;
          _uploadingImages[imageIndex] = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Tải hình ảnh thành công!'),
            backgroundColor: context.colors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingImages[imageIndex] = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải hình: $e'),
            backgroundColor: context.colors.error,
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
          widget.isEditMode ? 'Sửa bài Image Gallery' : 'Tạo bài Image Gallery',
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
                    // Title
                    TextFormField(
                      controller: _titleController,
                      style: TextStyle(color: sem.textPrimary),
                      decoration: _inputDecoration(context, 'Tiêu đề bài học'),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Nhập tiêu đề' : null,
                    ),
                    const SizedBox(height: 12),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      style: TextStyle(color: sem.textPrimary),
                      decoration: _inputDecoration(context, 'Mô tả'),
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
                          style: TextStyle(
                            color: sem.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _addImage,
                          icon: Icon(Icons.add_photo_alternate,
                              color: sem.brand),
                          label: Text(
                            'Thêm hình',
                            style: TextStyle(color: sem.brand),
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
              decoration: BoxDecoration(
                color: sem.card,
                border: Border(
                  top: BorderSide(color: sem.border.withValues(alpha: 0.65)),
                ),
              ),
              child: ElevatedButton(
                onPressed: _navigateToQuizEditor,
                style: ElevatedButton.styleFrom(
                  backgroundColor: sem.brand,
                  foregroundColor: sem.textOnBrand,
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
    final sem = context.colors;
    final img = _images[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: sem.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: sem.border.withValues(alpha: 0.65)),
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
                style: TextStyle(
                  color: sem.brand,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_images.length > 1)
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      color: sem.error, size: 20),
                  onPressed: () => _removeImage(index),
                ),
            ],
          ),
          Divider(color: sem.border.withValues(alpha: 0.65), height: 20),

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
              if (img.urlController.text.isNotEmpty)
                Container(
                  height: 200,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: sem.border.withValues(alpha: 0.65)),
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
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: context.colors.textOnBrand,
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
                  if (img.urlController.text.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.delete_outline,
                          color: sem.error),
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

          // Description
          TextFormField(
            controller: img.descriptionController,
            style: TextStyle(color: sem.textPrimary),
            decoration: _inputDecoration(context, 'Mô tả hình ảnh'),
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
