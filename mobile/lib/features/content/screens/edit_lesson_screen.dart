import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/core/config/api_config.dart';
import 'package:edtech_mobile/features/admin/widgets/comparison_dialog.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';

class EditLessonScreen extends StatefulWidget {
  final String contentItemId;
  final Map<String, dynamic>? initialData;
  final Map<String, dynamic>? originalData; // Original/current version for comparison

  const EditLessonScreen({
    super.key,
    required this.contentItemId,
    this.initialData,
    this.originalData, // Current version data (for comparison when editing from version snapshot)
  });

  @override
  State<EditLessonScreen> createState() => _EditLessonScreenState();
}

class _EditLessonScreenState extends State<EditLessonScreen> {
  final _titleController = TextEditingController();
  final quill.QuillController _quillController = quill.QuillController.basic();
  final ImagePicker _picker = ImagePicker();
  
  List<String> _imageUrls = [];
  String? _videoUrl;
  String? _videoThumbnail;
  String? _videoDuration;
  bool _isPreviewMode = false;
  bool _isSubmitting = false;
  
  // Quiz data
  bool _isQuiz = false;
  final _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [];
  int? _correctAnswerIndex;
  final _explanationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    // Handle combined data from version history (contains both initialData and originalData)
    Map<String, dynamic>? data = widget.initialData;
    
    // Check if initialData contains combined data structure from version history
    if (widget.initialData != null && widget.initialData!.containsKey('initialData')) {
      // Combined structure: {initialData: {...}, originalData: {...}}
      data = widget.initialData!['initialData'] as Map<String, dynamic>?;
    }
    
