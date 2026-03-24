import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/core/widgets/empty_state.dart';
import 'package:edtech_mobile/features/chat/widgets/emoji_bar.dart';
import 'package:edtech_mobile/core/widgets/app_bar_leading_back_home.dart';
import 'package:edtech_mobile/theme/theme.dart';

class WorldChatScreen extends StatefulWidget {
  const WorldChatScreen({super.key});

  @override
  State<WorldChatScreen> createState() => _WorldChatScreenState();
}

class _WorldChatScreenState extends State<WorldChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  int _onlineCount = 0;
  bool _isLoading = true;
  bool _isSending = false;
  Timer? _pollTimer;
  String? _lastMessageTime;
  String? _currentUserId;
  Map<String, dynamic>? _replyTo;
  bool _showEmojiBar = false;

  late TabController _tabController;
  List<dynamic> _conversations = [];
  bool _conversationsLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadMessages();
    _pollTimer =
        Timer.periodic(const Duration(seconds: 4), (_) => _pollNewMessages());
    _loadCurrentUser();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging && _tabController.index == 1) {
      _loadConversations();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _pollTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    setState(() => _conversationsLoading = true);
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final list = await api.getDmConversations();
      if (mounted) {
        setState(() {
          _conversations = list;
          _conversationsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _conversationsLoading = false);
    }
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
          _messages = _mergeMessages(_messages, msgs);
          _onlineCount = data['onlineCount'] as int? ?? 0;
          _isLoading = false;
          if (_messages.isNotEmpty) {
            _lastMessageTime = _messages.last['createdAt'] as String?;
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
          _messages = _mergeMessages(_messages, newMsgs);
          _onlineCount = data['onlineCount'] as int? ?? _onlineCount;
          if (_messages.isNotEmpty) {
            _lastMessageTime = _messages.last['createdAt'] as String?;
          }
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

    final replyToId = _replyTo?['id'] as String?;
    setState(() {
      _isSending = true;
      _replyTo = null;
      _messageController.clear();
    });
    HapticFeedback.lightImpact();

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final msg = await apiService.sendChatMessage(text, replyToId: replyToId);

      if (mounted) {
        setState(() {
          _messages = _mergeMessages(
            _messages,
            [Map<String, dynamic>.from(msg)],
          );
          if (_messages.isNotEmpty) {
            _lastMessageTime = _messages.last['createdAt'] as String?;
          }
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

  void _onEmojiTap(String emoji) {
    final text = _messageController.text;
    final selection = _messageController.selection;
    final start = selection.start.clamp(0, text.length);
    final end = selection.end.clamp(0, text.length);
    _messageController.text =
        text.substring(0, start) + emoji + text.substring(end);
    _messageController.selection =
        TextSelection.collapsed(offset: start + emoji.length);
  }

  Future<void> _deleteMessage(String messageId) async {
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      await api.deleteWorldChatMessage(messageId);
      if (mounted) {
        setState(() {
          _messages = _messages.where((m) => m['id'] != messageId).toList();
          if (_replyTo?['id'] == messageId) _replyTo = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(_extractError(e)),
              backgroundColor: Colors.red.shade700),
        );
      }
    }
  }

  List<Map<String, dynamic>> _mergeMessages(
    List<Map<String, dynamic>> existing,
    List<Map<String, dynamic>> incoming,
  ) {
    if (incoming.isEmpty) return existing;

    final seenIds = <String>{};
    final result = <Map<String, dynamic>>[];

    for (final m in existing) {
      final id = m['id'] as String?;
      if (id != null) {
        seenIds.add(id);
      }
      result.add(m);
    }

    for (final m in incoming) {
      final id = m['id'] as String?;
      if (id != null && seenIds.contains(id)) continue;
      if (id != null) seenIds.add(id);
      result.add(m);
    }

    result.sort((a, b) {
      final ta = DateTime.tryParse(a['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final tb = DateTime.tryParse(b['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return ta.compareTo(tb);
    });

    return result;
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
            const Icon(Icons.chat_rounded, color: AppColors.cyanNeon, size: 22),
            const SizedBox(width: 8),
            Text('Chat',
                style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary)),
            if (_tabController.index == 0) ...[
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
                      decoration: const BoxDecoration(
                          color: AppColors.successNeon, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '$_onlineCount',
                      style: const TextStyle(
                          color: AppColors.successNeon,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        leading: const AppBarLeadingBackAndHome(),
        leadingWidth: 112,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.cyanNeon,
          labelColor: AppColors.cyanNeon,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(
                text: 'Chat thế giới',
                icon: Icon(Icons.public_rounded, size: 20)),
            Tab(text: 'Bạn bè', icon: Icon(Icons.people_rounded, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWorldChatTab(),
          _buildFriendsChatTab(),
        ],
      ),
    );
  }

  Widget _buildWorldChatTab() {
    return Column(
      children: [
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.cyanNeon))
              : _messages.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded,
                              size: 56, color: AppColors.textTertiary),
                          SizedBox(height: 12),
                          Text('Chưa có tin nhắn',
                              style: TextStyle(color: AppColors.textSecondary)),
                          SizedBox(height: 4),
                          Text('Hãy là người đầu tiên!',
                              style: TextStyle(
                                  color: AppColors.textTertiary, fontSize: 13)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
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
    );
  }

  Widget _buildFriendsChatTab() {
    if (_conversationsLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.purpleNeon));
    }
    if (_conversations.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.people_outline_rounded,
        title: 'Chưa có cuộc trò chuyện',
        message: 'Chỉ nhắn tin được với bạn bè. Vào tab Bạn bè để kết bạn!',
      );
    }
    return RefreshIndicator(
      onRefresh: _loadConversations,
      color: AppColors.purpleNeon,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _conversations.length,
        itemBuilder: (context, index) {
          final c = _conversations[index] as Map<String, dynamic>;
          return _buildConversationTile(c);
        },
      ),
    );
  }

  Widget _buildConversationTile(Map<String, dynamic> c) {
    final peerId = c['peerId'] as String? ?? '';
    final peerName = c['peerName'] as String? ?? 'User';
    final last = c['lastMessage'] as Map<String, dynamic>?;
    final unread = c['unreadCount'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderPrimary),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: AppColors.purpleNeon.withOpacity(0.2),
          child: Text(
            peerName.isNotEmpty ? peerName[0].toUpperCase() : '?',
            style: const TextStyle(
                color: AppColors.purpleNeon, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          peerName,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: unread > 0 ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        subtitle: last != null
            ? Text(
                last['content'] as String? ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              )
            : const Text(
                'Nhắn tin...',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
              ),
        trailing: unread > 0
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.purpleNeon,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  unread > 99 ? '99+' : '$unread',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              )
            : null,
        onTap: () =>
            context.push('/dm/chat/$peerId', extra: {'peerName': peerName}),
      ),
    );
  }

  void _showMessageActions(
      BuildContext context, Map<String, dynamic> msg, bool isMe) {
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
                  const Icon(Icons.reply_rounded, color: AppColors.cyanNeon),
              title: const Text('Trả lời',
                  style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                setState(() {
                  _replyTo = {
                    'id': msg['id'],
                    'username': msg['username'] ?? 'Anonymous',
                    'message': msg['message'] ?? '',
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
    ).then((ok) {
      if (ok == true) _deleteMessage(messageId);
    });
  }

  Widget _buildMessageBubble(
      Map<String, dynamic> msg, bool isMe, bool showAvatar) {
    final username = msg['username'] as String? ?? 'Anonymous';
    final message = msg['message'] as String? ?? '';
    final level = msg['userLevel'] as int? ?? 1;
    final createdAt = msg['createdAt'] as String?;
    final time = _formatTime(createdAt);
    final replyTo = msg['replyTo'];
    final replyUsername =
        replyTo is Map ? (replyTo['username'] as String? ?? '') : '';
    final replySnippet =
        replyTo is Map ? (replyTo['message'] as String? ?? '') : '';

    return Padding(
      padding: EdgeInsets.only(
        top: showAvatar ? 10 : 2,
        left: isMe ? 48 : 0,
        right: isMe ? 0 : 48,
      ),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.purpleNeon.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Lv.$level',
                      style: const TextStyle(
                          color: AppColors.purpleNeon,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          GestureDetector(
            onLongPress: () => _showMessageActions(context, msg, isMe),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe
                    ? AppColors.cyanNeon.withOpacity(0.15)
                    : AppColors.bgSecondary,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                border: Border.all(
                  color: isMe
                      ? AppColors.cyanNeon.withOpacity(0.25)
                      : AppColors.borderPrimary,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (replyUsername.isNotEmpty || replySnippet.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.only(bottom: 8),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        border: Border(
                            left: BorderSide(
                                color: AppColors.cyanNeon.withOpacity(0.6),
                                width: 3)),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              replyUsername,
                              style: const TextStyle(
                                color: AppColors.cyanNeon,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              replySnippet.length > 60
                                  ? '${replySnippet.substring(0, 60)}...'
                                  : replySnippet,
                              style: const TextStyle(
                                  color: AppColors.textSecondary, fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  Text(
                    message,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14.5,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: const TextStyle(
                        color: AppColors.textTertiary, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgSecondary,
        border: Border(top: BorderSide(color: AppColors.borderPrimary)),
      ),
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
                      size: 18, color: AppColors.cyanNeon),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _replyTo!['username'] as String? ?? '',
                          style: const TextStyle(
                              color: AppColors.cyanNeon,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                        Text(
                          (_replyTo!['message'] as String? ?? '').length > 50
                              ? '${(_replyTo!['message'] as String).substring(0, 50)}...'
                              : (_replyTo!['message'] as String? ?? ''),
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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
            padding: EdgeInsets.only(
              left: 12,
              right: 8,
              top: 10,
              bottom: MediaQuery.of(context).padding.bottom + 10,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _showEmojiBar
                        ? Icons.keyboard_rounded
                        : Icons.emoji_emotions_outlined,
                    color: AppColors.cyanNeon,
                  ),
                  onPressed: () =>
                      setState(() => _showEmojiBar = !_showEmojiBar),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.bgTertiary,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 15),
                      decoration: const InputDecoration(
                        hintText: 'Nhập tin nhắn...',
                        hintStyle: TextStyle(color: AppColors.textTertiary),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
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
                      color: _isSending
                          ? AppColors.bgTertiary
                          : AppColors.cyanNeon,
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
