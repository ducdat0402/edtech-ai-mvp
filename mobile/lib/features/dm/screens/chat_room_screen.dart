import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/core/services/dm_socket_service.dart';
import 'package:edtech_mobile/features/chat/widgets/emoji_bar.dart';
import 'package:edtech_mobile/theme/theme.dart';

class ChatRoomScreen extends StatefulWidget {
  final String peerId;
  final String peerName;

  const ChatRoomScreen({
    super.key,
    required this.peerId,
    required this.peerName,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  bool _hasMore = false;
  String? _firstCreatedAt;
  bool _sending = false;
  String? _typingUserId;
  String? _myUserId;
  Map<String, dynamic>? _replyTo;
  bool _showEmojiBar = false;

  @override
  void initState() {
    super.initState();
    _fetchMyUserId();
    _loadHistory();
    _connectSocket();
  }

  Future<void> _fetchMyUserId() async {
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final profile = await api.getUserProfile();
      if (mounted && profile['id'] != null) {
        setState(() => _myUserId = profile['id'] as String);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    final dmSocket = Provider.of<DmSocketService>(context, listen: false);
    dmSocket.onNewMessage = null;
    dmSocket.onTyping = null;
    super.dispose();
  }

  void _connectSocket() {
    final dmSocket = Provider.of<DmSocketService>(context, listen: false);
    dmSocket.connect();
    dmSocket.onNewMessage = (msg) {
      if (!mounted) return;
      final senderId = msg['senderId'] as String?;
      final receiverId = msg['receiverId'] as String?;
      if (senderId != widget.peerId && receiverId != widget.peerId) return;
      setState(() {
        _messages.add(msg);
      });
      _markRead();
    };
    dmSocket.onTyping = (userId) {
      if (!mounted) return;
      if (userId != widget.peerId) return;
      setState(() => _typingUserId = userId);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _typingUserId = null);
      });
    };
    dmSocket.onMessageDeleted = (messageId) {
      if (!mounted) return;
      setState(() =>
          _messages = _messages.where((m) => m['id'] != messageId).toList());
    };
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final data = await api.getDmConversation(widget.peerId, limit: 50);
      final list =
          (data['messages'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final hasMore = data['hasMore'] as bool? ?? false;
      if (list.isNotEmpty) {
        _firstCreatedAt = list.first['createdAt'] as String?;
      }
      if (mounted) {
        setState(() {
          _messages = list;
          _hasMore = hasMore;
          _loading = false;
        });
      }
      await _markRead();
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _firstCreatedAt == null) return;
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final data = await api.getDmConversation(widget.peerId,
          limit: 30, before: _firstCreatedAt);
      final list =
          (data['messages'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final hasMore = data['hasMore'] as bool? ?? false;
      if (list.isNotEmpty) {
        _firstCreatedAt = list.first['createdAt'] as String?;
      }
      if (mounted) {
        setState(() {
          _messages = [...list, ..._messages];
          _hasMore = hasMore;
        });
      }
    } catch (_) {}
  }

  Future<void> _markRead() async {
    try {
      await Provider.of<ApiService>(context, listen: false)
          .markDmAsRead(widget.peerId);
    } catch (_) {}
  }

  Future<void> _send() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _sending) return;

    final dmSocket = Provider.of<DmSocketService>(context, listen: false);
    if (!dmSocket.isConnected) {
      dmSocket.connect();
      await Future.delayed(const Duration(milliseconds: 500));
    }

    final replyToId = _replyTo?['id'] as String?;
    setState(() {
      _sending = true;
      _replyTo = null;
      _textController.clear();
    });
    HapticFeedback.lightImpact();
    dmSocket.sendMessage(widget.peerId, text, replyToId: replyToId);
    dmSocket.emitTyping(widget.peerId);
    setState(() => _sending = false);
  }

  void _onEmojiTap(String emoji) {
    final text = _textController.text;
    final selection = _textController.selection;
    final start = selection.start.clamp(0, text.length);
    final end = selection.end.clamp(0, text.length);
    _textController.text =
        text.substring(0, start) + emoji + text.substring(end);
    _textController.selection =
        TextSelection.collapsed(offset: start + emoji.length);
  }

