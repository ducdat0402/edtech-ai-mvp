import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/theme/theme.dart';

class BossQuizScreen extends StatefulWidget {
  final String nodeId;
  final String nodeTitle;
  final Function(bool passed)? onComplete;

  const BossQuizScreen({
    super.key,
    required this.nodeId,
    required this.nodeTitle,
    this.onComplete,
  });

  @override
  State<BossQuizScreen> createState() => _BossQuizScreenState();
}

class _BossQuizScreenState extends State<BossQuizScreen> with TickerProviderStateMixin {
  bool _isLoading = true;
  String? _error;
  String? _sessionId;
  List<Map<String, dynamic>> _questions = [];
  int _passingScore = 80;
  int _currentQuestionIndex = 0;
  Map<String, String> _answers = {};
  bool _isSubmitting = false;
  Map<String, dynamic>? _result;

  late AnimationController _pulseController;
  late AnimationController _questionController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _questionFadeAnimation;
  late Animation<Offset> _questionSlideAnimation;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
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
    
    _confettiController = ConfettiController(duration: const Duration(seconds: 5));
    
    _loadQuiz();
  }

  @override
  void dispose() {
    _pulseController.dispose();
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
      final response = await apiService.generateBossQuiz(widget.nodeId);

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        setState(() {
          _sessionId = data['sessionId'];
          _questions = List<Map<String, dynamic>>.from(data['questions'] ?? []);
          _passingScore = data['passingScore'] ?? 80;
          _isLoading = false;
        });
        _questionController.forward();
      } else {
        throw Exception('Failed to load boss quiz');
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
      body: _buildBody(),
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
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated boss icon
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppGradients.primary,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.purpleNeon.withOpacity(0.5),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                        BoxShadow(
                          color: AppColors.pinkNeon.withOpacity(0.3),
                          blurRadius: 50,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        '👑',
                        style: TextStyle(fontSize: 50),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            ShaderMask(
              shaderCallback: (bounds) => AppGradients.primary.createShader(
                Rect.fromLTWH(0, 0, bounds.width, bounds.height),
              ),
              child: Text(
                'BOSS QUIZ',
                style: AppTextStyles.h1.copyWith(
                  color: Colors.white,
                  letterSpacing: 4,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Đang chuẩn bị thử thách...',
              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              '25 câu hỏi tổng hợp',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                backgroundColor: AppColors.bgTertiary,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.purpleNeon),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.errorNeon.withOpacity(0.1),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.errorNeon.withOpacity(0.2),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: const Icon(Icons.warning_rounded, size: 56, color: AppColors.errorNeon),
              ),
              const SizedBox(height: 24),
              Text(
                'Không thể tải Boss Quiz',
                style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                _error ?? '',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GamingButtonOutlined(
                    text: 'Quay lại',
                    onPressed: () => Navigator.pop(context),
                    icon: Icons.arrow_back_rounded,
                  ),
                  const SizedBox(width: 12),
                  GamingButton(
                    text: 'Thử lại',
                    onPressed: _loadQuiz,
                    icon: Icons.refresh_rounded,
                  ),
                ],
              ),
            ],
          ),
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
    final answeredCount = _answers.length;

    return SafeArea(
      child: Column(
        children: [
          // Epic header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.purpleNeon.withOpacity(0.3),
                  AppColors.pinkNeon.withOpacity(0.2),
                  AppColors.bgPrimary,
                ],
              ),
            ),
            child: Column(
              children: [
                // Top row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back button
                    IconButton(
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
                    // Boss Quiz badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: AppGradients.primary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.purpleNeon.withOpacity(0.4),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Text('👑', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Text(
                            'BOSS QUIZ',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Passing score
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.bgSecondary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderPrimary),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.flag_rounded, size: 16, color: AppColors.warningNeon),
                          const SizedBox(width: 4),
                          Text(
                            '$_passingScore%',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.warningNeon,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Progress section
                Row(
                  children: [
                    // Question number
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Câu ${_currentQuestionIndex + 1}',
                          style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
                        ),
                        Text(
                          'của ${_questions.length}',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Answered counter
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.successNeon.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.successNeon.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, size: 14, color: AppColors.successNeon),
                          const SizedBox(width: 4),
                          Text(
                            '$answeredCount đã trả lời',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.successNeon,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Epic progress bar
                Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.bgTertiary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      height: 8,
                      width: MediaQuery.of(context).size.width * progress * 0.85,
                      decoration: BoxDecoration(
                        gradient: AppGradients.primary,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.purpleNeon.withOpacity(0.6),
                            blurRadius: 10,
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
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.purpleNeon.withOpacity(0.2),
                                AppColors.pinkNeon.withOpacity(0.2),
                              ],
                            ),
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
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Options with epic styling
                      ...['A', 'B', 'C', 'D'].map((opt) {
                        final isSelected = selectedAnswer == opt;
                        return _buildBossOptionCard(opt, options[opt] ?? '', isSelected);
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Navigation bar
          _buildNavigationBar(),
        ],
      ),
    );
  }

  Widget _buildBossOptionCard(String option, String text, bool isSelected) {
    return GestureDetector(
      onTap: () => _selectAnswer(_questions[_currentQuestionIndex]['id'], option),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppColors.purpleNeon.withOpacity(0.2),
                    AppColors.pinkNeon.withOpacity(0.1),
                  ],
                )
              : null,
          color: isSelected ? null : AppColors.bgSecondary,
          border: Border.all(
            color: isSelected ? AppColors.purpleNeon : AppColors.borderPrimary,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.purpleNeon.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Option letter with gradient
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: isSelected ? AppGradients.primary : null,
                color: isSelected ? null : AppColors.bgTertiary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.purpleNeon.withOpacity(0.5),
                          blurRadius: 10,
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
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Option text
            Expanded(
              child: Text(
                text,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                  fontSize: 15,
                ),
              ),
            ),
            // Check indicator
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
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
                  : Icons.send_rounded,
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

    // Trigger confetti for passed boss quiz
    if (passed && !_confettiController.state.name.contains('playing')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        HapticFeedback.heavyImpact();
        _confettiController.play();
      });
    }

    return Stack(
      children: [
        SafeArea(
          child: Column(
        children: [
          // Epic result header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: passed
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.successNeon.withOpacity(0.4),
                        AppColors.cyanNeon.withOpacity(0.3),
                        AppColors.bgPrimary,
                      ],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.errorNeon.withOpacity(0.4),
                        AppColors.orangeNeon.withOpacity(0.3),
                        AppColors.bgPrimary,
                      ],
                    ),
            ),
            child: Column(
              children: [
                // Trophy or retry icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: passed ? AppGradients.success : AppGradients.error,
                    boxShadow: [
                      BoxShadow(
                        color: (passed ? AppColors.successNeon : AppColors.errorNeon)
                            .withOpacity(0.5),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Text(
                    passed ? '🏆' : '💪',
                    style: const TextStyle(fontSize: 48),
                  ),
                ),
                const SizedBox(height: 24),
                // Result text
                ShaderMask(
                  shaderCallback: (bounds) => (passed ? AppGradients.success : AppGradients.error)
                      .createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                  child: Text(
                    passed ? 'CHIẾN THẮNG!' : 'CHƯA ĐẠT',
                    style: AppTextStyles.h1.copyWith(
                      color: Colors.white,
                      letterSpacing: 3,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Score
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$score',
                      style: AppTextStyles.numberXLarge.copyWith(
                        color: passed ? AppColors.successNeon : AppColors.errorNeon,
                        fontSize: 64,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '%',
                        style: AppTextStyles.h2.copyWith(
                          color: (passed ? AppColors.successNeon : AppColors.errorNeon)
                              .withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Stats row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.bgSecondary.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.borderPrimary),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 18, color: AppColors.successNeon),
                      const SizedBox(width: 6),
                      Text(
                        '$correctAnswers/$totalQuestions câu đúng',
                        style: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                if (passed) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: AppGradients.primary,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.purpleNeon.withOpacity(0.4),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('👑', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text(
                          'Bạn đã chinh phục Boss Quiz!',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.purpleNeon.withOpacity(0.1),
                                      AppColors.cyanNeon.withOpacity(0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.purpleNeon.withOpacity(0.2)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.lightbulb_outline,
                                            size: 16, color: AppColors.purpleNeon),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Giải thích',
                                          style: AppTextStyles.labelMedium.copyWith(
                                            color: AppColors.purpleNeon,
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
                    icon: passed ? Icons.emoji_events_rounded : Icons.close_rounded,
                  ),
                ),
              ],
            ),
          ),
          ],
        ),
      ),
      // Epic confetti for boss quiz victory
      if (passed)
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: pi / 2,
            blastDirectionality: BlastDirectionality.explosive,
            maxBlastForce: 40,
            minBlastForce: 15,
            emissionFrequency: 0.02,
            numberOfParticles: 50,
            gravity: 0.15,
            shouldLoop: true,
            colors: const [
              AppColors.purpleNeon,
              AppColors.pinkNeon,
              AppColors.orangeNeon,
              AppColors.cyanNeon,
              AppColors.successNeon,
              AppColors.xpGold,
              AppColors.rankGold,
            ],
          ),
        ),
      ],
    );
  }

  String _getCategoryLabel(String? category) {
    switch (category) {
      case 'concept':
        return 'Khái niệm';
      case 'example':
        return 'Vận dụng';
      case 'synthesis':
        return 'Tổng hợp';
      case 'definition':
        return 'Định nghĩa';
      case 'distinction':
        return 'Phân biệt';
      default:
        return category ?? '';
    }
  }
}
