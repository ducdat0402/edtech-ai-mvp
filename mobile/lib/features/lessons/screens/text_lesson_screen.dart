import 'dart:math';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:edtech_mobile/core/widgets/app_bar_leading_back_home.dart';
import 'package:edtech_mobile/core/widgets/ai_generated_notice.dart';
import 'package:edtech_mobile/core/widgets/contributor_credit_button.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/theme/theme.dart';
import 'end_quiz_screen.dart';

class TextLessonScreen extends StatefulWidget {
  final String nodeId;
  final Map<String, dynamic> lessonData;
  final String title;
  final Map<String, dynamic>? endQuiz;
  final String? lessonType;
  final Map<String, dynamic>? contributor;
  final List<Map<String, dynamic>>? contentVersionHistory;

  const TextLessonScreen({
    super.key,
    required this.nodeId,
    required this.lessonData,
    required this.title,
    this.endQuiz,
    this.lessonType,
    this.contributor,
    this.contentVersionHistory,
  });

  @override
  State<TextLessonScreen> createState() => _TextLessonScreenState();
}

class _TextLessonScreenState extends State<TextLessonScreen> {
  final Map<int, int?> _quizAnswers = {};
  final Map<int, bool> _quizRevealed = {};
  final Set<int> _checkedObjectives = {};

  bool _isSimplifying = false;
  String? _simplifiedText;
  int _selectedView = 0; // 0: original, 1: simplified

  List<Map<String, dynamic>> get _sections {
    final raw = widget.lessonData['sections'] ?? widget.lessonData['content'];
    if (raw is List) {
      return List<Map<String, dynamic>>.from(
        raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList(),
      );
    }
    if (raw is String && raw.trim().isNotEmpty) {
      return [
        {
          'title': 'Nội dung bài học',
          'content': raw.trim(),
        }
      ];
    }
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      final mapText = (map['content'] ??
              map['text'] ??
              map['description'] ??
              map['body'] ??
              '')
          .toString()
          .trim();
      if (mapText.isNotEmpty) {
        return [
          {
            'title': (map['title'] ?? map['heading'] ?? 'Nội dung bài học')
                .toString(),
            'content': mapText,
          }
        ];
      }
    }

    final fallbackText = (widget.lessonData['text'] ??
            widget.lessonData['body'] ??
            widget.lessonData['article'] ??
            widget.lessonData['articleText'] ??
            widget.lessonData['description'] ??
            widget.lessonData['lessonText'] ??
            widget.lessonData['markdown'] ??
            widget.lessonData['contentText'] ??
            '')
        .toString()
        .trim();
    if (fallbackText.isNotEmpty) {
      return [
        {
          'title': 'Nội dung bài học',
          'content': fallbackText,
        }
      ];
    }
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

  String get _fullTextForSimplify {
    final parts = <String>[];
    for (final section in _sections) {
      final sectionTitle = (section['title'] ?? section['heading'] ?? '')
          .toString()
          .trim();
      final content = (section['content'] ??
              section['text'] ??
              section['description'] ??
              section['body'] ??
              '')
          .toString()
          .trim();
      if (sectionTitle.isNotEmpty) parts.add(sectionTitle);
      if (content.isNotEmpty) parts.add(content);
    }
    if (_summaryText.trim().isNotEmpty) {
      parts.add('Tổng kết');
      parts.add(_summaryText.trim());
    }
    return parts.join('\n\n').trim();
  }

  int get _fullTextWordCount =>
      _fullTextForSimplify.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

