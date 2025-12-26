import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:edtech_mobile/core/services/api_service.dart';

class PlacementTestScreen extends StatefulWidget {
  const PlacementTestScreen({super.key});

  @override
  State<PlacementTestScreen> createState() => _PlacementTestScreenState();
}

class _PlacementTestScreenState extends State<PlacementTestScreen> {
  Map<String, dynamic>? _currentQuestion;
  bool _isLoading = true;
  String? _error;
  int? _selectedAnswer;
  bool _isSubmitting = false;
  int _currentQuestionNumber = 1;
  int _totalQuestions = 10;
  bool _isLoadingNextQuestion = false;

  @override
  void initState() {
    super.initState();
    _startTest();
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
      
      // Parse response - get first question from questions array
      Map<String, dynamic>? question;
      
      print('📦 Placement test response keys: ${response.keys}');
      
      if (response['questions'] != null && (response['questions'] as List).isNotEmpty) {
        // Get first question from questions array (from startTest response)
        final questions = response['questions'] as List;
        print('✅ Found ${questions.length} questions in array');
        final firstQuestion = questions[0] as Map<String, dynamic>;
        question = {
          'id': firstQuestion['questionId'],
          'question': firstQuestion['question'],
          'options': firstQuestion['options'],
          'difficulty': firstQuestion['difficulty'],
        };
        print('✅ Parsed first question: ${question['question']}');
        
        // Set progress: first question, total 10
        _currentQuestionNumber = 1;
        _totalQuestions = 10;
      } else {
        // Try to get current question from API
        try {
          final currentTestResponse = await apiService.getCurrentTest();
          if (currentTestResponse['question'] != null) {
            question = currentTestResponse['question'];
            if (currentTestResponse['progress'] != null) {
              _currentQuestionNumber = currentTestResponse['progress']['current'] ?? 1;
              _totalQuestions = currentTestResponse['progress']['total'] ?? 10;
            }
            print('✅ Got question from getCurrentTest');
          }
        } catch (e) {
          print('⚠️  Error getting current test: $e');
        }
      }
      
      setState(() {
        _currentQuestion = question;
        _isLoading = false;
      });
      
      if (question == null) {
        print('❌ No question available!');
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

    setState(() {
      _isSubmitting = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final response = await apiService.submitAnswer(_selectedAnswer!);

      // Update progress
      if (response['progress'] != null) {
        _currentQuestionNumber = response['progress']['current'] ?? _currentQuestionNumber + 1;
        _totalQuestions = response['progress']['total'] ?? 10;
      } else {
        _currentQuestionNumber++;
      }

      if (response['completed'] == true) {
        // Navigate to analysis screen
        if (mounted) {
          context.go('/placement-test/analysis/${response['test']?['id']}');
        }
      } else {
        // Check if next question is available
        if (response['nextQuestion'] != null) {
          // Show next question immediately
          setState(() {
            _currentQuestion = response['nextQuestion'];
            _selectedAnswer = null;
            _isSubmitting = false;
            _isLoadingNextQuestion = false;
          });
        } else {
          // Next question not ready, start polling
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
          // Question is ready
          if (response['progress'] != null) {
            final progress = response['progress'] as Map<String, dynamic>;
            _currentQuestionNumber = progress['current'] ?? _currentQuestionNumber;
            _totalQuestions = progress['total'] ?? 10;
          } else {
            // If no progress in response, increment manually
            _currentQuestionNumber++;
          }
          
          setState(() {
            _currentQuestion = response['question'];
            _isLoadingNextQuestion = false;
          });
          return;
        }
      } catch (e) {
        print('⚠️  Error polling for question: $e');
      }
      
      retryCount++;
    }
    
    // Max retries reached
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
      appBar: AppBar(
        title: const Text('Placement Test'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _startTest,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _currentQuestion == null
                  ? const Center(child: Text('No question available'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Progress indicator
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Câu hỏi $_currentQuestionNumber / $_totalQuestions',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                LinearProgressIndicator(
                                  value: _currentQuestionNumber / _totalQuestions,
                                  backgroundColor: Colors.blue.shade100,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                  minHeight: 8,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Loading next question indicator
                          if (_isLoadingNextQuestion)
                            Container(
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.orange.shade200),
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Đang tải câu hỏi tiếp theo...',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.orange.shade900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          // Question
                          Text(
                            _currentQuestion!['question'] ?? 'Question',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ...List.generate(
                            (_currentQuestion!['options'] as List?)?.length ?? 0,
                            (index) {
                              final option = (_currentQuestion!['options'] as List)[index];
                              final isSelected = _selectedAnswer == index;
                              
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedAnswer = index;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.blue.shade100
                                          : Colors.grey.shade100,
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.blue
                                            : Colors.grey.shade300,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isSelected
                                                ? Colors.blue
                                                : Colors.transparent,
                                            border: Border.all(
                                              color: isSelected
                                                  ? Colors.blue
                                                  : Colors.grey,
                                              width: 2,
                                            ),
                                          ),
                                          child: isSelected
                                              ? const Icon(
                                                  Icons.check,
                                                  size: 16,
                                                  color: Colors.white,
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            option.toString(),
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _selectedAnswer != null && !_isSubmitting
                                  ? _submitAnswer
                                  : null,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Submit Answer'),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}

