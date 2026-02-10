import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/theme/theme.dart';

/// End Quiz Screen - shared quiz shown after completing any of the 4 lesson types.
///
/// Accepts [questions] directly or loads them from API via [nodeId].
/// Each question should have:
///   { question: String, options: List<String>, correctAnswer: int, explanation?: String }
class EndQuizScreen extends StatefulWidget {
  final String nodeId;
  final String title;
  final String? lessonType; // e.g. 'image_quiz', 'video', 'text', 'image_gallery'
  final List<dynamic>? questions;

  const EndQuizScreen({
    super.key,
    required this.nodeId,
    required this.title,
    this.lessonType,
    this.questions,
  });

  @override
  State<EndQuizScreen> createState() => _EndQuizScreenState();
}

class _EndQuizScreenState extends State<EndQuizScreen>
    with TickerProviderStateMixin {
  // ═══════════════════════════════════════════════════════════════════
  // STATE
  // ═══════════════════════════════════════════════════════════════════
  bool _isLoading = true;
  String? _error;
  List<dynamic> _questions = [];
  int _passingScore = 70;
  int _currentQuestionIndex = 0;
  final Map<int, int> _selectedAnswers = {};
  bool _isSubmitting = false;
  bool _showResults = false;
  Map<String, dynamic>? _quizResult;
  Map<String, dynamic>? _rewardData; // Cascade rewards from completeLessonType

  // ═══════════════════════════════════════════════════════════════════
  // ANIMATIONS
  // ═══════════════════════════════════════════════════════════════════
  late AnimationController _questionController;
  late Animation<double> _questionFadeAnimation;
  late Animation<Offset> _questionSlideAnimation;
  late AnimationController _scoreController;
  late Animation<double> _scoreAnimation;
  late AnimationController _confettiController;

  // Confetti particles
  final List<_ConfettiParticle> _confettiParticles = [];
  final _random = Random();

  @override
  void initState() {
    super.initState();

    _questionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _questionFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _questionController, curve: Curves.easeOut),
    );
    _questionSlideAnimation = Tween<Offset>(
      begin: const Offset(0.08, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _questionController, curve: Curves.easeOut),
    );

    _scoreController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _scoreAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scoreController, curve: Curves.easeOutCubic),
    );

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _loadQuiz();
  }

  @override
  void dispose() {
    _questionController.dispose();
    _scoreController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════
  // DATA LOADING
  // ═══════════════════════════════════════════════════════════════════
  Future<void> _loadQuiz() async {
    // Use questions from constructor if provided
    if (widget.questions != null && widget.questions!.isNotEmpty) {
      setState(() {
        _questions = List.from(widget.questions!);
        _isLoading = false;
      });
      _questionController.forward();
      return;
    }

    // Load from API if nodeId is available
    if (widget.nodeId.isNotEmpty) {
      try {
        final apiService = Provider.of<ApiService>(context, listen: false);
        final data = await apiService.getLessonData(widget.nodeId);
        final endQuiz = data['endQuiz'] as Map<String, dynamic>?;
        if (endQuiz != null && endQuiz['questions'] != null) {
          setState(() {
            _questions = List.from(endQuiz['questions']);
            _passingScore = (endQuiz['passingScore'] as num?)?.toInt() ?? 70;
            _isLoading = false;
          });
          _questionController.forward();
          return;
        }
      } catch (e) {
        // Fall through to error
      }
    }

    setState(() {
      _error = 'Chưa có dữ liệu câu hỏi. Vui lòng thử lại sau.';
      _isLoading = false;
    });
  }

  // ═══════════════════════════════════════════════════════════════════
  // ANSWER SELECTION & NAVIGATION
  // ═══════════════════════════════════════════════════════════════════
  void _selectAnswer(int optionIndex) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedAnswers[_currentQuestionIndex] = optionIndex;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      _questionController.reset();
      setState(() => _currentQuestionIndex++);
      _questionController.forward();
    }
  }

  void _prevQuestion() {
    if (_currentQuestionIndex > 0) {
      _questionController.reset();
      setState(() => _currentQuestionIndex--);
      _questionController.forward();
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // SUBMISSION
  // ═══════════════════════════════════════════════════════════════════
  Future<void> _submitQuiz() async {
    final unansweredCount = _questions.length - _selectedAnswers.length;
    if (unansweredCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Còn $unansweredCount câu hỏi chưa trả lời'),
          backgroundColor: AppColors.warningNeon,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final answers = List.generate(
        _questions.length,
        (i) => _selectedAnswers[i] ?? 0,
      );

      Map<String, dynamic> result;

      // Use lesson-type-specific API if lessonType is available
      if (widget.lessonType != null && widget.lessonType!.isNotEmpty) {
        try {
          result = await apiService.submitEndQuizForType(
            widget.nodeId,
            widget.lessonType!,
            answers,
          );
        } catch (_) {
          // Fallback to local evaluation if API fails
          result = _evaluateLocally();
        }
      } else {
        // Fallback: try legacy API, then local evaluation
        try {
          result = await apiService.submitEndQuiz(widget.nodeId, answers);
        } catch (_) {
          result = _evaluateLocally();
        }
      }

      if (!mounted) return;

      setState(() {
        _quizResult = result;
        _showResults = true;
        _isSubmitting = false;
      });

      _scoreController.forward();

      if (result['passed'] == true) {
        HapticFeedback.heavyImpact();
        _generateConfettiParticles();
        _confettiController.forward();

        // Trigger completion cascade if lesson type is known
        if (widget.lessonType != null && widget.lessonType!.isNotEmpty) {
          try {
            final rewardResult = await apiService.completeLessonType(
              widget.nodeId,
              widget.lessonType!,
            );
            if (mounted) {
              setState(() => _rewardData = rewardResult);
            }
          } catch (e) {
            debugPrint('Error completing lesson type: $e');
          }
        }
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: AppColors.errorNeon,
          ),
        );
      }
    }
  }

  Map<String, dynamic> _evaluateLocally() {
    int correctCount = 0;
    final List<Map<String, dynamic>> results = [];

    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i] as Map<String, dynamic>;
      final selectedIdx = _selectedAnswers[i] ?? -1;
      final correctIdx =
          (q['correctAnswer'] ?? q['correctIndex'] ?? 0) as int;
      final isCorrect = selectedIdx == correctIdx;
      if (isCorrect) correctCount++;

      final optionsList = _getOptionTexts(q);
      final selectedText =
          (selectedIdx >= 0 && selectedIdx < optionsList.length)
              ? optionsList[selectedIdx]
              : '';
      final correctText =
          (correctIdx >= 0 && correctIdx < optionsList.length)
              ? optionsList[correctIdx]
              : '';

      // Get explanation: prefer correct answer's explanation, fallback to question-level
      final correctExplanation = _getOptionExplanation(q, correctIdx);
      final explanation = correctExplanation.isNotEmpty
          ? correctExplanation
          : (q['explanation'] ?? '').toString();

      results.add({
        'questionIndex': i,
        'question': q['question'] ?? '',
        'selectedAnswer': selectedText,
        'correctAnswer': correctText,
        'isCorrect': isCorrect,
        'explanation': explanation,
      });
    }

    final score = _questions.isEmpty
        ? 0
        : (correctCount * 100 / _questions.length).round();

    return {
      'passed': score >= _passingScore,
      'score': score,
      'totalQuestions': _questions.length,
      'correctCount': correctCount,
      'results': results,
    };
  }

  // ═══════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════
  List<String> _getOptionTexts(Map<String, dynamic> question) {
    final options = question['options'];
    if (options is List) {
      return options.map((o) {
        if (o is Map) {
          // Options structured as {text: "...", explanation: "..."}
          return (o['text'] ?? o['content'] ?? '').toString();
        }
        return o.toString();
      }).toList();
    }
    if (options is Map) {
      return ['A', 'B', 'C', 'D']
          .map((k) => (options[k] ?? '').toString())
          .toList();
    }
    return [];
  }

  /// Get the explanation for a specific option by index.
  String _getOptionExplanation(Map<String, dynamic> question, int optionIndex) {
    final options = question['options'];
    if (options is List && optionIndex >= 0 && optionIndex < options.length) {
      final o = options[optionIndex];
      if (o is Map) {
        return (o['explanation'] ?? '').toString();
      }
    }
    return '';
  }

  void _resetQuiz() {
    setState(() {
      _currentQuestionIndex = 0;
      _selectedAnswers.clear();
      _showResults = false;
      _quizResult = null;
      _confettiParticles.clear();
    });
    _scoreController.reset();
    _confettiController.reset();
    _questionController.reset();
    _questionController.forward();
  }

  void _generateConfettiParticles() {
    _confettiParticles.clear();
    for (int i = 0; i < 30; i++) {
      _confettiParticles.add(_ConfettiParticle(
        x: _random.nextDouble(),
        delay: _random.nextDouble() * 0.5,
        speed: 0.3 + _random.nextDouble() * 0.7,
        size: 8.0 + _random.nextDouble() * 16.0,
        icon: [
          Icons.star_rounded,
          Icons.auto_awesome,
          Icons.celebration,
          Icons.emoji_events,
          Icons.workspace_premium,
        ][_random.nextInt(5)],
        color: [
          AppColors.purpleNeon,
          AppColors.pinkNeon,
          AppColors.orangeNeon,
          AppColors.cyanNeon,
          AppColors.successNeon,
          AppColors.xpGold,
        ][_random.nextInt(6)],
      ));
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: _showResults ? _buildResultsView() : _buildQuizView(),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // QUIZ VIEW
  // ─────────────────────────────────────────────────────────────────
  Widget _buildQuizView() {
    if (_isLoading) return _buildLoadingState();
    if (_error != null) return _buildErrorState();
    if (_questions.isEmpty) {
      return Center(
        child: Text(
          'Không có câu hỏi',
          style: AppTextStyles.bodyLarge
              .copyWith(color: AppColors.textSecondary),
        ),
      );
    }
    return _buildQuizContent();
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.purpleNeon.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
            child: const Center(
              child: SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  color: AppColors.purpleNeon,
                  strokeWidth: 3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Đang tải câu hỏi...',
            style:
                AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            widget.title,
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.errorNeon.withOpacity(0.1),
              ),
              child: const Icon(Icons.error_outline,
                  size: 48, color: AppColors.errorNeon),
            ),
            const SizedBox(height: 24),
            Text(
              'Đã xảy ra lỗi',
              style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GamingButtonOutlined(
                  text: 'Quay lại',
                  onPressed: () => context.pop(),
                  icon: Icons.arrow_back_rounded,
                ),
                const SizedBox(width: 12),
                GamingButton(
                  text: 'Thử lại',
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _error = null;
                    });
                    _loadQuiz();
                  },
                  icon: Icons.refresh_rounded,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizContent() {
    final question = _questions[_currentQuestionIndex] as Map<String, dynamic>;
    final optionTexts = _getOptionTexts(question);
    final selectedIdx = _selectedAnswers[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _questions.length;
    final isLastQuestion = _currentQuestionIndex == _questions.length - 1;
    final allAnswered = _selectedAnswers.length == _questions.length;

    return Column(
      children: [
        // ── Header with close button and progress ──
        _buildQuizHeader(progress),

        // ── Question content ──
        Expanded(
          child: FadeTransition(
            opacity: _questionFadeAnimation,
            child: SlideTransition(
              position: _questionSlideAnimation,
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question counter
                    Text(
                      'Câu ${_currentQuestionIndex + 1}/${_questions.length}',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.purpleNeon,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Question text
                    Text(
                      (question['question'] ?? '').toString(),
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Option cards
                    ...List.generate(optionTexts.length, (i) {
                      final labels = ['A', 'B', 'C', 'D'];
                      final label = i < labels.length ? labels[i] : '${i + 1}';
                      return _buildOptionCard(
                        index: i,
                        label: label,
                        text: optionTexts[i],
                        isSelected: selectedIdx == i,
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ),

        // ── Bottom navigation bar ──
        _buildNavigationBar(isLastQuestion, allAnswered),
      ],
    );
  }

  Widget _buildQuizHeader(double progress) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 16),
      child: Column(
        children: [
          // Top row: close button + title
          Row(
            children: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.bgSecondary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderPrimary),
                  ),
                  child: const Icon(Icons.close,
                      color: AppColors.textPrimary, size: 20),
                ),
                onPressed: () => context.pop(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.title,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Passing score badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.bgSecondary,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderPrimary),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.flag_rounded,
                        size: 14, color: AppColors.purpleNeon),
                    const SizedBox(width: 4),
                    Text(
                      '$_passingScore%',
                      style: AppTextStyles.labelMedium
                          .copyWith(color: AppColors.purpleNeon),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Stack(
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.bgTertiary,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  height: 6,
                  width: (MediaQuery.of(context).size.width - 64) * progress,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.purpleNeon,
                        AppColors.pinkNeon,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.purpleNeon.withOpacity(0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required int index,
    required String label,
    required String text,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => _selectAnswer(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.purpleNeon.withOpacity(0.1)
              : AppColors.bgSecondary,
          border: Border.all(
            color: isSelected ? AppColors.purpleNeon : AppColors.borderPrimary,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.purpleNeon.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Letter badge
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [AppColors.purpleNeon, AppColors.pinkNeon],
                      )
                    : null,
                color: isSelected ? null : AppColors.bgTertiary,
                borderRadius: BorderRadius.circular(10),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.purpleNeon.withOpacity(0.4),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  label,
                  style: AppTextStyles.labelLarge.copyWith(
                    color:
                        isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Option text
            Expanded(
              child: Text(
                text,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isSelected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontSize: 15,
                ),
              ),
            ),
            // Check indicator
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.purpleNeon, AppColors.pinkNeon],
                  ),
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.check, color: Colors.white, size: 16),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationBar(bool isLastQuestion, bool allAnswered) {
    final bool canGoBack = _currentQuestionIndex > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        border: const Border(
          top: BorderSide(color: AppColors.borderPrimary),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          // "Câu trước" button
          if (canGoBack)
            Expanded(
              child: GamingButtonOutlined(
                text: 'Câu trước',
                onPressed: _prevQuestion,
                icon: Icons.arrow_back_rounded,
              ),
            ),
          if (canGoBack) const SizedBox(width: 12),

          // "Câu sau" or "Nộp bài" button
          Expanded(
            flex: canGoBack ? 2 : 1,
            child: isLastQuestion && allAnswered
                ? GamingButton(
                    text: 'Nộp bài',
                    onPressed: _isSubmitting ? null : _submitQuiz,
                    isLoading: _isSubmitting,
                    icon: Icons.check_rounded,
                    gradient: LinearGradient(
                      colors: [AppColors.purpleNeon, AppColors.pinkNeon],
                    ),
                    glowColor: AppColors.purpleNeon,
                  )
                : GamingButton(
                    text: isLastQuestion ? 'Nộp bài' : 'Câu sau',
                    onPressed: isLastQuestion
                        ? (_isSubmitting ? null : _submitQuiz)
                        : _nextQuestion,
                    isLoading: isLastQuestion ? _isSubmitting : false,
                    icon: isLastQuestion
                        ? Icons.check_rounded
                        : Icons.arrow_forward_rounded,
                  ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // RESULTS VIEW
  // ─────────────────────────────────────────────────────────────────
  Widget _buildResultsView() {
    if (_quizResult == null) return const SizedBox.shrink();

    final passed = _quizResult!['passed'] as bool;
    final score = _quizResult!['score'] as int;
    final correctCount = _quizResult!['correctCount'] as int;
    final totalQuestions = _quizResult!['totalQuestions'] as int;
    final results =
        List<Map<String, dynamic>>.from(_quizResult!['results'] ?? []);

    return Stack(
      children: [
        Column(
          children: [
            // ── Result header with score circle ──
            _buildResultHeader(passed, score, correctCount, totalQuestions),

            // ── Question results list ──
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: results.length,
                itemBuilder: (context, index) =>
                    _buildResultItem(results[index], index),
              ),
            ),

            // ── Action buttons ──
            _buildResultActions(passed),
          ],
        ),

        // ── Confetti overlay for passed quiz ──
        if (passed) _buildConfettiOverlay(),
      ],
    );
  }

  Widget _buildResultHeader(
      bool passed, int score, int correctCount, int totalQuestions) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            (passed ? AppColors.successNeon : AppColors.errorNeon)
                .withOpacity(0.15),
            AppColors.bgPrimary,
          ],
        ),
      ),
      child: Column(
        children: [
          // Animated score circle
          AnimatedBuilder(
            animation: _scoreAnimation,
            builder: (context, child) {
              final animatedScore = (score * _scoreAnimation.value).round();
              return SizedBox(
                width: 140,
                height: 140,
                child: CustomPaint(
                  painter: _ScoreCirclePainter(
                    progress: _scoreAnimation.value * score / 100,
                    passed: passed,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$animatedScore',
                          style: AppTextStyles.numberXLarge.copyWith(
                            color: passed
                                ? AppColors.successNeon
                                : AppColors.errorNeon,
                            fontSize: 44,
                          ),
                        ),
                        Text(
                          '%',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: (passed
                                    ? AppColors.successNeon
                                    : AppColors.errorNeon)
                                .withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // Pass/fail text
          Text(
            passed ? 'Đạt' : 'Chưa đạt',
            style: AppTextStyles.h2.copyWith(
              color: passed ? AppColors.successNeon : AppColors.errorNeon,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),

          // Correct count badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: (passed ? AppColors.successNeon : AppColors.errorNeon)
                    .withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 18,
                  color: AppColors.successNeon,
                ),
                const SizedBox(width: 8),
                Text(
                  '$correctCount/$totalQuestions câu đúng',
                  style: AppTextStyles.labelLarge
                      .copyWith(color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem(Map<String, dynamic> result, int index) {
    final isCorrect = result['isCorrect'] as bool;
    final explanation = (result['explanation'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCorrect
              ? AppColors.successNeon.withOpacity(0.3)
              : AppColors.errorNeon.withOpacity(0.3),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isCorrect ? AppColors.successNeon : AppColors.errorNeon)
                  .withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isCorrect ? Icons.check_rounded : Icons.close_rounded,
              color: isCorrect ? AppColors.successNeon : AppColors.errorNeon,
              size: 20,
            ),
          ),
          title: Text(
            'Câu ${index + 1}',
            style: AppTextStyles.labelLarge
                .copyWith(color: AppColors.textPrimary),
          ),
          subtitle: Text(
            isCorrect
                ? 'Đúng'
                : 'Sai — Đáp án: ${result['correctAnswer'] ?? ''}',
            style: AppTextStyles.bodySmall.copyWith(
              color: isCorrect ? AppColors.successNeon : AppColors.errorNeon,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question text
                  Text(
                    (result['question'] ?? '').toString(),
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textPrimary),
                  ),

                  // User's answer vs correct answer
                  if (!isCorrect) ...[
                    const SizedBox(height: 12),
                    _buildAnswerComparison(
                      'Bạn chọn',
                      (result['selectedAnswer'] ?? '').toString(),
                      AppColors.errorNeon,
                    ),
                    const SizedBox(height: 6),
                    _buildAnswerComparison(
                      'Đáp án',
                      (result['correctAnswer'] ?? '').toString(),
                      AppColors.successNeon,
                    ),
                  ],

                  // Explanation
                  if (explanation.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.cyanNeon.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.cyanNeon.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.lightbulb_outline,
                                  size: 16, color: AppColors.cyanNeon),
                              const SizedBox(width: 6),
                              Text(
                                'Giải thích',
                                style: AppTextStyles.labelMedium
                                    .copyWith(color: AppColors.cyanNeon),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            explanation,
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerComparison(String label, String answer, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(color: color),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            answer,
            style:
                AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildResultActions(bool passed) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        border: const Border(
          top: BorderSide(color: AppColors.borderPrimary),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Show reward summary if available
          if (passed && _rewardData != null) _buildRewardSummary(),

          Row(
            children: [
              if (!passed) ...[
                // "Thử lại" button
                Expanded(
                  child: GamingButtonOutlined(
                    text: 'Thử lại',
                    onPressed: _resetQuiz,
                    icon: Icons.refresh_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                // "Xem lại bài học" button
                Expanded(
                  child: GamingButton(
                    text: 'Xem lại bài học',
                    onPressed: () => context.pop(false),
                    icon: Icons.menu_book_rounded,
                  ),
                ),
              ],
              if (passed)
                Expanded(
                  child: GamingButton(
                    text: 'Hoàn thành',
                    onPressed: () => context.pop(true),
                    gradient: AppGradients.success,
                    glowColor: AppColors.successNeon,
                    icon: Icons.emoji_events_rounded,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRewardSummary() {
    final totalRewards = _rewardData?['totalRewards'] as Map<String, dynamic>?;
    final rewards = _rewardData?['rewards'] as List<dynamic>?;
    final lessonCompleted = _rewardData?['lessonCompleted'] == true;
    final topicCompleted = _rewardData?['topicCompleted'] == true;
    final domainCompleted = _rewardData?['domainCompleted'] == true;

    final totalXp = totalRewards?['xp'] ?? 0;
    final totalCoins = totalRewards?['coins'] ?? 0;

    if (totalXp == 0 && totalCoins == 0 && !lessonCompleted) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.xpGold.withOpacity(0.1),
            AppColors.successNeon.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.xpGold.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 20, color: AppColors.xpGold),
              const SizedBox(width: 8),
              Text(
                'Phần thưởng',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.xpGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Total rewards
          Row(
            children: [
              if (totalXp > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.xpGold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, size: 16, color: AppColors.xpGold),
                      const SizedBox(width: 4),
                      Text(
                        '+$totalXp XP',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.xpGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (totalCoins > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.orangeNeon.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.monetization_on_rounded, size: 16, color: AppColors.orangeNeon),
                      const SizedBox(width: 4),
                      Text(
                        '+$totalCoins Xu',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.orangeNeon,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          // Cascade completion badges
          if (lessonCompleted || topicCompleted || domainCompleted) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (lessonCompleted) _buildCompletionBadge('Bài học', Icons.check_circle, AppColors.successNeon),
                if (topicCompleted) _buildCompletionBadge('Topic', Icons.topic_rounded, AppColors.cyanNeon),
                if (domainCompleted) _buildCompletionBadge('Domain', Icons.domain_rounded, AppColors.purpleNeon),
              ],
            ),
          ],

          // Individual reward breakdown
          if (rewards != null && rewards.length > 1) ...[
            const SizedBox(height: 10),
            ...rewards.map<Widget>((r) {
              final level = (r['level'] ?? '').toString();
              final name = (r['name'] ?? '').toString();
              final xp = r['xp'] ?? 0;
              final coins = r['coins'] ?? 0;
              if (xp == 0 && coins == 0) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${_getLevelLabel(level)}: $name (+$xp XP, +$coins Xu)',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildCompletionBadge(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$label hoàn thành!',
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getLevelLabel(String level) {
    switch (level) {
      case 'lesson':
        return 'Bài học';
      case 'topic':
        return 'Topic';
      case 'domain':
        return 'Domain';
      default:
        return level;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // CONFETTI OVERLAY (animated icons)
  // ─────────────────────────────────────────────────────────────────
  Widget _buildConfettiOverlay() {
    return AnimatedBuilder(
      animation: _confettiController,
      builder: (context, child) {
        if (_confettiController.value == 0) return const SizedBox.shrink();
        return IgnorePointer(
          child: SizedBox.expand(
            child: Stack(
              children: _confettiParticles.map((p) {
                final adjustedProgress =
                    ((_confettiController.value - p.delay) / (1 - p.delay))
                        .clamp(0.0, 1.0);
                if (adjustedProgress <= 0) return const SizedBox.shrink();

                final screenWidth = MediaQuery.of(context).size.width;
                final screenHeight = MediaQuery.of(context).size.height;

                final x = p.x * screenWidth;
                final y = -p.size +
                    (screenHeight + p.size * 2) *
                        adjustedProgress *
                        p.speed;
                final opacity =
                    adjustedProgress < 0.8 ? 1.0 : (1 - adjustedProgress) * 5;
                final rotation = adjustedProgress * pi * 4 * p.speed;

                return Positioned(
                  left: x + sin(adjustedProgress * pi * 3) * 20,
                  top: y,
                  child: Opacity(
                    opacity: opacity.clamp(0.0, 1.0),
                    child: Transform.rotate(
                      angle: rotation,
                      child: Icon(
                        p.icon,
                        size: p.size,
                        color: p.color,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// SCORE CIRCLE PAINTER
// ═══════════════════════════════════════════════════════════════════════
class _ScoreCirclePainter extends CustomPainter {
  final double progress;
  final bool passed;

  _ScoreCirclePainter({required this.progress, required this.passed});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 8.0;

    // Background track
    final bgPaint = Paint()
      ..color = AppColors.bgTertiary
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Score arc with gradient
    if (progress > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      final gradientShader = SweepGradient(
        startAngle: -pi / 2,
        endAngle: 3 * pi / 2,
        colors: [
          AppColors.purpleNeon,
          AppColors.pinkNeon,
        ],
        transform: const GradientRotation(-pi / 2),
      ).createShader(rect);

      final arcPaint = Paint()
        ..shader = gradientShader
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        rect,
        -pi / 2,
        2 * pi * progress,
        false,
        arcPaint,
      );

      // Glow effect at the end of the arc
      final glowColor = passed ? AppColors.successNeon : AppColors.pinkNeon;
      final endAngle = -pi / 2 + 2 * pi * progress;
      final glowX = center.dx + radius * cos(endAngle);
      final glowY = center.dy + radius * sin(endAngle);

      final glowPaint = Paint()
        ..color = glowColor.withOpacity(0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(glowX, glowY), 6, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScoreCirclePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.passed != passed;
  }
}

// ═══════════════════════════════════════════════════════════════════════
// CONFETTI PARTICLE DATA
// ═══════════════════════════════════════════════════════════════════════
class _ConfettiParticle {
  final double x;
  final double delay;
  final double speed;
  final double size;
  final IconData icon;
  final Color color;

  const _ConfettiParticle({
    required this.x,
    required this.delay,
    required this.speed,
    required this.size,
    required this.icon,
    required this.color,
  });
}
