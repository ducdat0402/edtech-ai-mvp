import 'dart:math';
import 'package:flutter/material.dart';
import 'package:edtech_mobile/theme/colors.dart';
import 'end_quiz_screen.dart';

class TextLessonScreen extends StatefulWidget {
  final String nodeId;
  final Map<String, dynamic> lessonData;
  final String title;
  final Map<String, dynamic>? endQuiz;
  final String? lessonType;

  const TextLessonScreen({
    super.key,
    required this.nodeId,
    required this.lessonData,
    required this.title,
    this.endQuiz,
    this.lessonType,
  });

  @override
  State<TextLessonScreen> createState() => _TextLessonScreenState();
}

class _TextLessonScreenState extends State<TextLessonScreen> {
  final Map<int, int?> _quizAnswers = {};
  final Map<int, bool> _quizRevealed = {};
  final Set<int> _checkedObjectives = {};

  List<Map<String, dynamic>> get _sections {
    final raw =
        widget.lessonData['sections'] ?? widget.lessonData['content'] ?? [];
    if (raw is List) return List<Map<String, dynamic>>.from(raw);
    return [];
  }

  List<Map<String, dynamic>> get _inlineQuizzes {
    final raw = widget.lessonData['inlineQuizzes'] ??
        widget.lessonData['quizzes'] ??
        [];
    return List<Map<String, dynamic>>.from(raw);
  }

  String get _summaryText =>
      (widget.lessonData['summary'] ?? widget.lessonData['conclusion'] ?? '')
          .toString();

  List<String> get _learningObjectives {
    final raw = widget.lessonData['learningObjectives'] ??
        widget.lessonData['objectives'] ??
        [];
    return List<String>.from(raw.map((e) => e.toString()));
  }

  int get _estimatedReadingTime {
    int totalWords = 0;
    for (final section in _sections) {
      final content = (section['content'] ?? section['text'] ?? '').toString();
      totalWords += content.split(RegExp(r'\s+')).length;
    }
    for (final quiz in _inlineQuizzes) {
      final q = (quiz['question'] ?? '').toString();
      totalWords += q.split(RegExp(r'\s+')).length;
    }
    totalWords += _summaryText.split(RegExp(r'\s+')).length;
    final minutes = (totalWords / 200).ceil();
    return max(1, minutes);
  }

  void _selectQuizAnswer(int quizIndex, int optionIndex) {
    if (_quizRevealed[quizIndex] == true) return;
    setState(() {
      _quizAnswers[quizIndex] = optionIndex;
      _quizRevealed[quizIndex] = true;
    });
  }

