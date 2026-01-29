import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/core/widgets/typewriter_text.dart';
<<<<<<< Updated upstream
=======
import 'package:edtech_mobile/theme/theme.dart';
>>>>>>> Stashed changes

class OnboardingChatScreen extends StatefulWidget {
  const OnboardingChatScreen({super.key});

  @override
  State<OnboardingChatScreen> createState() => _OnboardingChatScreenState();
}

class _OnboardingChatScreenState extends State<OnboardingChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
<<<<<<< Updated upstream
  final Set<int> _animatedMessages = {}; // Track which messages have been animated
=======
  final Set<int> _animatedMessages = {};
>>>>>>> Stashed changes
  bool _isLoading = false;
  String? _sessionId;
  bool _canProceed = false;
  bool _isCompleted = false;
  int _turnCount = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialMessage();
  }

  Future<void> _loadInitialMessage() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final status = await apiService.getOnboardingStatus();
      
        if (status['conversationHistory'] != null && 
          (status['conversationHistory'] as List).isNotEmpty) {
        final history = List<Map<String, dynamic>>.from(status['conversationHistory']);
        setState(() {
          final startIndex = _messages.length;
          _messages.addAll(history);
<<<<<<< Updated upstream
          // Đánh dấu tất cả messages cũ đã được animated (không animate messages đã load từ history)
=======
>>>>>>> Stashed changes
          for (int i = 0; i < history.length; i++) {
            if (history[i]['role'] == 'assistant') {
              _animatedMessages.add(startIndex + i);
            }
          }
          _sessionId = status['sessionId'];
          _canProceed = status['canProceed'] ?? false;
          _isCompleted = status['completed'] ?? false;
          _turnCount = _messages.where((m) => m['role'] == 'user').length;
        });
      } else {
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': 'Xin chào! 👋 Mình là AI tutor của bạn. Mình sẽ giúp bạn bắt đầu hành trình học tập thú vị!\n\nTrước tiên, bạn có thể cho mình biết bạn muốn học gì hoặc mục tiêu học tập của bạn là gì không? 🎯',
          });
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': 'Xin chào! 👋 Mình là AI tutor của bạn. Mình sẽ giúp bạn bắt đầu hành trình học tập thú vị!\n\nTrước tiên, bạn có thể cho mình biết bạn muốn học gì hoặc mục tiêu học tập của bạn là gì không? 🎯',
        });
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
      final response = await apiService.onboardingChat(
        message: message,
        sessionId: _sessionId,
      );

      final assistantMessage = response['response'] ?? 'Xin lỗi, tôi không hiểu. Bạn có thể nói lại được không?';
      
      setState(() {
        _sessionId = response['sessionId'] ?? _sessionId;
        _messages.add({
          'role': 'assistant',
          'content': assistantMessage,
        });
        _canProceed = response['canProceed'] ?? false;
        _isCompleted = response['completed'] ?? false;
        _turnCount = _messages.where((m) => m['role'] == 'user').length;
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': 'Xin lỗi, tôi gặp một chút vấn đề kỹ thuật. Bạn có thể thử lại được không? 😊',
        });
        _isLoading = false;
      });
      _scrollToBottom();
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

  void _proceedToTest() {
    context.go('/placement-test');
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canProceedNow = _canProceed || _isCompleted || _turnCount >= 3;

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
              child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text('AI Tutor', style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary)),
          ],
        ),
        actions: [
          if (canProceedNow)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: _proceedToTest,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: AppGradients.success,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Tiếp tục →',
                    style: AppTextStyles.labelSmall.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return _buildTypingIndicator();
                }

                final message = _messages[index];
                final isUser = message['role'] == 'user';
                final content = message['content'] ?? '';
                final shouldAnimate = !isUser && !_animatedMessages.contains(index);

<<<<<<< Updated upstream
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isUser
                          ? Colors.blue.shade600
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    child: shouldAnimate
                        ? TypeWriterText(
                            key: ValueKey('typewriter_$index'),
                            text: content,
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                            ),
                            speed: const Duration(milliseconds: 30),
                            onComplete: () {
                              setState(() {
                                _animatedMessages.add(index);
                              });
                            },
                          )
                        : Text(
                            content,
                            style: TextStyle(
                              color: isUser ? Colors.white : Colors.black87,
                              fontSize: 16,
                            ),
                          ),
                  ),
=======
                return _buildMessageBubble(
                  content: content,
                  isUser: isUser,
                  shouldAnimate: shouldAnimate,
                  index: index,
>>>>>>> Stashed changes
                );
              },
            ),
          ),

          // Proceed Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: canProceedNow
                  ? AppColors.successNeon.withOpacity(0.1)
                  : AppColors.bgSecondary,
              border: Border(
                top: BorderSide(
                  color: canProceedNow
                      ? AppColors.successNeon.withOpacity(0.3)
                      : AppColors.borderPrimary,
                ),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: GamingButton(
                text: _turnCount < 3 && !_canProceed && !_isCompleted
                    ? 'Trả lời thêm ${3 - _turnCount} câu để tiếp tục'
                    : 'Bắt đầu Placement Test',
                onPressed: canProceedNow ? _proceedToTest : null,
                gradient: canProceedNow ? AppGradients.success : null,
                glowColor: canProceedNow ? AppColors.successNeon : null,
                icon: canProceedNow ? Icons.play_arrow_rounded : Icons.lock_rounded,
              ),
            ),
          ),

          // Input field
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              border: Border(top: BorderSide(color: AppColors.borderPrimary)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.bgTertiary,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.borderPrimary),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Nhập tin nhắn...',
                          hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _isLoading ? null : () {
                      HapticFeedback.lightImpact();
                      _sendMessage();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: _isLoading ? null : AppGradients.primary,
                        color: _isLoading ? AppColors.bgTertiary : null,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _isLoading
                            ? null
                            : [
                                BoxShadow(
                                  color: AppColors.purpleNeon.withOpacity(0.4),
                                  blurRadius: 12,
                                ),
                              ],
                      ),
                      child: Icon(
                        Icons.send_rounded,
                        color: _isLoading ? AppColors.textTertiary : Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({
    required String content,
    required bool isUser,
    required bool shouldAnimate,
    required int index,
  }) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isUser ? AppGradients.primary : null,
          color: isUser ? null : AppColors.bgSecondary,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
          border: isUser ? null : Border.all(color: AppColors.borderPrimary),
          boxShadow: isUser
              ? [
                  BoxShadow(
                    color: AppColors.purpleNeon.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: shouldAnimate
            ? TypeWriterText(
                key: ValueKey('typewriter_$index'),
                text: content,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
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
                  color: isUser ? Colors.white : AppColors.textPrimary,
                ),
              ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderPrimary),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(0),
            const SizedBox(width: 4),
            _buildDot(1),
            const SizedBox(width: 4),
            _buildDot(2),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 200)),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.purpleNeon.withOpacity(0.3 + (value * 0.7)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
