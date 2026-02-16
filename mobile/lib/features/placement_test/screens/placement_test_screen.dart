import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/theme/theme.dart';

class PlacementTestScreen extends StatefulWidget {
  const PlacementTestScreen({super.key});

  @override
  State<PlacementTestScreen> createState() => _PlacementTestScreenState();
}

class _PlacementTestScreenState extends State<PlacementTestScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _currentQuestion;
  bool _isLoading = true;
  String? _error;
  int? _selectedAnswer;
  bool _isSubmitting = false;
  int _currentQuestionNumber = 1;
  int _totalQuestions = 10;
  bool _isLoadingNextQuestion = false;

  late AnimationController _questionController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _questionController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _questionController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.05, 0),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _questionController, curve: Curves.easeOut));

    _startTest();
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _startTest() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _currentQuestionNumber = 1;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final response = await apiService.startPlacementTest();

      Map<String, dynamic>? question;

      if (response['questions'] != null &&
          (response['questions'] as List).isNotEmpty) {
        final questions = response['questions'] as List;
        final firstQuestion = questions[0] as Map<String, dynamic>;
        question = {
          'id': firstQuestion['questionId'],
          'question': firstQuestion['question'],
          'options': firstQuestion['options'],
          'difficulty': firstQuestion['difficulty'],
        };
        _currentQuestionNumber = 1;
        _totalQuestions = 10;
      } else {
        try {
          final currentTestResponse = await apiService.getCurrentTest();
          if (currentTestResponse['question'] != null) {
            question = currentTestResponse['question'];
            if (currentTestResponse['progress'] != null) {
              _currentQuestionNumber =
                  currentTestResponse['progress']['current'] ?? 1;
              _totalQuestions = currentTestResponse['progress']['total'] ?? 10;
            }
          }
        } catch (e) {
          print('⚠️  Error getting current test: $e');
        }
      }

      setState(() {
        _currentQuestion = question;
        _isLoading = false;
      });

      _questionController.forward();

      if (question == null) {
        setState(() {
          _error = 'Không thể tải câu hỏi. Vui lòng thử lại.';
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _submitAnswer() async {
    if (_selectedAnswer == null || _isSubmitting) return;

    HapticFeedback.lightImpact();

    setState(() {
      _isSubmitting = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final response = await apiService.submitAnswer(_selectedAnswer!);

      if (response['progress'] != null) {
        _currentQuestionNumber =
            response['progress']['current'] ?? _currentQuestionNumber + 1;
        _totalQuestions = response['progress']['total'] ?? 10;
      } else {
        _currentQuestionNumber++;
      }

      if (response['completed'] == true) {
        if (mounted) {
          context.go('/placement-test/analysis/${response['test']?['id']}');
        }
      } else {
        if (response['nextQuestion'] != null) {
          _questionController.reset();
          setState(() {
            _currentQuestion = response['nextQuestion'];
            _selectedAnswer = null;
            _isSubmitting = false;
            _isLoadingNextQuestion = false;
          });
          _questionController.forward();
        } else {
          setState(() {
            _isSubmitting = false;
            _isLoadingNextQuestion = true;
            _selectedAnswer = null;
          });
          _pollForNextQuestion();
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isSubmitting = false;
        _isLoadingNextQuestion = false;
      });
    }
  }

  Future<void> _pollForNextQuestion() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    int retryCount = 0;
    const maxRetries = 10;
    const retryDelay = Duration(seconds: 2);

    while (retryCount < maxRetries && mounted) {
      await Future.delayed(retryDelay);

      try {
        final response = await apiService.getCurrentTest();

        if (response['question'] != null) {
          if (response['progress'] != null) {
            final progress = response['progress'] as Map<String, dynamic>;
            _currentQuestionNumber =
                progress['current'] ?? _currentQuestionNumber;
            _totalQuestions = progress['total'] ?? 10;
          } else {
            _currentQuestionNumber++;
          }

          _questionController.reset();
          setState(() {
            _currentQuestion = response['question'];
            _isLoadingNextQuestion = false;
          });
          _questionController.forward();
          return;
        }
      } catch (e) {
        print('⚠️  Error polling for question: $e');
      }

      retryCount++;
    }

    if (mounted) {
      setState(() {
        _isLoadingNextQuestion = false;
        _error = 'Không thể tải câu hỏi tiếp theo. Vui lòng thử lại.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppGradients.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  const Icon(Icons.quiz_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text('Placement Test',
                style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary)),
          ],
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderPrimary),
            ),
            child: const Icon(Icons.arrow_back,
                color: AppColors.textPrimary, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _error != null
              ? _buildErrorState()
              : _currentQuestion == null
                  ? _buildNoQuestionState()
                  : _buildQuestionContent(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.purpleNeon.withOpacity(0.4),
                  blurRadius: 20,
                ),
              ],
            ),
            child: const CircularProgressIndicator(color: Colors.white),
          ),
          const SizedBox(height: 24),
          Text(
            'Đang chuẩn bị bài test...',
            style: AppTextStyles.bodyLarge
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
                color: AppColors.errorNeon.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  size: 48, color: AppColors.errorNeon),
            ),
            const SizedBox(height: 24),
            Text(
              'Có lỗi xảy ra',
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
            GamingButton(
              text: 'Thử lại',
              onPressed: _startTest,
              icon: Icons.refresh_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoQuestionState() {
    return Center(
      child: Text(
        'Không có câu hỏi',
        style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildQuestionContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress header
              _buildProgressHeader(),
              const SizedBox(height: 24),

              // Loading next question indicator
              if (_isLoadingNextQuestion) _buildLoadingNextQuestion(),

              // Question card
              _buildQuestionCard(),
              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: GamingButton(
                  text: _isSubmitting ? 'Đang gửi...' : 'Tiếp theo',
                  onPressed: _selectedAnswer != null && !_isSubmitting
                      ? _submitAnswer
                      : null,
                  isLoading: _isSubmitting,
                  icon: Icons.arrow_forward_rounded,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressHeader() {
    final progress = _currentQuestionNumber / _totalQuestions;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.purpleNeon.withOpacity(0.15),
            AppColors.pinkNeon.withOpacity(0.1)
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.purpleNeon.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Câu $_currentQuestionNumber / $_totalQuestions',
                style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: AppTextStyles.labelSmall.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.bgTertiary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              AnimatedProgressBox(
                widthFactor: progress,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: AppGradients.primary,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.purpleNeon.withOpacity(0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingNextQuestion() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.warningNeon.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warningNeon.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.warningNeon,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Đang tải câu hỏi tiếp theo...',
            style:
                AppTextStyles.bodyMedium.copyWith(color: AppColors.warningNeon),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question text
          Text(
            _currentQuestion!['question'] ?? 'Question',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textPrimary,
              fontSize: 18,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          // Options
          ...List.generate(
            (_currentQuestion!['options'] as List?)?.length ?? 0,
            (index) => _buildOptionCard(index),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(int index) {
    final option = (_currentQuestion!['options'] as List)[index];
    final isSelected = _selectedAnswer == index;
    final optionLetters = ['A', 'B', 'C', 'D', 'E', 'F'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _selectedAnswer = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: isSelected ? AppGradients.primary : null,
            color: isSelected ? null : AppColors.bgTertiary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? Colors.transparent : AppColors.borderPrimary,
              width: 2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.purpleNeon.withOpacity(0.3),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.2)
                      : AppColors.bgSecondary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    optionLetters[index],
                    style: AppTextStyles.labelLarge.copyWith(
                      color:
                          isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  option.toString(),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      size: 16, color: Colors.white),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