    if (data != null) {
      _titleController.text = data['title'] ?? '';
      
      // Check if this is a quiz
      final format = data['format'] as String?;
      final quizData = data['quizData'] as Map<String, dynamic>?;
      _isQuiz = format == 'quiz' || quizData != null;
      
      if (_isQuiz && quizData != null) {
        // Load quiz data
        _questionController.text = quizData['question'] ?? '';
        final options = quizData['options'] as List<dynamic>? ?? [];
        _optionControllers.clear();
        for (var option in options) {
          final controller = TextEditingController(text: option.toString());
          _optionControllers.add(controller);
        }
        // Ensure at least 2 options
        while (_optionControllers.length < 2) {
          _optionControllers.add(TextEditingController());
        }
        _correctAnswerIndex = quizData['correctAnswer'] as int?;
        _explanationController.text = quizData['explanation'] ?? '';
      } else {
        // Load rich content if available
        if (data['richContent'] != null) {
          try {
            // richContent can be List (Delta format) or Map
            final richContentData = data['richContent'];
            if (richContentData is List) {
              final delta = Delta.fromJson(richContentData);
              _quillController.document = quill.Document.fromDelta(delta);
            } else if (richContentData is Map) {
              final delta = Delta.fromJson([richContentData]);
              _quillController.document = quill.Document.fromDelta(delta);
            } else {
              // Fallback to plain text
              _quillController.document = quill.Document()..insert(0, richContentData.toString());
            }
          } catch (e) {
            // If richContent is string, convert to plain text
            if (data['richContent'] is String) {
              _quillController.document = quill.Document()..insert(0, data['richContent']);
            }
          }
        } else if (data['content'] != null) {
          _quillController.document = quill.Document()..insert(0, data['content']);
        }
      }

      // Load images
      if (data['media'] != null) {
        final media = data['media'] as Map<String, dynamic>;
        if (media['imageUrls'] != null) {
          _imageUrls = List<String>.from(media['imageUrls']);
        } else if (media['imageUrl'] != null) {
          _imageUrls = [media['imageUrl']];
        }
        
        if (media['videoUrl'] != null) {
          _videoUrl = media['videoUrl'];
          _loadVideoThumbnail(media['videoUrl']!);
        }
      }
    }
  }

  Future<void> _loadVideoThumbnail(String videoUrl) async {
    try {
      // Generate thumbnail from video URL
      // Note: For remote URLs, video_thumbnail may not work. Consider using a placeholder.
      if (videoUrl.startsWith('http://') || videoUrl.startsWith('https://')) {
        // For remote videos, we'll use a placeholder or fetch thumbnail from backend
        // For now, skip thumbnail generation for remote URLs
        return;
      }
      
      final thumbnail = await VideoThumbnail.thumbnailFile(
        video: videoUrl,
        thumbnailPath: (await Directory.systemTemp).path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 640,
        quality: 75,
      );
      
      if (thumbnail != null) {
        setState(() {
          _videoThumbnail = thumbnail;
        });
      }
    } catch (e) {
      print('Error generating video thumbnail: $e');
    }
  }

  Future<void> _pickAndCropImage() async {
    if (_imageUrls.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tối đa 5 ảnh')),
      );
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      String imagePath = image.path;
      
      // Only crop on mobile platforms (Android/iOS), skip on Windows/Web
      // image_cropper doesn't work well on Windows desktop
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        try {
          // Crop image to 4:3 on mobile
          final croppedFile = await ImageCropper().cropImage(
            sourcePath: image.path,
            aspectRatio: const CropAspectRatio(ratioX: 4, ratioY: 3),
            uiSettings: [
              AndroidUiSettings(
                toolbarTitle: 'Cắt ảnh',
                toolbarColor: Colors.blue,
                toolbarWidgetColor: Colors.white,
                initAspectRatio: CropAspectRatioPreset.ratio4x3,
                lockAspectRatio: true,
              ),
              IOSUiSettings(
                title: 'Cắt ảnh',
                aspectRatioLockEnabled: true,
                resetAspectRatioEnabled: false,
              ),
            ],
          );
          
          if (croppedFile != null) {
            imagePath = croppedFile.path;
          } else {
            // User cancelled cropping, return early
            return;
          }
        } catch (e) {
          // If cropping fails, use original image
          print('Image cropping failed, using original image: $e');
          // Continue with original image (imagePath already set)
        }
      } else {
        // On Windows/Web, use original image without cropping
        // Backend will handle normalization via Cloudinary
        print('Skipping crop on desktop/web, backend will normalize image');
      }

      setState(() {
        _isSubmitting = true;
      });

      try {
        final apiService = Provider.of<ApiService>(context, listen: false);
        final result = await apiService.uploadImageForEdit(imagePath);
        
        setState(() {
          _imageUrls.add(result['imageUrl'] as String);
          _isSubmitting = false;
        });
      } catch (e) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi upload ảnh: $e')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi chọn ảnh: $e')),
      );
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video == null) return;

      // Validate video size (max 100MB)
      final file = File(video.path);
      final fileSize = await file.length();
      const maxSize = 100 * 1024 * 1024;
      
      if (fileSize > maxSize) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Video quá lớn. Kích thước tối đa: 100MB. Video của bạn: ${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB',
            ),
          ),
        );
        return;
      }

      setState(() {
        _isSubmitting = true;
      });

      try {
        final apiService = Provider.of<ApiService>(context, listen: false);
        final result = await apiService.uploadVideoForEdit(video.path);
        
        setState(() {
          _videoUrl = result['videoUrl'] as String;
          _isSubmitting = false;
        });
        
        // Generate thumbnail
        _loadVideoThumbnail(_videoUrl!);
      } catch (e) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi upload video: $e')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi chọn video: $e')),
      );
    }
  }

  Future<void> _handleSubmit() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tiêu đề bài học')),
      );
      return;
    }

    // Validate quiz data if it's a quiz
    if (_isQuiz) {
      if (_questionController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng nhập câu hỏi')),
        );
        return;
      }
      
      final validOptions = _optionControllers.where((c) => c.text.trim().isNotEmpty).toList();
      if (validOptions.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng nhập ít nhất 2 đáp án')),
        );
        return;
      }
      
      if (_correctAnswerIndex == null || _correctAnswerIndex! < 0 || _correctAnswerIndex! >= validOptions.length) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn đáp án đúng')),
        );
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      
      Map<String, dynamic>? quizData;
      dynamic richContent;
      
      if (_isQuiz) {
        // Build quiz data
        final validOptions = _optionControllers.where((c) => c.text.trim().isNotEmpty).map((c) => c.text.trim()).toList();
        quizData = {
          'question': _questionController.text.trim(),
          'options': validOptions,
          'correctAnswer': _correctAnswerIndex!,
          'explanation': _explanationController.text.trim(),
        };
      } else {
        // Convert quill document to JSON (Delta format)
        final delta = _quillController.document.toDelta();
        richContent = delta.toJson(); // This returns List<Map<String, dynamic>>
      }

      await apiService.submitLessonEdit(
        contentItemId: widget.contentItemId,
        title: _titleController.text.trim(),
        richContent: richContent,
        imageUrls: _imageUrls.isNotEmpty ? _imageUrls : null,
        videoUrl: _videoUrl,
        quizData: quizData,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã đóng góp bài học thành công! Bài đóng góp của bạn đang chờ được duyệt.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showComparisonDialog() async {
    // Use originalData (current version) if available, otherwise use initialData
    Map<String, dynamic> original;
    
    // Check if initialData contains combined data structure from version history
    Map<String, dynamic>? originalData = widget.originalData;
    Map<String, dynamic>? initialData = widget.initialData;
    
    if (widget.initialData != null && widget.initialData!.containsKey('originalData')) {
      // Combined data structure from version history
      originalData = widget.initialData!['originalData'] as Map<String, dynamic>?;
      initialData = widget.initialData!['initialData'] as Map<String, dynamic>?;
    }
    
    if (originalData != null) {
      // Use current version data for comparison (when editing from version snapshot)
      original = {
        'title': originalData['title'] ?? '',
        'content': originalData['content'] ?? '',
        'richContent': originalData['richContent'] ?? null,
        'media': originalData['media'] ?? null,
        'quizData': originalData['quizData'] ?? null,
      };
    } else if (initialData != null) {
      // Fallback to initialData if originalData not provided
      original = {
        'title': initialData['title'] ?? '',
        'content': initialData['content'] ?? '',
        'richContent': initialData['richContent'] ?? null,
        'media': initialData['media'] ?? null,
        'quizData': initialData['quizData'] ?? null,
      };
    } else {
      // Fetch current content if neither provided
      try {
        final apiService = Provider.of<ApiService>(context, listen: false);
        final currentContent = await apiService.getContentDetail(widget.contentItemId);
        original = {
          'title': currentContent['title'] ?? '',
          'content': currentContent['content'] ?? '',
          'richContent': currentContent['richContent'] ?? null,
          'media': currentContent['media'] ?? null,
          'quizData': currentContent['quizData'] ?? null,
        };
      } catch (e) {
        original = {
          'title': '',
          'content': '',
          'richContent': null,
          'media': null,
          'quizData': null,
        };
      }
    }

    // Build comparison data from current form state
    final delta = _quillController.document.toDelta();
    final richContent = delta.toJson();
    
    Map<String, dynamic>? quizData;
    if (_isQuiz) {
      final validOptions = _optionControllers.where((c) => c.text.trim().isNotEmpty).map((c) => c.text.trim()).toList();
      quizData = {
        'question': _questionController.text.trim(),
        'options': validOptions,
        'correctAnswer': _correctAnswerIndex,
        'explanation': _explanationController.text.trim(),
      };
    }

    final proposed = {
      'title': _titleController.text.trim(),
      'content': '', // Not used for rich content
      'richContent': _isQuiz ? null : richContent,
      'media': {
        'imageUrls': _imageUrls,
        'videoUrl': _videoUrl,
      },
      'quizData': quizData,
    };

    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => ComparisonDialog(
        comparison: {
          'original': original,
          'proposed': proposed,
        },
      ),
    );
  }

  String _buildFullUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    final baseUrl = ApiConfig.baseUrl.replaceAll('/api/v1', '');
    return '$baseUrl$url';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quillController.dispose();
    _questionController.dispose();
    _explanationController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
        title: const Text(
          'Chỉnh sửa Bài học',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          // Nút so sánh
          IconButton(
            icon: const Icon(Icons.compare_arrows, color: Colors.black),
            onPressed: () => _showComparisonDialog(),
            tooltip: 'Xem so sánh',
          ),
          // Nút preview/edit toggle
          IconButton(
            icon: Icon(
              _isPreviewMode ? Icons.edit : Icons.visibility,
              color: Colors.black,
            ),
            onPressed: () {
              setState(() {
                _isPreviewMode = !_isPreviewMode;
              });
            },
          ),
        ],
      ),
      body: _isPreviewMode ? _buildPreviewView() : _buildEditView(),
    );
  }

  Widget _buildEditView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TIÊU ĐỀ BÀI HỌC
          _buildSectionLabel('TIÊU ĐỀ BÀI HỌC'),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              hintText: 'Kỹ thuật Ném 3 Điểm cơ bản',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 24),

          // NỘI DUNG CHI TIẾT hoặc QUIZ
          if (_isQuiz) ...[
            // QUIZ EDITOR
            _buildSectionLabel('CÂU HỎI QUIZ'),
            const SizedBox(height: 8),
            TextField(
              controller: _questionController,
              decoration: InputDecoration(
                hintText: 'Nhập câu hỏi...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            
            // ĐÁP ÁN
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionLabel('ĐÁP ÁN'),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _optionControllers.add(TextEditingController());
                    });
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Thêm đáp án'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...List.generate(_optionControllers.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    // Radio button for correct answer
                    Radio<int>(
                      value: index,
                      groupValue: _correctAnswerIndex,
                      onChanged: (value) {
                        setState(() {
                          _correctAnswerIndex = value;
                        });
                      },
                    ),
                    // Option text field
                    Expanded(
                      child: TextField(
                        controller: _optionControllers[index],
                        decoration: InputDecoration(
                          hintText: 'Đáp án ${index + 1}',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                    ),
                    // Delete button
                    if (_optionControllers.length > 2)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _optionControllers[index].dispose();
                            _optionControllers.removeAt(index);
                            if (_correctAnswerIndex == index) {
                              _correctAnswerIndex = null;
                            } else if (_correctAnswerIndex != null && _correctAnswerIndex! > index) {
                              _correctAnswerIndex = _correctAnswerIndex! - 1;
                            }
                          });
                        },
                      ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),
            
            // GIẢI THÍCH
            _buildSectionLabel('GIẢI THÍCH ĐÁP ÁN'),
            const SizedBox(height: 8),
            TextField(
              controller: _explanationController,
              decoration: InputDecoration(
                hintText: 'Giải thích tại sao đáp án này đúng...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
          ] else ...[
            // RICH CONTENT EDITOR
            _buildSectionLabel('NỘI DUNG CHI TIẾT'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Rich text editor toolbar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: quill.QuillToolbar.simple(
                      configurations: quill.QuillSimpleToolbarConfigurations(
                        controller: _quillController,
                        sharedConfigurations: const quill.QuillSharedConfigurations(),
                      ),
                    ),
                  ),
                  // Rich text editor content
                  Container(
                    constraints: const BoxConstraints(minHeight: 200),
                    padding: const EdgeInsets.all(12),
                    child: quill.QuillEditor.basic(
                      configurations: quill.QuillEditorConfigurations(
                        controller: _quillController,
                        placeholder: 'Nhập nội dung chi tiết...',
                        sharedConfigurations: const quill.QuillSharedConfigurations(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // HÌNH ẢNH MINH HỌA
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionLabel('HÌNH ẢNH MINH HỌA'),
              Text(
                '${_imageUrls.length}/5 ảnh',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _imageUrls.length + 1,
              itemBuilder: (context, index) {
                if (index == _imageUrls.length) {
                  // Add image button
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: _isSubmitting ? null : _pickAndCropImage,
                      child: Container(
                        width: 100,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.green, style: BorderStyle.solid, width: 2),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.green.shade50,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate, color: Colors.green.shade700, size: 32),
                            const SizedBox(height: 4),
                            const Text(
                              'Thêm ảnh',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                
                // Image thumbnail
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _buildFullUrl(_imageUrls[index]),
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 100,
                              height: 100,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _imageUrls.removeAt(index);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // VIDEO HƯỚNG DẪN
          _buildSectionLabel('VIDEO HƯỚNG DẪN'),
          const SizedBox(height: 8),
          if (_videoUrl != null) ...[
            // Video preview
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _videoThumbnail != null
                      ? Image.file(
                          File(_videoThumbnail!),
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: double.infinity,
                          height: 200,
                          color: Colors.black,
                          child: const Center(
                            child: Icon(Icons.video_library, color: Colors.white, size: 48),
                          ),
                        ),
                ),
                // Play button overlay
                Positioned.fill(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),
                ),
                // Duration badge
                if (_videoDuration != null)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _videoDuration!,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Video title/URL
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _videoUrl!,
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _videoUrl = null;
                        _videoThumbnail = null;
                        _videoDuration = null;
                      });
                    },
                  ),
                ],
              ),
            ),
          ] else ...[
            // Upload video button
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _pickVideo,
              icon: const Icon(Icons.video_library),
              label: const Text('Tải video lên'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
          const SizedBox(height: 32),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Đóng góp',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title preview
          Text(
            _titleController.text.isEmpty ? 'Tiêu đề bài học' : _titleController.text,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Quiz or Rich content preview
          if (_isQuiz) ...[
            // Quiz preview
            Text(
              _questionController.text.isEmpty ? 'Câu hỏi quiz' : _questionController.text,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            ...List.generate(_optionControllers.length, (index) {
              final optionText = _optionControllers[index].text.trim();
              if (optionText.isEmpty) return const SizedBox.shrink();
              
              final isCorrect = index == _correctAnswerIndex;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isCorrect ? Colors.green.shade100 : Colors.grey.shade100,
                    border: Border.all(
                      color: isCorrect ? Colors.green : Colors.grey.shade300,
                      width: isCorrect ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isCorrect ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: isCorrect ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          optionText,
                          style: TextStyle(
                            fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (isCorrect)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Đúng',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
            if (_explanationController.text.trim().isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Giải thích:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_explanationController.text.trim()),
                  ],
                ),
              ),
            ],
          ] else ...[
            // Rich content preview - use IgnorePointer to prevent interaction
            IgnorePointer(
              child: quill.QuillEditor.basic(
                configurations: quill.QuillEditorConfigurations(
                  controller: _quillController,
                  sharedConfigurations: const quill.QuillSharedConfigurations(),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Images preview
          if (_imageUrls.isNotEmpty) ...[
            const Text(
              'Hình ảnh minh họa',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _imageUrls.length,
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _buildFullUrl(_imageUrls[index]),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],

          // Video preview
          if (_videoUrl != null) ...[
            const Text(
              'Video hướng dẫn',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _videoThumbnail != null
                      ? Image.file(
                          File(_videoThumbnail!),
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: double.infinity,
                          height: 200,
                          color: Colors.black,
                          child: const Center(
                            child: Icon(Icons.video_library, color: Colors.white, size: 48),
                          ),
                        ),
                ),
                Positioned.fill(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),
                ),
                if (_videoDuration != null)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _videoDuration!,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade700,
        letterSpacing: 0.5,
      ),
    );
  }
}