  Future<void> _onSimplifyPressed() async {
    if (_isSimplifying) return;

    if (_fullTextWordCount < 50) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bài học quá ngắn, không thể đơn giản hóa hơn được nữa.',
          ),
        ),
      );
      return;
    }

    setState(() => _isSimplifying = true);
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final res = await api.simplifyTextLesson(
        nodeId: widget.nodeId,
        title: widget.title,
        content: _fullTextForSimplify,
      );
      if (!mounted) return;
      final simplified = (res['simplifiedText'] ?? '').toString().trim();
      final remaining = int.tryParse('${res['remainingFreeUsesToday'] ?? ''}');
      setState(() {
        _simplifiedText = simplified.isEmpty ? _simplifiedText : simplified;
        _selectedView = 1;
      });
      if (remaining != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Còn $remaining lượt miễn phí hôm nay')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      String msg = 'Có lỗi xảy ra. Vui lòng thử lại.';
      bool requiresPaywall = false;

      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map) {
          final m = data['message'];
          if (m is String && m.trim().isNotEmpty) msg = m.trim();
          requiresPaywall = data['requiresPaywall'] == true;
        } else if (data is String && data.trim().isNotEmpty) {
          msg = data.trim();
        }
      } else {
        final raw = e.toString();
        if (raw.trim().isNotEmpty) msg = raw;
      }

      if (requiresPaywall) {
        showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Đã hết lượt miễn phí'),
            content: Text(msg),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Đóng'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSimplifying = false);
    }
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = context.colors;
    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: isDark
            ? null
            : const BrandHeader(
                padding: EdgeInsets.zero,
                child: SizedBox.shrink(),
              ),
        leading: AppBarLeadingBackAndHome(
          iconColor: isDark ? null : tokens.textOnBrand,
        ),
        leadingWidth: 112,
        automaticallyImplyLeading: false,
        title: Text(
          widget.title,
          style: TextStyle(
            color: isDark ? tokens.textPrimary : tokens.textOnBrand,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          ContributorCreditButton(
            contributor: widget.contributor,
            contentVersionHistory: widget.contentVersionHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AiGeneratedNotice(visible: widget.contributor == null),
                  if (widget.contributor == null) const SizedBox(height: 10),
                  // Estimated reading time
                  Row(
                    children: [
                      _buildReadingTimeChip(),
                      const Spacer(),
                      _buildSimplifyButton(),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Sections with inline quizzes
                  ..._buildContentByView(),

                  // Summary card
                  if (_summaryText.isNotEmpty && _selectedView == 0) ...[
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
                        contributor: widget.contributor,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: tokens.brand,
                  foregroundColor: tokens.textOnBrand,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Làm bài kiểm tra',
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
    final t = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: t.brand.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: t.brand.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule, color: t.brand, size: 16),
          const SizedBox(width: 6),
          Text(
            'Thời gian đọc: ~$_estimatedReadingTime phút',
            style: TextStyle(
              color: t.brand,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimplifyButton() {
    final t = context.colors;
    final canShowTabs = _simplifiedText != null && _simplifiedText!.isNotEmpty;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (canShowTabs)
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: t.card,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: t.brand.withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildViewChip(label: 'Gốc', value: 0),
                _buildViewChip(label: 'Bản đơn giản', value: 1),
              ],
            ),
          ),
        const SizedBox(width: 10),
        SizedBox(
          height: 34,
          child: ElevatedButton.icon(
            onPressed: _isSimplifying ? null : _onSimplifyPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: t.brand,
              foregroundColor: t.textOnBrand,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            icon: _isSimplifying
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: t.textOnBrand,
                    ),
                  )
                : const Icon(Icons.auto_fix_high, size: 18),
            label: const Text(
              'Đơn giản hóa',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildViewChip({required String label, required int value}) {
    final t = context.colors;
    final selected = _selectedView == value;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => setState(() => _selectedView = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? t.brand.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? t.brand : t.textTertiary,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildContentByView() {
    if (_selectedView == 1 && (_simplifiedText?.trim().isNotEmpty ?? false)) {
      return [
        _buildSimplifiedCard(_simplifiedText!.trim()),
        ..._buildSectionsWithQuizzes(includeSections: false),
      ];
    }
    return _buildSectionsWithQuizzes(includeSections: true);
  }

  List<Widget> _buildSectionsWithQuizzes({required bool includeSections}) {
    final widgets = <Widget>[];

    if (includeSections) {
      for (int i = 0; i < _sections.length; i++) {
        final section = _sections[i];
        widgets.add(_buildSectionCard(section));
      }
    }

    // Always place quiz part after reading content to avoid "all questions" feeling.
    if (_inlineQuizzes.isNotEmpty) {
      widgets.add(const SizedBox(height: 6));
      widgets.add(
        Text(
          'Câu hỏi ôn tập',
          style: TextStyle(
            color: context.colors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
      widgets.add(const SizedBox(height: 10));
      for (int quizIndex = 0; quizIndex < _inlineQuizzes.length; quizIndex++) {
        widgets.add(_buildInlineQuiz(quizIndex, _inlineQuizzes[quizIndex]));
      }
    }

    return widgets;
  }

  Widget _buildSimplifiedCard(String simplified) {
    final t = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: t.brand.withValues(alpha: 0.25)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              t.card,
              t.brand.withValues(alpha: 0.05),
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
                    color: t.brand.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.auto_fix_high,
                    color: t.brand,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Bản đơn giản',
                    style: TextStyle(
                      color: t.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              simplified,
              style: TextStyle(
                color: t.textSecondary,
                fontSize: 15,
                height: 1.7,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildSectionCard(Map<String, dynamic> section) {
    final t = context.colors;
    final rawSectionTitle =
        (section['title'] ?? section['heading'] ?? '').toString();
    final content = (section['content'] ??
            section['text'] ??
            section['description'] ??
            section['body'] ??
            '')
        .toString();
    final titlePrefix = '${widget.title} - ';
    final sectionTitle = rawSectionTitle.startsWith(titlePrefix)
        ? rawSectionTitle.substring(titlePrefix.length).trim()
        : rawSectionTitle;
    final examples =
        (section['examples'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: t.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (sectionTitle.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  sectionTitle,
                  style: TextStyle(
                    color: t.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (content.isNotEmpty)
              Text(
                content,
                style: TextStyle(
                  color: t.textSecondary,
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
      ),
    );
  }

  Widget _buildExampleItem(Map<String, dynamic> example) {
    final t = context.colors;
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
        border: Border.all(color: color.withValues(alpha: 0.3)),
        color: color.withValues(alpha: 0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
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
                          color: t.textSecondary,
                          height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineQuiz(int quizIndex, Map<String, dynamic> quiz) {
    final t = context.colors;
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
        color: t.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: revealed
              ? (selected == correctIndex
                  ? t.success.withValues(alpha: 0.5)
                  : t.error.withValues(alpha: 0.5))
              : t.brand.withValues(alpha: 0.3),
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
                  color: t.brand.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.quiz, color: t.brand, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Câu hỏi kiểm tra',
                      style: TextStyle(
                        color: t.brand,
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
            style: TextStyle(
              color: t.textPrimary,
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

            Color borderColor = const Color(0x332D363D);
            Color bgColor = t.cardMuted;
            Color labelColor = t.textSecondary;

            if (revealed) {
              if (isCorrect) {
                borderColor = t.success;
                bgColor = t.success.withValues(alpha: 0.1);
                labelColor = t.success;
              } else if (isSelected && !isCorrect) {
                borderColor = t.error;
                bgColor = t.error.withValues(alpha: 0.1);
                labelColor = t.error;
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
                              ? t.success.withValues(alpha: 0.2)
                              : revealed && isSelected
                                  ? t.error.withValues(alpha: 0.2)
                                  : t.card,
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
                          style: TextStyle(
                            color: t.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (revealed && isCorrect)
                        Icon(Icons.check_circle, color: t.success, size: 20),
                      if (revealed && isSelected && !isCorrect)
                        Icon(Icons.cancel, color: t.error, size: 20),
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
                            ? t.success.withValues(alpha: 0.08)
                            : t.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected == correctIndex
                              ? t.success.withValues(alpha: 0.3)
                              : t.error.withValues(alpha: 0.3),
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
                                ? t.success
                                : t.warning,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              explanation,
                              style: TextStyle(
                                color: t.textSecondary,
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
    final t = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.brand.withValues(alpha: 0.3)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            t.card,
            t.brand.withValues(alpha: 0.05),
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
                  color: t.brand.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.auto_awesome, color: t.brand, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                'Tổng kết',
                style: TextStyle(
                  color: t.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _summaryText,
            style: TextStyle(
              color: t.textSecondary,
              fontSize: 15,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLearningObjectives() {
    final t = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: t.brand.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.checklist, color: t.brand, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                'Nội dung cần học',
                style: TextStyle(
                  color: t.textPrimary,
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
                            ? t.success.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isChecked
                              ? t.success
                              : t.textTertiary,
                          width: 1.5,
                        ),
                      ),
                      child: isChecked
                          ? Icon(Icons.check, color: t.success, size: 16)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _learningObjectives[index],
                        style: TextStyle(
                          color: isChecked
                              ? t.textTertiary
                              : t.textSecondary,
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
