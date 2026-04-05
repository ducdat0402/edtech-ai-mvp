import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/core/utils/navigation_helper.dart';
import 'package:edtech_mobile/core/widgets/typewriter_text.dart';
import 'package:edtech_mobile/theme/theme.dart';

class SubjectLearningGoalsScreen extends StatefulWidget {
  final String subjectId;

  const SubjectLearningGoalsScreen({
    super.key,
    required this.subjectId,
  });

  @override
  State<SubjectLearningGoalsScreen> createState() =>
      _SubjectLearningGoalsScreenState();
}

class _SubjectLearningGoalsScreenState
    extends State<SubjectLearningGoalsScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  final Set<int> _animatedMessages =
      {}; // Track which messages have been animated
  bool _isLoading = false;
  bool _isCompleted = false;
  bool _shouldSkipPlacementTest = false;
  Map<String, dynamic>? _extractedData;

  @override
  void initState() {
    super.initState();
    _startConversation();
  }

  Future<void> _startConversation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final response = await apiService.startLearningGoals(widget.subjectId);

      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': response['response'] as String? ??
              'Xin chào! Tôi sẽ giúp bạn xác định mục tiêu học tập.',
        });
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content':
              'Xin chào! Tôi sẽ giúp bạn xác định mục tiêu học tập. Bạn có thể cho tôi biết trình độ hiện tại của bạn không?',
        });
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isLoading) return;

    setState(() {
      _messages.add({
        'role': 'user',
        'content': message,
      });
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final response =
          await apiService.chatLearningGoals(widget.subjectId, message);

      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': response['response'] as String? ??
              'Xin lỗi, tôi không hiểu. Bạn có thể nói lại được không?',
        });
        _isCompleted = response['completed'] as bool? ?? false;
        _shouldSkipPlacementTest =
            response['shouldSkipPlacementTest'] as bool? ?? false;
        _extractedData = response['extractedData'] as Map<String, dynamic>?;
        _isLoading = false;
      });

      _scrollToBottom();

      // If conversation is completed, proceed to next step
      if (_isCompleted) {
        _proceedToLearning();
      }
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': 'Xin lỗi, có lỗi xảy ra. Vui lòng thử lại.',
        });
        _isLoading = false;
      });
    }
  }

  Future<void> _proceedToLearning() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final currentLevel = _extractedData?['currentLevel'] as String?;

    // Show loading
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    try {
      if (_shouldSkipPlacementTest || currentLevel == 'beginner') {
        // Skip placement test, generate skill tree with learning goals
        await apiService.generateSkillTreeWithGoals(widget.subjectId);

        if (mounted) {
          NavigationHelper.safePop(context);
          context.go('/skill-tree?subjectId=${widget.subjectId}');
        }
      } else {
        // Go to placement test
        if (mounted) {
          NavigationHelper.safePop(context);
          context.go('/placement-test?subjectId=${widget.subjectId}');
        }
      }
    } catch (e) {
      if (mounted) {
        NavigationHelper.safePop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: AppColors.errorNeon,
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Xác định mục tiêu học tập',
          style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message['role'] == 'user';
                final content = message['content'] as String? ?? '';
                final shouldAnimate =
                    !isUser && !_animatedMessages.contains(index);

                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color:
                          isUser ? AppColors.purpleNeon : AppColors.bgSecondary,
                      borderRadius: BorderRadius.circular(16),
                      border: isUser
                          ? null
                          : Border.all(color: const Color(0x332D363D)),
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    child: shouldAnimate
                        ? TypeWriterText(
                            key: ValueKey('typewriter_$index'),
                            text: content,
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.textPrimary),
                            speed: const Duration(milliseconds: 30),
                            onComplete: () {
                              setState(() {
                                _animatedMessages.add(index);
                              });
                            },
                          )
                        : Text(
                            content,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color:
                                  isUser ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(color: AppColors.primaryLight),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.bgSecondary,
              border: Border(
                top: BorderSide(color: Color(0x332D363D)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Nhập tin nhắn...',
                      hintStyle: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textTertiary),
                      filled: true,
                      fillColor: AppColors.bgTertiary,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: Color(0x332D363D)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: Color(0x332D363D)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                            color:
                                AppColors.primaryLight.withValues(alpha: 0.6)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send_rounded),
                  onPressed: _sendMessage,
                  color: AppColors.primaryLight,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