  int _getCorrectAnswer(Map<String, dynamic> quiz) {
    final correct = quiz['correctAnswer'] ?? quiz['correct'] ?? 0;
    return correct is int ? correct : int.tryParse(correct.toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Estimated reading time
                  _buildReadingTimeChip(),
                  const SizedBox(height: 16),

                  // Sections with inline quizzes
                  ..._buildSectionsWithQuizzes(),

                  // Summary card
                  if (_summaryText.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildSummaryCard(),
                  ],

                  // Learning objectives checklist
                  if (_learningObjectives.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildLearningObjectives(),
                  ],

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Bottom button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EndQuizScreen(
                        nodeId: widget.nodeId,
                        title: widget.title,
                        lessonType: widget.lessonType ?? 'text',
                        questions: (widget.endQuiz?['questions'] as List?)
                            ?.cast<dynamic>(),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purpleNeon,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Lam bai test',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingTimeChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.purpleNeon.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.purpleNeon.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.schedule, color: AppColors.purpleNeon, size: 16),
          const SizedBox(width: 6),
          Text(
            'Thoi gian doc: ~$_estimatedReadingTime phut',
            style: const TextStyle(
              color: AppColors.purpleNeon,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSectionsWithQuizzes() {
    final widgets = <Widget>[];
    int quizIndex = 0;

    for (int i = 0; i < _sections.length; i++) {
      final section = _sections[i];
      widgets.add(_buildSectionCard(section));

      // Check if there's a quiz after this section
      if (quizIndex < _inlineQuizzes.length) {
        final quiz = _inlineQuizzes[quizIndex];
        final afterSection =
            quiz['afterSection'] ?? quiz['position'] ?? quizIndex;
        final sectionPos = afterSection is int
            ? afterSection
            : int.tryParse(afterSection.toString()) ?? quizIndex;

        if (sectionPos == i ||
            (sectionPos <= i && quizIndex < _inlineQuizzes.length)) {
          widgets.add(_buildInlineQuiz(quizIndex, quiz));
          quizIndex++;
        }
      }
    }

    // Add remaining quizzes
    while (quizIndex < _inlineQuizzes.length) {
      widgets.add(_buildInlineQuiz(quizIndex, _inlineQuizzes[quizIndex]));
      quizIndex++;
    }

    return widgets;
  }

  Widget _buildSectionCard(Map<String, dynamic> section) {
    final sectionTitle =
        (section['title'] ?? section['heading'] ?? '').toString();
    final content = (section['content'] ?? section['text'] ?? '').toString();
    final examples =
        (section['examples'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (sectionTitle.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                sectionTitle,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (content.isNotEmpty)
            Text(
              content,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                height: 1.7,
              ),
            ),
          // Per-section examples
          if (examples.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...examples.map((example) => _buildExampleItem(example)),
          ],
        ],
      ),
    );
  }

  Widget _buildExampleItem(Map<String, dynamic> example) {
    final type = example['type'] as String? ?? 'real_world_scenario';
    final info =
        _exampleTypeInfo[type] ?? _exampleTypeInfo['real_world_scenario']!;
    final color = Color(info['color'] as int);
    final icon = info['icon'] as IconData;
    final label = info['label'] as String;
    final title = example['title'] as String? ?? '';
    final content = example['content'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        color: color.withOpacity(0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 5),
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty)
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold)),
                if (title.isNotEmpty && content.isNotEmpty)
                  const SizedBox(height: 4),
                if (content.isNotEmpty)
                  Text(content,
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineQuiz(int quizIndex, Map<String, dynamic> quiz) {
    final question = (quiz['question'] ?? '').toString();
    final options = List<Map<String, dynamic>>.from(quiz['options'] ?? []);
    final correctIndex = _getCorrectAnswer(quiz);
    final explanation = (quiz['explanation'] ?? '').toString();
    final selected = _quizAnswers[quizIndex];
    final revealed = _quizRevealed[quizIndex] == true;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: revealed
              ? (selected == correctIndex
                  ? AppColors.successNeon.withOpacity(0.5)
                  : AppColors.errorNeon.withOpacity(0.5))
              : AppColors.purpleNeon.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quiz header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.purpleNeon.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.quiz, color: AppColors.purpleNeon, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Cau hoi kiem tra',
                      style: TextStyle(
                        color: AppColors.purpleNeon,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Question
          Text(
            question,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // Options
          ...List.generate(options.length.clamp(0, 4), (optIdx) {
            final option = options[optIdx];
            final label = String.fromCharCode(65 + optIdx);
            final optionText =
                (option['text'] ?? option['content'] ?? '').toString();
            final isCorrect = optIdx == correctIndex;
            final isSelected = selected == optIdx;

            Color borderColor = AppColors.borderPrimary;
            Color bgColor = AppColors.bgTertiary;
            Color labelColor = AppColors.textSecondary;

            if (revealed) {
              if (isCorrect) {
                borderColor = AppColors.successNeon;
                bgColor = AppColors.successNeon.withOpacity(0.1);
                labelColor = AppColors.successNeon;
              } else if (isSelected && !isCorrect) {
                borderColor = AppColors.errorNeon;
                bgColor = AppColors.errorNeon.withOpacity(0.1);
                labelColor = AppColors.errorNeon;
              }
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => _selectQuizAnswer(quizIndex, optIdx),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: revealed && isCorrect
                              ? AppColors.successNeon.withOpacity(0.2)
                              : revealed && isSelected
                                  ? AppColors.errorNeon.withOpacity(0.2)
                                  : AppColors.bgSecondary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          label,
                          style: TextStyle(
                            color: labelColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          optionText,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (revealed && isCorrect)
                        const Icon(Icons.check_circle,
                            color: AppColors.successNeon, size: 20),
                      if (revealed && isSelected && !isCorrect)
                        const Icon(Icons.cancel,
                            color: AppColors.errorNeon, size: 20),
                    ],
                  ),
                ),
              ),
            );
          }),

          // Explanation with animated reveal
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            constraints: BoxConstraints(
              maxHeight: revealed && explanation.isNotEmpty ? 200 : 0,
            ),
            child: revealed && explanation.isNotEmpty
                ? SingleChildScrollView(
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: selected == correctIndex
                            ? AppColors.successNeon.withOpacity(0.08)
                            : AppColors.errorNeon.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected == correctIndex
                              ? AppColors.successNeon.withOpacity(0.3)
                              : AppColors.errorNeon.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            selected == correctIndex
                                ? Icons.check_circle_outline
                                : Icons.info_outline,
                            color: selected == correctIndex
                                ? AppColors.successNeon
                                : AppColors.orangeNeon,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              explanation,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  static const _exampleTypeInfo = <String, Map<String, dynamic>>{
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

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.purpleNeon.withOpacity(0.3)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.bgSecondary,
            AppColors.purpleNeon.withOpacity(0.05),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.purpleNeon.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome,
                    color: AppColors.purpleNeon, size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                'Tong ket',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _summaryText,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLearningObjectives() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.cyanNeon.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.checklist,
                    color: AppColors.cyanNeon, size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                'Noi dung can hoc',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(_learningObjectives.length, (index) {
            final isChecked = _checkedObjectives.contains(index);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (isChecked) {
                      _checkedObjectives.remove(index);
                    } else {
                      _checkedObjectives.add(index);
                    }
                  });
                },
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                        color: isChecked
                            ? AppColors.successNeon.withOpacity(0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isChecked
                              ? AppColors.successNeon
                              : AppColors.textTertiary,
                          width: 1.5,
                        ),
                      ),
                      child: isChecked
                          ? const Icon(Icons.check,
                              color: AppColors.successNeon, size: 16)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _learningObjectives[index],
                        style: TextStyle(
                          color: isChecked
                              ? AppColors.textTertiary
                              : AppColors.textSecondary,
                          fontSize: 14,
                          height: 1.5,
                          decoration:
                              isChecked ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
