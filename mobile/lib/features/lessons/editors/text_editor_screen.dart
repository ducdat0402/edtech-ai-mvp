import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:edtech_mobile/theme/colors.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'quiz_editor_screen.dart';

class TextEditorScreen extends StatefulWidget {
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

  const TextEditorScreen({
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
  State<TextEditorScreen> createState() => _TextEditorScreenState();
}

class _TextEditorScreenState extends State<TextEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _summaryController = TextEditingController();

  List<_SectionData> _sections = [_SectionData()];
  List<_InlineQuizData> _inlineQuizzes = [];
  List<TextEditingController> _objectiveControllers = [TextEditingController()];

  @override
  void initState() {
    super.initState();
    _prefillData();
  }

  void _prefillData() {
    final data = widget.initialLessonData;
    if (data == null) return;

    _summaryController.text = data['summary'] as String? ?? '';

    // Sections
    final sections = data['sections'] as List?;
    if (sections != null && sections.isNotEmpty) {
      for (final s in _sections) {
        s.dispose();
      }
      _sections = sections.map((s) {
        final m = s as Map<String, dynamic>;
        final sd = _SectionData();
        sd.titleController.text = m['title'] as String? ?? '';
        sd.contentController.text = m['content'] as String? ?? '';
        return sd;
      }).toList();
    }

    // Inline quizzes
    final quizzes = data['inlineQuizzes'] as List?;
    if (quizzes != null && quizzes.isNotEmpty) {
      for (final q in _inlineQuizzes) {
        q.dispose();
      }
      _inlineQuizzes = quizzes.map((q) {
        final m = q as Map<String, dynamic>;
        final qd = _InlineQuizData(afterSectionIndex: m['afterSectionIndex'] as int? ?? 0);
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
    }

    // Learning objectives
    final objectives = data['learningObjectives'] as List?;
    if (objectives != null && objectives.isNotEmpty) {
      for (final c in _objectiveControllers) {
        c.dispose();
      }
      _objectiveControllers = objectives.map((o) {
        final c = TextEditingController();
        c.text = o.toString();
        return c;
      }).toList();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _summaryController.dispose();
    for (final s in _sections) {
      s.dispose();
    }
    for (final q in _inlineQuizzes) {
      q.dispose();
    }
    for (final c in _objectiveControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addSection() {
    setState(() {
      _sections.add(_SectionData());
    });
  }

  void _removeSection(int index) {
    if (_sections.length <= 1) return;
    setState(() {
      _sections[index].dispose();
      _sections.removeAt(index);
      // Remove inline quizzes that referenced this or later sections
      _inlineQuizzes.removeWhere((q) => q.afterSectionIndex >= _sections.length);
      // Adjust indexes for quizzes after removed section
      for (final q in _inlineQuizzes) {
        if (q.afterSectionIndex > index) {
          q.afterSectionIndex--;
        }
      }
    });
  }

  void _addInlineQuiz(int afterSectionIndex) {
    setState(() {
      _inlineQuizzes.add(_InlineQuizData(afterSectionIndex: afterSectionIndex));
    });
  }

  void _removeInlineQuiz(int index) {
    setState(() {
      _inlineQuizzes[index].dispose();
      _inlineQuizzes.removeAt(index);
    });
  }

  void _addObjective() {
    setState(() {
      _objectiveControllers.add(TextEditingController());
    });
  }

  void _removeObjective(int index) {
    if (_objectiveControllers.length <= 1) return;
    setState(() {
      _objectiveControllers[index].dispose();
      _objectiveControllers.removeAt(index);
    });
  }

  Map<String, dynamic> _buildLessonData() {
    return {
      'sections': _sections.map((s) => s.toJson()).toList(),
      'inlineQuizzes': _inlineQuizzes.map((q) => q.toJson()).toList(),
      'summary': _summaryController.text,
      'learningObjectives': _objectiveControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList(),
    };
  }

  void _navigateToQuizEditor() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizEditorScreen(
          lessonType: 'text',
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
          widget.isEditMode ? 'Sửa bài Text' : 'Tạo bài Text',
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
                    const SizedBox(height: 24),

                    // Sections header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Các phần (${_sections.length})',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _addSection,
                          icon: const Icon(Icons.add, color: AppColors.purpleNeon),
                          label: const Text(
                            'Thêm phần',
                            style: TextStyle(color: AppColors.purpleNeon),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Sections and inline quizzes
                    ...List.generate(_sections.length, (index) {
                      final quizzesAfter = _inlineQuizzes
                          .where((q) => q.afterSectionIndex == index)
                          .toList();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionCard(index),
                          // "Add inline quiz" button after each section
                          Center(
                            child: TextButton.icon(
                              onPressed: () => _addInlineQuiz(index),
                              icon: const Icon(Icons.quiz_outlined,
                                  color: AppColors.cyanNeon, size: 18),
                              label: const Text(
                                'Thêm câu hỏi',
                                style: TextStyle(
                                    color: AppColors.cyanNeon, fontSize: 13),
                              ),
                            ),
                          ),
                          // Inline quizzes after this section
                          ...quizzesAfter.map((quiz) {
                            final qIndex = _inlineQuizzes.indexOf(quiz);
                            return _buildInlineQuizCard(qIndex);
                          }),
                        ],
                      );
                    }),

                    const SizedBox(height: 24),

                    // Summary
                    const Text(
                      'Tóm tắt',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _summaryController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: _inputDecoration('Tóm tắt bài học'),
                      maxLines: 5,
                    ),
                    const SizedBox(height: 24),

                    // Learning Objectives
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Mục tiêu học tập',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _addObjective,
                          icon: const Icon(Icons.add, color: AppColors.purpleNeon),
                          label: const Text(
                            'Thêm',
                            style: TextStyle(color: AppColors.purpleNeon),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(_objectiveControllers.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _objectiveControllers[index],
                                style: const TextStyle(
                                    color: AppColors.textPrimary),
                                decoration: _inputDecoration(
                                    'Mục tiêu ${index + 1}'),
                              ),
                            ),
                            if (_objectiveControllers.length > 1)
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline,
                                    color: AppColors.errorNeon, size: 20),
                                onPressed: () => _removeObjective(index),
                              ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 16),
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

  Widget _buildSectionCard(int index) {
    final section = _sections[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
                'Phần ${index + 1}',
                style: const TextStyle(
                  color: AppColors.purpleNeon,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_sections.length > 1)
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.errorNeon, size: 20),
                  onPressed: () => _removeSection(index),
                ),
            ],
          ),
          const Divider(color: AppColors.borderPrimary, height: 20),

          // Section title
          TextFormField(
            controller: section.titleController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: _inputDecoration('Tiêu đề phần'),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Nhập tiêu đề' : null,
          ),
          const SizedBox(height: 12),

          // Section content
          TextFormField(
            controller: section.contentController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: _inputDecoration('Nội dung'),
            maxLines: 8,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Nhập nội dung' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildInlineQuizCard(int quizIndex) {
    final quiz = _inlineQuizzes[quizIndex];
    final labels = ['A', 'B', 'C', 'D'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cyanNeon.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.quiz_outlined,
                      color: AppColors.cyanNeon, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Câu hỏi inline (sau phần ${quiz.afterSectionIndex + 1})',
                    style: const TextStyle(
                      color: AppColors.cyanNeon,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: AppColors.errorNeon, size: 20),
                onPressed: () => _removeInlineQuiz(quizIndex),
              ),
            ],
          ),
          const Divider(color: AppColors.borderPrimary, height: 16),

          // Question
          TextFormField(
            controller: quiz.questionController,
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
                        groupValue: quiz.correctAnswer,
                        onChanged: (v) {
                          setState(() {
                            quiz.correctAnswer = v ?? 0;
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
                          controller: quiz.optionControllers[optIdx],
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
                      controller: quiz.explanationControllers[optIdx],
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

class _SectionData {
  final titleController = TextEditingController();
  final contentController = TextEditingController();

  void dispose() {
    titleController.dispose();
    contentController.dispose();
  }

  Map<String, dynamic> toJson() {
    return {
      'title': titleController.text,
      'content': contentController.text,
    };
  }
}

class _InlineQuizData {
  int afterSectionIndex;
  final questionController = TextEditingController();
  final List<TextEditingController> optionControllers =
      List.generate(4, (_) => TextEditingController());
  final List<TextEditingController> explanationControllers =
      List.generate(4, (_) => TextEditingController());
  int correctAnswer = 0;

  _InlineQuizData({required this.afterSectionIndex});

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
      'afterSectionIndex': afterSectionIndex,
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
