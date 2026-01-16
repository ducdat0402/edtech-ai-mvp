import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/core/widgets/typewriter_text.dart';

class OnboardingChatScreen extends StatefulWidget {
  const OnboardingChatScreen({super.key});

  @override
  State<OnboardingChatScreen> createState() => _OnboardingChatScreenState();
}

class _OnboardingChatScreenState extends State<OnboardingChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  final Set<int> _animatedMessages = {}; // Track which messages have been animated
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
          // Đánh dấu tất cả messages cũ đã được animated (không animate messages đã load từ history)
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
        // Start with welcome message - ưu tiên hỏi về mục tiêu học tập
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': 'Xin chào! 👋 Mình là AI tutor của bạn. Mình sẽ giúp bạn bắt đầu hành trình học tập thú vị!\n\nTrước tiên, bạn có thể cho mình biết bạn muốn học gì hoặc mục tiêu học tập của bạn là gì không? 🎯',
          });
        });
      }
    } catch (e) {
      // If error, start with welcome message - ưu tiên hỏi về mục tiêu học tập
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Onboarding'),
        actions: [
          if (_canProceed)
            TextButton(
              onPressed: _proceedToTest,
              child: const Text(
                'Xong / Test thôi',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final message = _messages[index];
                final isUser = message['role'] == 'user';
                final content = message['content'] ?? '';
                final shouldAnimate = !isUser && !_animatedMessages.contains(index);

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
                );
              },
            ),
          ),
          // Proceed Button - Always visible, enabled after 3 turns or when canProceed
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: (_canProceed || _isCompleted || _turnCount >= 3)
                  ? Colors.green.shade50
                  : Colors.grey.shade100,
              border: Border(
                top: BorderSide(
                  color: (_canProceed || _isCompleted || _turnCount >= 3)
                      ? Colors.green.shade200
                      : Colors.grey.shade300,
                ),
              ),
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (_canProceed || _isCompleted || _turnCount >= 3)
                      ? _proceedToTest
                      : null,
                  icon: Icon(
                    Icons.check_circle,
                    color: (_canProceed || _isCompleted || _turnCount >= 3)
                        ? Colors.white
                        : Colors.grey,
                  ),
                  label: Text(
                    _turnCount < 3 && !_canProceed && !_isCompleted
                        ? 'Hoàn thành thêm ${3 - _turnCount} câu hỏi để tiếp tục'
                        : 'Xong / Test thôi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: (_canProceed || _isCompleted || _turnCount >= 3)
                          ? Colors.white
                          : Colors.grey,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (_canProceed || _isCompleted || _turnCount >= 3)
                        ? Colors.green
                        : Colors.grey.shade300,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Nhập tin nhắn...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
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
                    onPressed: _isLoading ? null : _sendMessage,
                    icon: const Icon(Icons.send),
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

