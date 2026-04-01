import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/core/widgets/app_bar_leading_back_home.dart';
import 'package:edtech_mobile/core/widgets/bottom_nav_bar.dart';
import 'package:edtech_mobile/core/widgets/empty_state.dart';
import 'package:edtech_mobile/theme/theme.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  List<dynamic> _conversations = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final list = await api.getDmConversations();
      if (mounted) {
        setState(() {
          _conversations = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgSecondary,
        leading: const AppBarLeadingBackAndHome(),
        leadingWidth: 112,
        automaticallyImplyLeading: false,
        title: const Text('Tin nhắn',
            style: TextStyle(color: AppColors.textPrimary)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.purpleNeon))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.errorNeon, size: 48),
                      const SizedBox(height: 16),
                      Text(_error!,
                          style:
                              const TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                          onPressed: _load, child: const Text('Thử lại')),
                    ],
                  ),
                )
              : _conversations.isEmpty
                  ? const EmptyStateWidget(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'Chưa có cuộc trò chuyện',
                      message:
                          'Chỉ nhắn tin được với bạn bè. Kết bạn rồi quay lại đây!',
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.purpleNeon,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _conversations.length,
                        itemBuilder: (context, index) {
                          final c =
                              _conversations[index] as Map<String, dynamic>;
                          return _buildConversationTile(c);
                        },
                      ),
                    ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
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
}
