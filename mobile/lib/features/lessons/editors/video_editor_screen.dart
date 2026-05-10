import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:edtech_mobile/theme/theme.dart';
import 'package:edtech_mobile/core/widgets/app_bar_leading_back_home.dart';
import 'quiz_editor_screen.dart';

class VideoEditorScreen extends StatefulWidget {
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

  const VideoEditorScreen({
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
  State<VideoEditorScreen> createState() => _VideoEditorScreenState();
}

class _VideoEditorScreenState extends State<VideoEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _videoUrlController = TextEditingController();
  final _summaryController = TextEditingController();
  final _keywordController = TextEditingController();

  List<_KeyPointData> _keyPoints = [];
  List<String> _keywords = [];

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

    _videoUrlController.text = data['videoUrl'] as String? ?? '';
    _summaryController.text = data['summary'] as String? ?? '';

    final keyPoints = data['keyPoints'] as List?;
    if (keyPoints != null && keyPoints.isNotEmpty) {
      for (final kp in _keyPoints) {
        kp.dispose();
      }
      _keyPoints = keyPoints.map((kp) {
        final m = kp as Map<String, dynamic>;
        final kpd = _KeyPointData();
        kpd.titleController.text = m['title'] as String? ?? '';
        kpd.descriptionController.text = m['description'] as String? ?? '';
        kpd.timestampController.text = (m['timestamp'] ?? '').toString();
        return kpd;
      }).toList();
    }

    final keywords = data['keywords'] as List?;
    if (keywords != null) {
      _keywords = keywords.map((k) => k.toString()).toList();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _videoUrlController.dispose();
    _summaryController.dispose();
    _keywordController.dispose();
    for (final kp in _keyPoints) {
      kp.dispose();
    }
    super.dispose();
  }

  void _addKeyPoint() {
    setState(() {
      _keyPoints.add(_KeyPointData());
    });
  }

  void _removeKeyPoint(int index) {
    setState(() {
      _keyPoints[index].dispose();
      _keyPoints.removeAt(index);
    });
  }

  void _addKeyword() {
    final text = _keywordController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _keywords.add(text);
      _keywordController.clear();
    });
  }

  void _removeKeyword(int index) {
    setState(() {
      _keywords.removeAt(index);
    });
  }

  Map<String, dynamic> _buildLessonData() {
    return {
      'videoUrl': _videoUrlController.text,
      'summary': _summaryController.text,
      'keyPoints': _keyPoints.map((kp) => kp.toJson()).toList(),
      'keywords': _keywords,
    };
  }

  void _navigateToQuizEditor() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizEditorScreen(
          lessonType: 'video',
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

  InputDecoration _inputDecoration(BuildContext context, String label,
      {String? hintText}) {
    final sem = context.colors;
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      hintStyle: TextStyle(color: sem.textTertiary, fontSize: 13),
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
          widget.isEditMode ? 'Sửa bài Video' : 'Tạo bài Video',
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
                      decoration:
                          _inputDecoration(context, 'Tiêu đề bài học'),
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
                    const SizedBox(height: 16),

                    // Video URL
                    TextFormField(
                      controller: _videoUrlController,
                      style: TextStyle(color: sem.textPrimary),
                      decoration: _inputDecoration(
                        context,
                        'URL Video',
                        hintText: 'YouTube, Vimeo, hoặc link trực tiếp',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Nhập URL video';
                        }
                        final url = v.trim().toLowerCase();
                        if (!url.startsWith('http://') &&
                            !url.startsWith('https://')) {
                          return 'URL phải bắt đầu với http:// hoặc https://';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Summary
                    TextFormField(
                      controller: _summaryController,
                      style: TextStyle(color: sem.textPrimary),
                      decoration:
                          _inputDecoration(context, 'Tóm tắt nội dung'),
                      maxLines: 5,
                    ),
                    const SizedBox(height: 24),

                    // Key Points section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Nội dung chính',
                          style: TextStyle(
                            color: sem.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _addKeyPoint,
                          icon: Icon(Icons.add, color: sem.brand),
                          label: Text(
                            'Thêm nội dung chính',
                            style: TextStyle(
                                color: sem.brand, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    ...List.generate(_keyPoints.length, (index) {
                      return _buildKeyPointCard(context, index);
                    }),

                    const SizedBox(height: 24),

                    // Keywords section
                    Text(
                      'Từ khóa',
                      style: TextStyle(
                        color: sem.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Keyword input
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _keywordController,
                            style: TextStyle(color: sem.textPrimary),
                            decoration:
                                _inputDecoration(context, 'Thêm từ khóa'),
                            onFieldSubmitted: (_) => _addKeyword(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _addKeyword,
                          icon: Icon(Icons.add_circle,
                              color: sem.brand, size: 32),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Keyword chips
                    if (_keywords.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(_keywords.length, (i) {
                          return Chip(
                            label: Text(
                              _keywords[i],
                              style: TextStyle(color: sem.textPrimary),
                            ),
                            backgroundColor: sem.cardMuted,
                            side: BorderSide(
                                color: sem.border.withValues(alpha: 0.65)),
                            deleteIcon: Icon(Icons.close,
                                size: 16, color: sem.textSecondary),
                            onDeleted: () => _removeKeyword(i),
                          );
                        }),
                      ),

                    const SizedBox(height: 16),
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

  Widget _buildKeyPointCard(BuildContext context, int index) {
    final kp = _keyPoints[index];
    final sem = context.colors;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nội dung ${index + 1}',
                style: TextStyle(
                  color: sem.brand,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline,
                    color: sem.error, size: 20),
                onPressed: () => _removeKeyPoint(index),
              ),
            ],
          ),
          Divider(
              color: sem.border.withValues(alpha: 0.65), height: 16),

          // Title
          TextFormField(
            controller: kp.titleController,
            style: TextStyle(color: sem.textPrimary),
            decoration: _inputDecoration(context, 'Tiêu đề'),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Nhập tiêu đề' : null,
          ),
          const SizedBox(height: 10),

          // Description
          TextFormField(
            controller: kp.descriptionController,
            style: TextStyle(color: sem.textPrimary),
            decoration: _inputDecoration(context, 'Mô tả (tuỳ chọn)'),
            maxLines: 2,
          ),
          const SizedBox(height: 10),

          // Timestamp
          TextFormField(
            controller: kp.timestampController,
            style: TextStyle(color: sem.textPrimary),
            decoration:
                _inputDecoration(context, 'Timestamp (giây, tuỳ chọn)'),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ],
      ),
    );
  }
}

class _KeyPointData {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final timestampController = TextEditingController();

  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    timestampController.dispose();
  }

  Map<String, dynamic> toJson() {
    return {
      'title': titleController.text,
      'description': descriptionController.text,
      'timestamp': int.tryParse(timestampController.text),
    };
  }
}