  void _showMessageActions(BuildContext context, Map<String, dynamic> msg) {
    final senderId = msg['senderId'] as String? ?? '';
    final isMe =
        _myUserId != null ? senderId == _myUserId : senderId != widget.peerId;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.bgSecondary,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading:
                  const Icon(Icons.reply_rounded, color: AppColors.purpleNeon),
              title: const Text('Trả lời',
                  style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                setState(() {
                  _replyTo = {
                    'id': msg['id'],
                    'content': msg['content'] ?? '',
                  };
                  _showEmojiBar = false;
                });
              },
            ),
            if (isMe)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.pinkNeon),
                title: const Text('Xóa tin nhắn',
                    style: TextStyle(color: AppColors.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDelete(msg['id'] as String);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(String messageId) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        title: const Text('Xóa tin nhắn?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('Tin nhắn sẽ bị xóa vĩnh viễn.',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Xóa', style: TextStyle(color: AppColors.pinkNeon)),
          ),
        ],
      ),
    ).then((ok) async {
      if (ok != true) return;
      try {
        await Provider.of<ApiService>(context, listen: false)
            .deleteDmMessage(messageId);
        if (mounted) {
          setState(() {
            _messages = _messages.where((m) => m['id'] != messageId).toList();
            if (_replyTo?['id'] == messageId) _replyTo = null;
          });
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Không thể xóa tin nhắn'),
                backgroundColor: Colors.red),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgSecondary,
        title: Text(widget.peerName,
            style: const TextStyle(color: AppColors.textPrimary)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.purpleNeon))
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: _messages.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Center(
                            child: TextButton(
                              onPressed: _loadMore,
                              child: const Text('Tải thêm',
                                  style:
                                      TextStyle(color: AppColors.purpleNeon)),
                            ),
                          ),
                        );
                      }
                      final msg = _messages[_messages.length - 1 - index];
                      return _buildMessageBubble(msg);
                    },
                  ),
          ),
          if (_typingUserId != null)
            const Padding(
              padding: EdgeInsets.only(left: 16, bottom: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('đang gõ...',
                    style:
                        TextStyle(color: AppColors.textTertiary, fontSize: 12)),
              ),
            ),
          Container(
            color: AppColors.bgSecondary,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_replyTo != null)
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 8, 8, 4),
                    color: AppColors.bgTertiary.withOpacity(0.5),
                    child: Row(
                      children: [
                        const Icon(Icons.reply_rounded,
                            size: 18, color: AppColors.purpleNeon),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            (_replyTo!['content'] as String? ?? '').length > 50
                                ? '${(_replyTo!['content'] as String).substring(0, 50)}...'
                                : (_replyTo!['content'] as String? ?? ''),
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          color: AppColors.textTertiary,
                          onPressed: () => setState(() => _replyTo = null),
                        ),
                      ],
                    ),
                  ),
                if (_showEmojiBar) EmojiBar(onEmojiTap: _onEmojiTap),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: SafeArea(
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            _showEmojiBar
                                ? Icons.keyboard_rounded
                                : Icons.emoji_emotions_outlined,
                            color: AppColors.purpleNeon,
                          ),
                          onPressed: () =>
                              setState(() => _showEmojiBar = !_showEmojiBar),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            style:
                                const TextStyle(color: AppColors.textPrimary),
                            decoration: InputDecoration(
                              hintText: 'Nhắn tin...',
                              hintStyle: const TextStyle(
                                  color: AppColors.textTertiary),
                              filled: true,
                              fillColor: AppColors.bgTertiary,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                            ),
                            onSubmitted: (_) => _send(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: _send,
                          icon: const Icon(Icons.send_rounded,
                              color: Colors.white),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.purpleNeon,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final senderId = msg['senderId'] as String? ?? '';
    final content = msg['content'] as String? ?? '';
    final createdAt = msg['createdAt'] as String?;
    final isMe =
        _myUserId != null ? senderId == _myUserId : senderId != widget.peerId;
    final replyTo = msg['replyTo'];
    final replyContent =
        replyTo is Map ? (replyTo['content'] as String? ?? '') : '';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _showMessageActions(context, msg),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(
            color: isMe
                ? AppColors.purpleNeon.withOpacity(0.3)
                : AppColors.bgTertiary,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMe ? 16 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 16),
            ),
            border: Border.all(
              color: isMe
                  ? AppColors.purpleNeon.withOpacity(0.5)
                  : AppColors.borderPrimary,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (replyContent.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.only(bottom: 8),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    border: Border(
                        left: BorderSide(
                            color: AppColors.purpleNeon.withOpacity(0.6),
                            width: 3)),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      replyContent.length > 50
                          ? '${replyContent.substring(0, 50)}...'
                          : replyContent,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              Text(
                content,
                style:
                    const TextStyle(color: AppColors.textPrimary, fontSize: 15),
              ),
              if (createdAt != null) ...[
                const SizedBox(height: 4),
                Text(
                  _formatTime(createdAt),
                  style: const TextStyle(
                      color: AppColors.textTertiary, fontSize: 10),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final now = DateTime.now();
      if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
      return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}
