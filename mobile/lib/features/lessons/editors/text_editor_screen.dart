import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:edtech_mobile/theme/colors.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'quiz_editor_screen.dart';

class TextEditorScreen extends StatefulWidget {
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

  const TextEditorScreen({
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
  int _generatingExampleSection = -1; // -1 = not generating
  final Set<int> _generatingInlineQuizExplanations = {};

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
        // Per-section examples
        final exList = m['examples'] as List?;
        if (exList != null) {
          sd.examples = exList.map((e) {
            final em = e as Map<String, dynamic>;
            final ed = _ExampleData(
                type: em['type'] as String? ?? 'real_world_scenario');
            ed.titleController.text = em['title'] as String? ?? '';
            ed.contentController.text = em['content'] as String? ?? '';
            return ed;
          }).toList();
        }
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
        final qd = _InlineQuizData(
            afterSectionIndex: m['afterSectionIndex'] as int? ?? 0);
        qd.questionController.text = m['question'] as String? ?? '';
        qd.correctAnswer = m['correctAnswer'] as int? ?? 0;
        final options = m['options'] as List? ?? [];
        for (int i = 0; i < options.length && i < 4; i++) {
          final opt = options[i] as Map<String, dynamic>;
          qd.optionControllers[i].text = opt['text'] as String? ?? '';
          qd.explanationControllers[i].text =
              opt['explanation'] as String? ?? '';
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
      _inlineQuizzes
          .removeWhere((q) => q.afterSectionIndex >= _sections.length);
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

  void _addExampleToSection(int sectionIndex) {
    setState(() {
      _sections[sectionIndex]
          .examples
          .add(_ExampleData(type: 'real_world_scenario'));
    });
  }

  void _removeExampleFromSection(int sectionIndex, int exampleIndex) {
    setState(() {
      _sections[sectionIndex].examples[exampleIndex].dispose();
      _sections[sectionIndex].examples.removeAt(exampleIndex);
    });
  }

  Future<void> _generateExampleWithAI(
      int sectionIndex, int exampleIndex) async {
    final section = _sections[sectionIndex];
    final sectionTitle = section.titleController.text.trim();
    final sectionContent = section.contentController.text.trim();

    if (sectionTitle.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Tiêu đề phần quá ngắn. Vui lòng nhập tiêu đề ít nhất 5 ký tự.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (sectionContent.length < 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Nội dung phần quá ngắn hoặc mơ hồ. Vui lòng bổ sung nội dung để AI tạo ví dụ chính xác hơn.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _generatingExampleSection = sectionIndex);

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final result = await apiService.generateExample(
        sectionTitle,
        sectionContent,
        section.examples[exampleIndex].type,
      );
      if (mounted) {
        setState(() {
          section.examples[exampleIndex].titleController.text =
              result['title'] as String? ?? '';
          section.examples[exampleIndex].contentController.text =
              result['content'] as String? ?? '';
        });
      }
    } catch (e) {
      if (!mounted) return;
      String errorMsg = 'Lỗi tạo ví dụ';
      if (e is DioException && e.response?.data != null) {
        final data = e.response!.data;
        final msg = data is Map ? (data['message'] ?? '') : data.toString();
        if (msg.toString().contains('kim cương')) {
          _showDiamondInsufficientDialog(msg.toString());
          setState(() => _generatingExampleSection = -1);
          return;
        }
        errorMsg = msg.toString();
      } else {
        errorMsg = e.toString();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _generatingExampleSection = -1);
    }
  }

  void _showDiamondInsufficientDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Text('💎', style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Text('Không đủ kim cương',
                style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 12),
            const Text(
              'Bạn có thể mua thêm kim cương trong phần Cửa hàng.',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).pushNamed('/payment');
            },
            icon: const Text('💎', style: TextStyle(fontSize: 16)),
            label: const Text('Mua kim cương'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.purpleNeon,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
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
          originalLessonData:
              widget.originalLessonData ?? widget.initialLessonData,
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
                          icon: const Icon(Icons.add,
                              color: AppColors.purpleNeon),
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
                          icon: const Icon(Icons.add,
                              color: AppColors.purpleNeon),
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
                                decoration:
                                    _inputDecoration('Mục tiêu ${index + 1}'),
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

  static const _exampleTypes = <String, Map<String, dynamic>>{
    'real_world_scenario': {
      'label': 'Tình huống thực tế',
      'icon': Icons.public,
      'color': 0xFF4CAF50
    },
    'everyday_analogy': {
      'label': 'So sánh đời thường',
      'icon': Icons.lightbulb_outline,
      'color': 0xFFFF9800
    },
    'hypothetical_situation': {
      'label': 'Tình huống giả định',
      'icon': Icons.psychology,
      'color': 0xFF9C27B0
    },
    'technical_implementation': {
      'label': 'Ví dụ kỹ thuật',
      'icon': Icons.code,
      'color': 0xFF2196F3
    },
    'step_by_step': {
      'label': 'Từng bước',
      'icon': Icons.format_list_numbered,
      'color': 0xFF00BCD4
    },
    'comparison': {
      'label': 'So sánh',
      'icon': Icons.compare_arrows,
      'color': 0xFFE91E63
    },
    'story_narrative': {
      'label': 'Kể chuyện',
      'icon': Icons.auto_stories,
      'color': 0xFF795548
    },
  };

  Widget _buildExampleCard(int sectionIndex, int exampleIndex) {
    final example = _sections[sectionIndex].examples[exampleIndex];
    final typeInfo =
        _exampleTypes[example.type] ?? _exampleTypes['real_world_scenario']!;
    final typeColor = Color(typeInfo['color'] as int);
    final isGenerating = _generatingExampleSection == sectionIndex;

    return Container(
      margin: const EdgeInsets.only(bottom: 8, top: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: typeColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: typeColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Icon(typeInfo['icon'] as IconData, color: typeColor, size: 18),
              const SizedBox(width: 6),
              Text(
                'Ví dụ ${exampleIndex + 1}',
                style: TextStyle(
                    color: typeColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              SizedBox(
                height: 28,
                child: ElevatedButton.icon(
                  onPressed: isGenerating
                      ? null
                      : () =>
                          _generateExampleWithAI(sectionIndex, exampleIndex),
                  icon: isGenerating
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.auto_awesome, size: 12),
                  label: Text(isGenerating ? '...' : 'AI 10💎',
                      style: const TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: typeColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: () =>
                    _removeExampleFromSection(sectionIndex, exampleIndex),
                child: const Icon(Icons.close,
                    color: AppColors.errorNeon, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Type dropdown
          DropdownButtonFormField<String>(
            value: example.type,
            dropdownColor: AppColors.bgSecondary,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            decoration: _inputDecoration('Loại ví dụ'),
            isDense: true,
            items: _exampleTypes.entries.map((entry) {
              final info = entry.value;
              return DropdownMenuItem(
                value: entry.key,
                child: Row(
                  children: [
                    Icon(info['icon'] as IconData,
                        size: 16, color: Color(info['color'] as int)),
                    const SizedBox(width: 6),
                    Text(info['label'] as String,
                        style: const TextStyle(fontSize: 13)),
                  ],
                ),
              );
            }).toList(),
            onChanged: (v) {
              if (v != null) setState(() => example.type = v);
            },
          ),
          const SizedBox(height: 8),

          // Title
          TextFormField(
            controller: example.titleController,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            decoration: _inputDecoration('Tiêu đề ví dụ'),
          ),
          const SizedBox(height: 8),

          // Content
          TextFormField(
            controller: example.contentController,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            decoration: _inputDecoration('Nội dung ví dụ'),
            maxLines: 4,
            minLines: 2,
          ),
        ],
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

          // Per-section examples
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.lightbulb_outline,
                  color: Colors.amber, size: 16),
              const SizedBox(width: 4),
              Text(
                'Ví dụ minh họa (${section.examples.length})',
                style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              SizedBox(
                height: 28,
                child: TextButton.icon(
                  onPressed: () => _addExampleToSection(index),
                  icon: const Icon(Icons.add, color: Colors.amber, size: 14),
                  label: const Text('Thêm',
                      style: TextStyle(color: Colors.amber, fontSize: 12)),
                  style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6)),
                ),
              ),
            ],
          ),
          ...List.generate(section.examples.length, (eIdx) {
            return _buildExampleCard(index, eIdx);
          }),
        ],
      ),
    );
  }

  Future<void> _generateInlineQuizAIExplanation(int quizIndex) async {
    final quiz = _inlineQuizzes[quizIndex];
    final questionText = quiz.questionController.text.trim();

    if (questionText.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Vui lòng nhập câu hỏi (ít nhất 5 ký tự) trước khi tạo giải thích'),
          backgroundColor: AppColors.warningNeon,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    for (int i = 0; i < 4; i++) {
      if (quiz.optionControllers[i].text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vui lòng nhập đáp án ${[
              'A',
              'B',
              'C',
              'D'
            ][i]} trước khi tạo giải thích'),
            backgroundColor: AppColors.warningNeon,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        return;
      }
    }

    setState(() => _generatingInlineQuizExplanations.add(quizIndex));

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final result = await apiService.generateQuizExplanations(
        question: questionText,
        options: List.generate(
            4, (i) => {'text': quiz.optionControllers[i].text.trim()}),
        correctAnswer: quiz.correctAnswer,
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
            await _showInlineQuizValidationDialog(validationIssues);
        if (!mounted) return;
        if (shouldContinue != true) {
          setState(() => _generatingInlineQuizExplanations.remove(quizIndex));
          return;
        }
      }

      // Show answer mismatch
      if (suggestedCorrectAnswer != null &&
          suggestedCorrectAnswer != quiz.correctAnswer) {
        final shouldChange = await _showInlineQuizMismatchDialog(
          currentAnswer: quiz.correctAnswer,
          suggestedAnswer: suggestedCorrectAnswer,
          reason: suggestedCorrectReason ?? '',
        );
        if (!mounted) return;
        if (shouldChange == true) {
          setState(() {
            quiz.correctAnswer = suggestedCorrectAnswer;
          });
        }
      }

      // Fill in explanations
      for (int i = 0; i < explanations.length && i < 4; i++) {
        final explanation = explanations[i]['explanation'] as String? ?? '';
        if (explanation.isNotEmpty) {
          quiz.explanationControllers[i].text = explanation;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã tạo lời giải thích thành công!'),
            backgroundColor: AppColors.successGlow,
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
          setState(() => _generatingInlineQuizExplanations.remove(quizIndex));
          return;
        }
        errorMsg = msg.toString();
      } else {
        errorMsg = e.toString();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: AppColors.errorNeon,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted)
        setState(() => _generatingInlineQuizExplanations.remove(quizIndex));
    }
  }

  Future<bool?> _showInlineQuizValidationDialog(List<String> issues) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warningNeon),
            SizedBox(width: 8),
            Text('Phát hiện vấn đề',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 17)),
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
                        const Text('• ',
                            style: TextStyle(
                                color: AppColors.warningNeon, fontSize: 14)),
                        Expanded(
                            child: Text(issue,
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14))),
                      ],
                    ),
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Sửa lỗi',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warningNeon,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child:
                const Text('Tiếp tục', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showInlineQuizMismatchDialog({
    required int currentAnswer,
    required int suggestedAnswer,
    required String reason,
  }) {
    final labels = ['A', 'B', 'C', 'D'];
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.errorNeon),
            SizedBox(width: 8),
            Expanded(
              child: Text('Cảnh báo: Đáp án có thể sai',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 17)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 14),
                children: [
                  const TextSpan(text: 'Bạn đánh dấu: '),
                  TextSpan(
                      text: labels[currentAnswer],
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                  const TextSpan(text: ' là đúng'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 14),
                children: [
                  const TextSpan(text: 'AI đề xuất: '),
                  TextSpan(
                      text: labels[suggestedAnswer],
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.orangeNeon)),
                  const TextSpan(text: ' mới đúng'),
                ],
              ),
            ),
            if (reason.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.bgTertiary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline,
                        color: AppColors.orangeNeon, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(reason,
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 13))),
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
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orangeNeon,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Đổi sang ${labels[suggestedAnswer]}',
                style: const TextStyle(color: Colors.white)),
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
            children: [
              const Icon(Icons.quiz_outlined,
                  color: AppColors.cyanNeon, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Câu hỏi inline (sau phần ${quiz.afterSectionIndex + 1})',
                  style: const TextStyle(
                    color: AppColors.cyanNeon,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // AI Explain button
              _generatingInlineQuizExplanations.contains(quizIndex)
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      child: const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.orangeNeon,
                        ),
                      ),
                    )
                  : InkWell(
                      onTap: () => _generateInlineQuizAIExplanation(quizIndex),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.orangeNeon.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColors.orangeNeon.withOpacity(0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome,
                                color: AppColors.orangeNeon, size: 12),
                            SizedBox(width: 3),
                            Text('AI 5💎',
                                style: TextStyle(
                                    color: AppColors.orangeNeon,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
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
                          validator: (v) => v == null || v.trim().isEmpty
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
  List<_ExampleData> examples = [];

  void dispose() {
    titleController.dispose();
    contentController.dispose();
    for (final e in examples) {
      e.dispose();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'title': titleController.text,
      'content': contentController.text,
      'examples': examples.map((e) => e.toJson()).toList(),
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

class _ExampleData {
  String type;
  final titleController = TextEditingController();
  final contentController = TextEditingController();

  _ExampleData({required this.type});

  void dispose() {
    titleController.dispose();
    contentController.dispose();
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'title': titleController.text,
      'content': contentController.text,
    };
  }
}
