import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/theme/theme.dart';

class QuizScreen extends StatefulWidget {
  final String contentItemId;
  final String contentTitle;
  final String contentType; // 'concept' or 'example'
  final String nodeId;
  final Function(bool passed)? onComplete;

  const QuizScreen({
    super.key,
    required this.contentItemId,
    required this.contentTitle,
    required this.contentType,
    required this.nodeId,
    this.onComplete,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  bool _isLoading = true;
  String? _error;
  String? _sessionId;
  List<Map<String, dynamic>> _questions = [];
  int _passingScore = 70;
  int _currentQuestionIndex = 0;
  Map<String, String> _answers = {};
  bool _isSubmitting = false;
  Map<String, dynamic>? _result;
  
  late AnimationController _progressController;
  late AnimationController _questionController;
  late Animation<double> _questionFadeAnimation;
  late Animation<Offset> _questionSlideAnimation;
  late ConfettiController _confettiController;

  Color get _themeColor => widget.contentType == 'concept' 
      ? AppColors.cyanNeon 
      : AppColors.successNeon;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _questionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _questionFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _questionController, curve: Curves.easeOut),
    );
    _questionSlideAnimation = Tween<Offset>(
      begin: const Offset(0.1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _questionController, curve: Curves.easeOut));
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    
    _loadQuiz();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _questionController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadQuiz() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final apiService = Provider.of<ApiService>(context, listen: false);
      final response = await apiService.generateQuiz(widget.contentItemId);

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        setState(() {
          _sessionId = data['sessionId'];
          _questions = List<Map<String, dynamic>>.from(data['questions'] ?? []);
          _passingScore = data['passingScore'] ?? 70;
          _isLoading = false;
        });
        _questionController.forward();
      } else {
        throw Exception('Failed to load quiz');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _selectAnswer(String questionId, String answer) {
    HapticFeedback.lightImpact();
    setState(() {
      _answers[questionId] = answer;
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

  Future<void> _submitQuiz() async {
    if (_sessionId == null) return;

    final unanswered = _questions.where((q) => !_answers.containsKey(q['id'])).toList();
    if (unanswered.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vui lòng trả lời tất cả ${unanswered.length} câu hỏi còn lại'),
          backgroundColor: AppColors.warningNeon,
        ),
      );
      return;
    }

    try {
      setState(() => _isSubmitting = true);

      final apiService = Provider.of<ApiService>(context, listen: false);
      final response = await apiService.submitQuiz(_sessionId!, _answers);

      if (response['success'] == true && response['data'] != null) {
        final passed = response['data']['passed'] as bool;
        if (passed) {
          HapticFeedback.heavyImpact();
        }
        setState(() {
          _result = response['data'];
          _isSubmitting = false;
        });
      } else {
        throw Exception('Failed to submit quiz');
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.errorNeon),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.bgSecondary,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderPrimary),
          ),
          child: const Icon(Icons.close, color: AppColors.textPrimary, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _themeColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _themeColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.contentType == 'concept' ? Icons.lightbulb_rounded : Icons.code_rounded,
                  color: _themeColor,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.contentType == 'concept' ? 'CONCEPT' : 'EXAMPLE',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: _themeColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_result != null) {
      return _buildResultScreen();
    }

    if (_questions.isEmpty) {
      return Center(
        child: Text(
          'Không có câu hỏi',
          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
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
          // Animated loading indicator
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [_themeColor.withOpacity(0.3), Colors.transparent],
              ),
            ),
            child: Center(
              child: SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  color: _themeColor,
                  strokeWidth: 3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Đang tạo câu hỏi...',
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'AI đang phân tích nội dung bài học',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
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
              child: const Icon(Icons.error_outline, size: 48, color: AppColors.errorNeon),
            ),
            const SizedBox(height: 24),
            Text(
              'Đã xảy ra lỗi',
              style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GamingButton(
              text: 'Thử lại',
              onPressed: _loadQuiz,
              icon: Icons.refresh_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizContent() {
    final question = _questions[_currentQuestionIndex];
    final questionId = question['id'] as String;
    final options = question['options'] as Map<String, dynamic>;
    final selectedAnswer = _answers[questionId];
    final progress = (_currentQuestionIndex + 1) / _questions.length;

    return Column(
      children: [
        // Progress section
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // Progress info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Câu ${_currentQuestionIndex + 1}',
                        style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary),
                      ),
                      Text(
                        ' / ${_questions.length}',
                        style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.bgSecondary,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.borderPrimary),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.flag_rounded, size: 14, color: _themeColor),
                        const SizedBox(width: 4),
                        Text(
                          '$_passingScore%',
                          style: AppTextStyles.labelMedium.copyWith(color: _themeColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Animated progress bar
              Stack(
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
                    width: MediaQuery.of(context).size.width * progress * 0.9,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_themeColor, _themeColor.withOpacity(0.7)],
                      ),
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [
                        BoxShadow(
                          color: _themeColor.withOpacity(0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Question content
        Expanded(
          child: FadeTransition(
            opacity: _questionFadeAnimation,
            child: SlideTransition(
              position: _questionSlideAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category tag
                    if (question['category'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.purpleNeon.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.purpleNeon.withOpacity(0.3)),
                        ),
                        child: Text(
                          _getCategoryLabel(question['category']),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.purpleNeon,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                    // Question text
                    Text(
                      question['question'] ?? '',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Options
                    ...['A', 'B', 'C', 'D'].map((opt) {
                      final isSelected = selectedAnswer == opt;
                      return _buildOptionCard(opt, options[opt] ?? '', isSelected);
                    }),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Navigation buttons
        _buildNavigationBar(),
      ],
    );
  }

  Widget _buildOptionCard(String option, String text, bool isSelected) {
    return GestureDetector(
      onTap: () => _selectAnswer(_questions[_currentQuestionIndex]['id'], option),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? _themeColor.withOpacity(0.1) : AppColors.bgSecondary,
          border: Border.all(
            color: isSelected ? _themeColor : AppColors.borderPrimary,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _themeColor.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Option letter
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected ? _themeColor : AppColors.bgTertiary,
                borderRadius: BorderRadius.circular(10),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: _themeColor.withOpacity(0.4),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  option,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
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
                  color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
            ),
            // Check icon
            if (isSelected)
              Icon(Icons.check_circle, color: _themeColor, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        border: Border(top: BorderSide(color: AppColors.borderPrimary)),
      ),
      child: Row(
        children: [
          if (_currentQuestionIndex > 0)
            Expanded(
              child: GamingButtonOutlined(
                text: 'Quay lại',
                onPressed: _prevQuestion,
                icon: Icons.arrow_back_rounded,
              ),
            ),
          if (_currentQuestionIndex > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: GamingButton(
              text: _currentQuestionIndex < _questions.length - 1 ? 'Tiếp theo' : 'Nộp bài',
              onPressed: _currentQuestionIndex < _questions.length - 1
                  ? _nextQuestion
                  : (_isSubmitting ? null : _submitQuiz),
              isLoading: _isSubmitting,
              icon: _currentQuestionIndex < _questions.length - 1
                  ? Icons.arrow_forward_rounded
                  : Icons.check_rounded,
              gradient: LinearGradient(colors: [_themeColor, _themeColor.withOpacity(0.8)]),
              glowColor: _themeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultScreen() {
    final passed = _result!['passed'] as bool;
    final score = _result!['score'] as int;
    final correctAnswers = _result!['correctAnswers'] as int;
    final totalQuestions = _result!['totalQuestions'] as int;
    final details = List<Map<String, dynamic>>.from(_result!['details'] ?? []);

    // Trigger confetti for high scores
    if (score >= 80 && !_confettiController.state.name.contains('playing')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        HapticFeedback.heavyImpact();
        _confettiController.play();
      });
    }

    return Stack(
      children: [
        Column(
          children: [
            // Result header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: passed ? AppGradients.success : AppGradients.error,
                boxShadow: [
                  BoxShadow(
                    color: (passed ? AppColors.successNeon : AppColors.errorNeon).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Result icon with glow
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.3),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Icon(
                      passed ? Icons.check_rounded : Icons.refresh_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
              const SizedBox(height: 20),
              Text(
                passed ? 'Chúc mừng!' : 'Chưa đạt',
                style: AppTextStyles.h2.copyWith(
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              // Score display
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$score',
                    style: AppTextStyles.numberXLarge.copyWith(
                      color: Colors.white,
                      fontSize: 56,
                    ),
                  ),
                  Text(
                    '%',
                    style: AppTextStyles.h3.copyWith(color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$correctAnswers/$totalQuestions câu đúng',
                  style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ),

        // Details list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: details.length,
            itemBuilder: (context, index) {
              final detail = details[index];
              final isCorrect = detail['isCorrect'] as bool;
              final questionIndex = _questions.indexWhere((q) => q['id'] == detail['questionId']);
              final question = questionIndex >= 0 ? _questions[questionIndex] : null;

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
                      style: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary),
                    ),
                    subtitle: Text(
                      isCorrect ? 'Đúng' : 'Sai - Đáp án: ${detail['correctAnswer']}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isCorrect ? AppColors.successNeon : AppColors.errorNeon,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (question != null)
                              Text(
                                question['question'] ?? '',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.cyanNeon.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.cyanNeon.withOpacity(0.2)),
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
                                        style: AppTextStyles.labelMedium.copyWith(
                                          color: AppColors.cyanNeon,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    detail['explanation'] ?? '',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Action buttons
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.bgSecondary,
            border: Border(top: BorderSide(color: AppColors.borderPrimary)),
          ),
          child: Row(
            children: [
              if (!passed)
                Expanded(
                  child: GamingButtonOutlined(
                    text: 'Làm lại',
                    onPressed: () {
                      setState(() {
                        _result = null;
                        _answers = {};
                        _currentQuestionIndex = 0;
                      });
                      _loadQuiz();
                    },
                    icon: Icons.refresh_rounded,
                  ),
                ),
              if (!passed) const SizedBox(width: 12),
              Expanded(
                child: GamingButton(
                  text: passed ? 'Hoàn thành' : 'Đóng',
                  onPressed: () {
                    widget.onComplete?.call(passed);
                    Navigator.pop(context, passed);
                  },
                  gradient: passed ? AppGradients.success : null,
                  glowColor: passed ? AppColors.successNeon : null,
                  icon: passed ? Icons.check_rounded : Icons.close_rounded,
                ),
              ),
            ],
          ),
        ),
        ],
      ),
      // Confetti for high scores
      if (score >= 80)
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: pi / 2,
            blastDirectionality: BlastDirectionality.explosive,
            maxBlastForce: 30,
            minBlastForce: 10,
            emissionFrequency: 0.03,
            numberOfParticles: 30,
            gravity: 0.2,
            shouldLoop: false,
            colors: const [
              AppColors.purpleNeon,
              AppColors.pinkNeon,
              AppColors.orangeNeon,
              AppColors.cyanNeon,
              AppColors.successNeon,
              AppColors.xpGold,
            ],
          ),
        ),
      ],
    );
  }

  String _getCategoryLabel(String? category) {
    switch (category) {
      case 'definition':
        return 'Định nghĩa';
      case 'distinction':
        return 'Phân biệt';
      case 'correct_example':
        return 'Ví dụ đúng';
      case 'wrong_example':
        return 'Ví dụ sai';
      case 'mini_case':
        return 'Tình huống';
      case 'concept':
        return 'Khái niệm';
      case 'example':
        return 'Vận dụng';
      case 'synthesis':
        return 'Tổng hợp';
      default:
        return category ?? '';
    }
  }
}
