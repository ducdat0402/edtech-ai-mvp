import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/theme/theme.dart';

/// Adaptive Placement Test Screen
/// Tests user knowledge to create personalized learning path
class AdaptivePlacementTestScreen extends StatefulWidget {
  final String subjectId;
  final String? subjectName;

  const AdaptivePlacementTestScreen({
    super.key,
    required this.subjectId,
    this.subjectName,
  });

  @override
  State<AdaptivePlacementTestScreen> createState() => _AdaptivePlacementTestScreenState();
}

class _AdaptivePlacementTestScreenState extends State<AdaptivePlacementTestScreen>
    with TickerProviderStateMixin {
  // Test state
  Map<String, dynamic>? _testData;
  Map<String, dynamic>? _currentQuestion;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;
  int? _selectedAnswer;
  bool? _lastAnswerCorrect;
  String? _lastExplanation;
  
  // Progress
  int _currentQuestionIndex = 0;
  int _totalQuestions = 0;
  int _correctAnswers = 0;
  String _currentDifficulty = 'beginner';
  String _currentTopic = '';
  String _currentDomain = '';
  
  // Completion state
  bool _isCompleted = false;
  Map<String, dynamic>? _testResult;
  
  // Animation
  late AnimationController _progressController;
  late ConfettiController _confettiController;
  
  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _startTest();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _startTest() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final result = await apiService.startAdaptivePlacementTest(widget.subjectId);
      
      setState(() {
        _testData = result;
        _currentQuestion = result['currentQuestion'];
        _totalQuestions = result['estimatedQuestions'] ?? 20;
        _currentTopic = result['currentTopic'] ?? '';
        _currentDomain = result['currentDomain'] ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _submitAnswer() async {
    if (_selectedAnswer == null || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final result = await apiService.submitAdaptiveAnswer(
        _testData!['testId'],
        _selectedAnswer!,
      );

      final isCorrect = result['isCorrect'] as bool? ?? false;
      final isSkipped = result['isSkipped'] as bool? ?? false;
      final completed = result['completed'] as bool? ?? false;

      setState(() {
        _lastAnswerCorrect = isSkipped ? null : isCorrect; // null for skip (no feedback)
        _lastExplanation = result['explanation'] as String?;
        _currentQuestionIndex = result['progress']?['current'] ?? _currentQuestionIndex + 1;
        _totalQuestions = result['progress']?['total'] ?? _totalQuestions;
        _currentDifficulty = result['adaptiveData']?['currentDifficulty'] ?? _currentDifficulty;
        _currentTopic = result['currentTopic'] ?? _currentTopic;
        _currentDomain = result['currentDomain'] ?? _currentDomain;
        
        if (isCorrect) {
          _correctAnswers++;
        }
      });

      // Haptic feedback
      if (isSkipped) {
        HapticFeedback.mediumImpact();
      } else if (isCorrect) {
        HapticFeedback.lightImpact();
      } else {
        HapticFeedback.heavyImpact();
      }

      // Show result briefly then move to next (shorter for skip)
      await Future.delayed(Duration(milliseconds: isSkipped ? 500 : 2000));

      if (completed) {
        // Test completed
        _confettiController.play();
        HapticFeedback.heavyImpact();
        setState(() {
          _isCompleted = true;
          _testResult = result['result'];
          _isSubmitting = false;
        });
      } else {
        // Move to next question
        setState(() {
          _currentQuestion = result['nextQuestion'];
          _selectedAnswer = null;
          _lastAnswerCorrect = null;
          _lastExplanation = null;
          _isSubmitting = false;
        });
        _progressController.forward(from: 0);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isSubmitting = false;
      });
    }
  }

  void _selectAnswer(int index) {
    if (_isSubmitting || _lastAnswerCorrect != null) return;
    HapticFeedback.selectionClick();
    setState(() {
      _selectedAnswer = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: _isCompleted ? null : _buildAppBar(),
      body: Stack(
        children: [
          if (_isLoading)
            _buildLoadingState()
          else if (_error != null)
            _buildErrorState()
          else if (_isCompleted)
            _buildCompletedState()
          else
            _buildTestContent(),
          
          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              gravity: 0.1,
              colors: [
                AppColors.purpleNeon,
                AppColors.pinkNeon,
                AppColors.cyanNeon,
                AppColors.xpGold,
                AppColors.successNeon,
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    // Progress based on answered questions
    final progressPercent = _totalQuestions > 0 
        ? ((_currentQuestionIndex) / _totalQuestions * 100).round().clamp(0, 100)
        : 0;
    
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
        onPressed: () => _showExitConfirmation(),
      ),
      title: Column(
        children: [
          Text(
            '$progressPercent% hoàn thành',
            style: AppTextStyles.labelMedium.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          _buildProgressBar(),
        ],
      ),
      actions: [
        // Difficulty badge
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getDifficultyColor().withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _getDifficultyColor().withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_getDifficultyIcon(), color: _getDifficultyColor(), size: 16),
              const SizedBox(width: 4),
              Text(
                _getDifficultyLabel(),
                style: AppTextStyles.labelSmall.copyWith(color: _getDifficultyColor()),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    // Clamp progress to max 1.0 (100%)
    final progress = _totalQuestions > 0 
        ? ((_currentQuestionIndex + 1) / _totalQuestions).clamp(0.0, 1.0)
        : 0.0;
    
    return Container(
      width: 150,
      height: 6,
      decoration: BoxDecoration(
        color: AppColors.bgTertiary,
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            gradient: AppGradients.primary,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.purpleNeon),
          const SizedBox(height: 24),
          Text(
            'Đang chuẩn bị bài kiểm tra...',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Hệ thống đang phân tích môn học để tạo câu hỏi phù hợp',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.errorNeon.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.errorNeon),
            ),
            const SizedBox(height: 24),
            Text(
              'Không thể tải bài kiểm tra',
              style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Đã xảy ra lỗi',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
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

  Widget _buildTestContent() {
    if (_currentQuestion == null) {
      return _buildLoadingState();
    }

    final question = _currentQuestion!['question'] as String? ?? '';
    final options = (_currentQuestion!['options'] as List?)?.cast<String>() ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Topic/Domain info
          if (_currentTopic.isNotEmpty || _currentDomain.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderPrimary),
              ),
              child: Row(
                children: [
                  Icon(Icons.topic_rounded, color: AppColors.cyanNeon, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _currentDomain.isNotEmpty ? '$_currentDomain > $_currentTopic' : _currentTopic,
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          // Question
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderPrimary),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: AppGradients.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.help_outline_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Câu hỏi',
                      style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  question,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Answer options
          ...options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            return _buildAnswerOption(index, option);
          }),
          
          // Option E: Skip this topic
          _buildSkipOption(),

          const SizedBox(height: 24),

          // Feedback (after answer)
          if (_lastAnswerCorrect != null)
            _buildFeedback(),

          const SizedBox(height: 24),

          // Submit button
          if (_lastAnswerCorrect == null)
            GamingButton(
              text: _isSubmitting ? 'Đang xử lý...' : 'Xác nhận',
              onPressed: _selectedAnswer != null && !_isSubmitting ? _submitAnswer : null,
              icon: _isSubmitting ? null : Icons.check_rounded,
              isLoading: _isSubmitting,
            ),
        ],
      ),
    );
  }

  Widget _buildAnswerOption(int index, String option) {
    final isSelected = _selectedAnswer == index;
    final isCorrectAnswer = _lastAnswerCorrect != null && 
        index == _currentQuestion!['correctAnswer'];
    final isWrongSelected = _lastAnswerCorrect == false && isSelected;

    Color borderColor = AppColors.borderPrimary;
    Color bgColor = AppColors.bgSecondary;
    Color textColor = AppColors.textPrimary;

    if (_lastAnswerCorrect != null) {
      if (isCorrectAnswer) {
        borderColor = AppColors.successNeon;
        bgColor = AppColors.successNeon.withOpacity(0.15);
        textColor = AppColors.successNeon;
      } else if (isWrongSelected) {
        borderColor = AppColors.errorNeon;
        bgColor = AppColors.errorNeon.withOpacity(0.15);
        textColor = AppColors.errorNeon;
      }
    } else if (isSelected) {
      borderColor = AppColors.purpleNeon;
      bgColor = AppColors.purpleNeon.withOpacity(0.15);
    }

    return GestureDetector(
      onTap: () => _selectAnswer(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            // Option letter
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected 
                    ? borderColor.withOpacity(0.2) 
                    : AppColors.bgTertiary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  String.fromCharCode(65 + index), // A, B, C, D
                  style: AppTextStyles.labelLarge.copyWith(
                    color: isSelected ? borderColor : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                option,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: textColor,
                  height: 1.4,
                ),
              ),
            ),
            if (_lastAnswerCorrect != null && isCorrectAnswer)
              Icon(Icons.check_circle_rounded, color: AppColors.successNeon, size: 24)
            else if (isWrongSelected)
              Icon(Icons.cancel_rounded, color: AppColors.errorNeon, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSkipOption() {
    final isSelected = _selectedAnswer == -1; // -1 = skip
    
    // Don't show if already answered
    if (_lastAnswerCorrect != null) {
      return const SizedBox.shrink();
    }
    
    return GestureDetector(
      onTap: () {
        if (_isSubmitting) return;
        HapticFeedback.selectionClick();
        setState(() {
          _selectedAnswer = -1; // Special value for skip
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, top: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.warningNeon.withOpacity(0.15) 
              : AppColors.bgTertiary.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.warningNeon : AppColors.borderPrimary,
            width: isSelected ? 2 : 1,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppColors.warningNeon.withOpacity(0.2) 
                    : AppColors.bgTertiary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(
                  Icons.skip_next_rounded,
                  color: isSelected ? AppColors.warningNeon : AppColors.textTertiary,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tôi không biết kiến thức này',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isSelected ? AppColors.warningNeon : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Bỏ qua và chuyển sang chủ đề khác',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedback() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (_lastAnswerCorrect ?? false)
            ? AppColors.successNeon.withOpacity(0.1)
            : AppColors.errorNeon.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (_lastAnswerCorrect ?? false)
              ? AppColors.successNeon.withOpacity(0.3)
              : AppColors.errorNeon.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                (_lastAnswerCorrect ?? false)
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                color: (_lastAnswerCorrect ?? false)
                    ? AppColors.successNeon
                    : AppColors.errorNeon,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                (_lastAnswerCorrect ?? false) ? 'Chính xác!' : 'Chưa đúng',
                style: AppTextStyles.labelLarge.copyWith(
                  color: (_lastAnswerCorrect ?? false)
                      ? AppColors.successNeon
                      : AppColors.errorNeon,
                ),
              ),
            ],
          ),
          if (_lastExplanation != null && _lastExplanation!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              _lastExplanation!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompletedState() {
    final score = _testResult?['score'] ?? 0;
    final level = _testResult?['level'] ?? 'beginner';
    final weakAreas = (_testResult?['weakAreas'] as List?)?.cast<String>() ?? [];
    final strongAreas = (_testResult?['strongAreas'] as List?)?.cast<String>() ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          
          // Congrats icon
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.purpleNeon.withOpacity(0.4),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 64),
          ),
          
          const SizedBox(height: 32),
          
          // Title
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [AppColors.purpleNeon, AppColors.pinkNeon],
            ).createShader(bounds),
            child: Text(
              'Hoàn thành!',
              style: AppTextStyles.h1.copyWith(color: Colors.white),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'Bạn đã hoàn thành bài kiểm tra đầu vào',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 32),
          
          // Score card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.borderPrimary),
            ),
            child: Column(
              children: [
                // Score
                Text(
                  '$score%',
                  style: AppTextStyles.numberXLarge.copyWith(
                    color: _getScoreColor(score),
                    fontSize: 64,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_correctAnswers}/${_currentQuestionIndex} câu đúng',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
                
                const SizedBox(height: 24),
                Divider(color: AppColors.borderPrimary),
                const SizedBox(height: 24),
                
                // Level badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: _getLevelGradient(level),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: _getLevelColor(level).withOpacity(0.4),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getLevelIcon(level), color: Colors.white, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        _getLevelLabel(level),
                        style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Strong areas
          if (strongAreas.isNotEmpty)
            _buildAreaSection(
              'Điểm mạnh',
              strongAreas,
              AppColors.successNeon,
              Icons.trending_up_rounded,
            ),
          
          // Weak areas
          if (weakAreas.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildAreaSection(
              'Cần cải thiện',
              weakAreas,
              AppColors.warningNeon,
              Icons.trending_down_rounded,
            ),
          ],
          
          const SizedBox(height: 32),
          
          // Action buttons
          GamingButton(
            text: 'Xem lộ trình cá nhân',
            onPressed: () {
              HapticFeedback.mediumImpact();
              // Navigate to personalized mind map (generated from test results)
              context.go('/subjects/${widget.subjectId}/personal-mind-map');
            },
            icon: Icons.route_rounded,
          ),
          
          const SizedBox(height: 12),
          
          TextButton(
            onPressed: () => context.go('/dashboard'),
            child: Text(
              'Quay về trang chủ',
              style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAreaSection(String title, List<String> areas, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTextStyles.labelLarge.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: areas.map((area) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                area,
                style: AppTextStyles.bodySmall.copyWith(color: color),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Thoát bài kiểm tra?',
          style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary),
        ),
        content: Text(
          'Tiến trình của bạn sẽ không được lưu.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Tiếp tục làm bài',
              style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(
              'Thoát',
              style: AppTextStyles.labelMedium.copyWith(color: AppColors.errorNeon),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getDifficultyColor() {
    switch (_currentDifficulty) {
      case 'advanced':
        return AppColors.errorNeon;
      case 'intermediate':
        return AppColors.warningNeon;
      default:
        return AppColors.successNeon;
    }
  }

  IconData _getDifficultyIcon() {
    switch (_currentDifficulty) {
      case 'advanced':
        return Icons.whatshot_rounded;
      case 'intermediate':
        return Icons.trending_up_rounded;
      default:
        return Icons.school_rounded;
    }
  }

  String _getDifficultyLabel() {
    switch (_currentDifficulty) {
      case 'advanced':
        return 'Nâng cao';
      case 'intermediate':
        return 'Trung bình';
      default:
        return 'Cơ bản';
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return AppColors.successNeon;
    if (score >= 60) return AppColors.warningNeon;
    return AppColors.errorNeon;
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case 'advanced':
        return AppColors.purpleNeon;
      case 'intermediate':
        return AppColors.cyanNeon;
      default:
        return AppColors.successNeon;
    }
  }

  LinearGradient _getLevelGradient(String level) {
    switch (level) {
      case 'advanced':
        return LinearGradient(colors: [AppColors.purpleNeon, AppColors.pinkNeon]);
      case 'intermediate':
        return LinearGradient(colors: [AppColors.cyanNeon, AppColors.successNeon]);
      default:
        return LinearGradient(colors: [AppColors.successNeon, AppColors.cyanNeon]);
    }
  }

  IconData _getLevelIcon(String level) {
    switch (level) {
      case 'advanced':
        return Icons.workspace_premium_rounded;
      case 'intermediate':
        return Icons.trending_up_rounded;
      default:
        return Icons.school_rounded;
    }
  }

  String _getLevelLabel(String level) {
    switch (level) {
      case 'advanced':
        return 'Nâng cao';
      case 'intermediate':
        return 'Trung bình';
      default:
        return 'Cơ bản';
    }
  }
}
