import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/theme/theme.dart';

class WorldChatScreen extends StatefulWidget {
  const WorldChatScreen({super.key});

  @override
  State<WorldChatScreen> createState() => _WorldChatScreenState();
}

class _WorldChatScreenState extends State<WorldChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  int _onlineCount = 0;
  bool _isLoading = true;
  bool _isSending = false;
  Timer? _pollTimer;
  String? _lastMessageTime;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => _pollNewMessages());
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final data = await apiService.getUserProfile();
      if (mounted) setState(() => _currentUserId = data['id'] as String?);
    } catch (_) {}
  }

  Future<void> _loadMessages() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final data = await apiService.getChatMessages();
      if (mounted) {
        final msgs = (data['messages'] as List<dynamic>? ?? [])
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
        setState(() {
          _messages = msgs;
          _onlineCount = data['onlineCount'] as int? ?? 0;
          _isLoading = false;
          if (msgs.isNotEmpty) {
            _lastMessageTime = msgs.last['createdAt'] as String?;
          }
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pollNewMessages() async {
    if (_lastMessageTime == null) return;
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final data = await apiService.getChatMessages(after: _lastMessageTime);
      final newMsgs = (data['messages'] as List<dynamic>? ?? [])
          .map((m) => Map<String, dynamic>.from(m))
          .toList();

      if (mounted && newMsgs.isNotEmpty) {
        setState(() {
          _messages.addAll(newMsgs);
          _onlineCount = data['onlineCount'] as int? ?? _onlineCount;
          _lastMessageTime = newMsgs.last['createdAt'] as String?;
        });
        _scrollToBottom();
      }
    } catch (_) {}
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

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();
    HapticFeedback.lightImpact();

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final msg = await apiService.sendChatMessage(text);

      if (mounted) {
        setState(() {
          _messages.add(Map<String, dynamic>.from(msg));
          _lastMessageTime = msg['createdAt'] as String?;
          _isSending = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_extractError(e)),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  String _extractError(dynamic e) {
    final str = e.toString();
    final match = RegExp(r'"message":"([^"]+)"').firstMatch(str);
    return match?.group(1) ?? 'Có lỗi xảy ra';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        title: Row(
          children: [
            const Icon(Icons.public_rounded, color: AppColors.cyanNeon, size: 22),
            const SizedBox(width: 8),
            Text('Chat thế giới', style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary)),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.successNeon.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(color: AppColors.successNeon, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '$_onlineCount',
                    style: const TextStyle(color: AppColors.successNeon, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded, size: 56, color: AppColors.textTertiary),
                            const SizedBox(height: 12),
                            Text('Chưa có tin nhắn', style: TextStyle(color: AppColors.textSecondary)),
                            const SizedBox(height: 4),
                            Text('Hãy là người đầu tiên!', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMe = msg['userId'] == _currentUserId;
                          final showAvatar = index == 0 ||
                              _messages[index - 1]['userId'] != msg['userId'];
                          return _buildMessageBubble(msg, isMe, showAvatar);
                        },
                      ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isMe, bool showAvatar) {
    final username = msg['username'] as String? ?? 'Anonymous';
    final message = msg['message'] as String? ?? '';
    final level = msg['userLevel'] as int? ?? 1;
    final createdAt = msg['createdAt'] as String?;
    final time = _formatTime(createdAt);

    return Padding(
      padding: EdgeInsets.only(
        top: showAvatar ? 10 : 2,
        left: isMe ? 48 : 0,
        right: isMe ? 0 : 48,
      ),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (showAvatar && !isMe)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    username,
                    style: TextStyle(
                      color: _getUserColor(username),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.purpleNeon.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Lv.$level',
                      style: const TextStyle(color: AppColors.purpleNeon, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? AppColors.cyanNeon.withOpacity(0.15) : AppColors.bgSecondary,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
              border: Border.all(
                color: isMe ? AppColors.cyanNeon.withOpacity(0.25) : AppColors.borderPrimary,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14.5,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 8,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        border: Border(top: BorderSide(color: AppColors.borderPrimary)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.bgTertiary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Nhập tin nhắn...',
                  hintStyle: TextStyle(color: AppColors.textTertiary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                maxLines: 3,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _isSending ? AppColors.bgTertiary : AppColors.cyanNeon,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.send_rounded,
                color: _isSending ? AppColors.textTertiary : Colors.black,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getUserColor(String username) {
    final colors = [
      AppColors.cyanNeon,
      AppColors.purpleNeon,
      AppColors.pinkNeon,
      AppColors.orangeNeon,
      AppColors.coinGold,
      AppColors.successNeon,
    ];
    return colors[username.hashCode.abs() % colors.length];
  }

  String _formatTime(String? isoString) {
    if (isoString == null) return '';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final now = DateTime.now();
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
      return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}
