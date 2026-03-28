import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:edtech_mobile/core/config/api_config.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/theme/theme.dart';

/// Bảng tin cộng đồng: đăng status, like/dislike, bình luận, xem hồ sơ user.
class CommunityFeedTab extends StatefulWidget {
  const CommunityFeedTab({super.key});

  @override
  State<CommunityFeedTab> createState() => _CommunityFeedTabState();
}

class _CommunityFeedTabState extends State<CommunityFeedTab> {
  final List<Map<String, dynamic>> _items = [];
  String? _nextCursor;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  String? _myUserId;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final api = Provider.of<ApiService>(context, listen: false);
    try {
      final me = await api.getUserProfile();
      if (mounted) setState(() => _myUserId = me['id']?.toString());
    } catch (_) {}
    await _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
      _nextCursor = null;
    });
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final data = await api.listCommunityStatuses(limit: 20);
      final raw = data['items'] as List? ?? const [];
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(raw.map((e) => Map<String, dynamic>.from(e as Map)));
        _nextCursor = data['nextCursor'] as String?;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_nextCursor == null || _loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final data = await api.listCommunityStatuses(limit: 20, before: _nextCursor);
      final raw = data['items'] as List? ?? const [];
      if (!mounted) return;
      setState(() {
        _items.addAll(raw.map((e) => Map<String, dynamic>.from(e as Map)));
        _nextCursor = data['nextCursor'] as String?;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _composeStatus() async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        title: const Text('Đăng status', style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: controller,
          maxLines: 5,
          maxLength: 2000,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Chia sẻ điều gì đó với cộng đồng…',
            hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.8)),
            filled: true,
            fillColor: AppColors.bgTertiary,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.purpleNeon),
            child: const Text('Đăng'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final text = controller.text.trim();
    if (text.isEmpty) return;
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final created = await api.createCommunityStatus(text);
      if (!mounted) return;
      setState(() => _items.insert(0, Map<String, dynamic>.from(created)));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã đăng status'), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không đăng được: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _react(Map<String, dynamic> item, String kind) async {
    final id = item['id']?.toString();
    if (id == null) return;
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final r = await api.reactCommunityStatus(id, kind);
      if (!mounted) return;
      setState(() {
        item['likeCount'] = r['likeCount'];
        item['dislikeCount'] = r['dislikeCount'];
        item['myReaction'] = r['myReaction'];
      });
    } catch (_) {}
  }

  Future<void> _openComments(Map<String, dynamic> item) async {
    final statusId = item['id']?.toString();
    if (statusId == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgSecondary,
      builder: (ctx) => _CommentsSheet(statusId: statusId),
    );
  }

  Future<void> _openUserProfile(String userId) async {
    final api = Provider.of<ApiService>(context, listen: false);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgSecondary,
      builder: (ctx) => _UserProfileSheet(api: api, userId: userId, myUserId: _myUserId),
    );
  }

  Future<void> _deleteOwn(Map<String, dynamic> item) async {
    final id = item['id']?.toString();
    if (id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        title: const Text('Xóa status?', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Status sẽ bị xóa vĩnh viễn.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa', style: TextStyle(color: AppColors.errorNeon)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      await api.deleteCommunityStatus(id);
      if (!mounted) return;
      setState(() => _items.removeWhere((e) => e['id']?.toString() == id));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  String _timeAgo(String? iso) {
    final dt = DateTime.tryParse(iso ?? '');
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    return '${diff.inDays} ngày trước';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.purpleNeon));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _refresh, child: const Text('Thử lại')),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.purpleNeon,
          child: _items.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 120),
                    Center(
                      child: Text(
                        'Chưa có status nào.\nHãy là người đầu tiên đăng!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary, height: 1.4),
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
                  itemCount: _items.length + (_nextCursor != null ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _items.length && _nextCursor != null) {
                      if (!_loadingMore) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) _loadMore();
                        });
                      }
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: CircularProgressIndicator(color: AppColors.purpleNeon),
                        ),
                      );
                    }
                    final item = _items[index];
                    final author = item['author'] as Map<String, dynamic>? ?? {};
                    final authorId = author['id']?.toString() ?? '';
                    final name = author['fullName']?.toString() ?? 'User';
                    final avatarUrl = ApiConfig.absoluteMediaUrl(author['avatarUrl']?.toString());
                    final isMine = _myUserId != null && authorId == _myUserId;
                    final myReaction = item['myReaction'] as String?;
                    final likeCount = item['likeCount'] as int? ?? 0;
                    final dislikeCount = item['dislikeCount'] as int? ?? 0;
                    final commentCount = item['commentCount'] as int? ?? 0;

                    return Card(
                      color: AppColors.bgSecondary,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: AppColors.borderPrimary),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                InkWell(
                                  onTap: authorId.isEmpty ? null : () => _openUserProfile(authorId),
                                  borderRadius: BorderRadius.circular(24),
                                  child: CircleAvatar(
                                    radius: 22,
                                    backgroundColor: AppColors.purpleNeon.withValues(alpha: 0.2),
                                    backgroundImage: avatarUrl.isNotEmpty
                                        ? CachedNetworkImageProvider(avatarUrl)
                                        : null,
                                    child: avatarUrl.isEmpty
                                        ? Text(
                                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                                            style: const TextStyle(
                                              color: AppColors.purpleNeon,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      InkWell(
                                        onTap: authorId.isEmpty ? null : () => _openUserProfile(authorId),
                                        child: Text(
                                          name,
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        _timeAgo(item['createdAt']?.toString()),
                                        style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isMine)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: AppColors.textTertiary),
                                    onPressed: () => _deleteOwn(item),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              item['content']?.toString() ?? '',
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.35),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                _ReactionChip(
                                  icon: Icons.thumb_up_outlined,
                                  activeIcon: Icons.thumb_up,
                                  label: '$likeCount',
                                  active: myReaction == 'like',
                                  color: AppColors.successNeon,
                                  onTap: () => _react(item, 'like'),
                                ),
                                const SizedBox(width: 8),
                                _ReactionChip(
                                  icon: Icons.thumb_down_outlined,
                                  activeIcon: Icons.thumb_down,
                                  label: '$dislikeCount',
                                  active: myReaction == 'dislike',
                                  color: AppColors.errorNeon,
                                  onTap: () => _react(item, 'dislike'),
                                ),
                                const SizedBox(width: 8),
                                _ReactionChip(
                                  icon: Icons.chat_bubble_outline_rounded,
                                  activeIcon: Icons.chat_bubble_rounded,
                                  label: '$commentCount',
                                  active: false,
                                  color: AppColors.cyanNeon,
                                  onTap: () => _openComments(item),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: _composeStatus,
            backgroundColor: AppColors.purpleNeon,
            child: const Icon(Icons.edit_rounded),
          ),
        ),
      ],
    );
  }
}

class _ReactionChip extends StatelessWidget {
  const _ReactionChip({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? color.withValues(alpha: 0.15) : AppColors.bgTertiary,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(active ? activeIcon : icon, size: 18, color: active ? color : AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(color: active ? color : AppColors.textSecondary, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommentsSheet extends StatefulWidget {
  const _CommentsSheet({required this.statusId});

  final String statusId;

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final TextEditingController _text = TextEditingController();
  List<Map<String, dynamic>> _comments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final list = await api.listCommunityComments(widget.statusId);
      if (mounted) {
        setState(() {
          _comments = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _send() async {
    final t = _text.text.trim();
    if (t.isEmpty) return;
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final c = await api.addCommunityComment(widget.statusId, t);
      if (!mounted) return;
      setState(() {
        _comments.add(Map<String, dynamic>.from(c));
        _text.clear();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không gửi được: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.55,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Bình luận',
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.purpleNeon))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _comments.length,
                        itemBuilder: (_, i) {
                          final c = _comments[i];
                          final a = c['author'] as Map<String, dynamic>? ?? {};
                          final n = a['fullName']?.toString() ?? 'User';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  n,
                                  style: const TextStyle(
                                    color: AppColors.purpleNeon,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  c['content']?.toString() ?? '',
                                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _text,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Viết bình luận…',
                          hintStyle: const TextStyle(color: AppColors.textTertiary),
                          filled: true,
                          fillColor: AppColors.bgTertiary,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        minLines: 1,
                        maxLines: 3,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    IconButton(
                      onPressed: _send,
                      icon: const Icon(Icons.send_rounded, color: AppColors.purpleNeon),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserProfileSheet extends StatefulWidget {
  const _UserProfileSheet({
    required this.api,
    required this.userId,
    required this.myUserId,
  });

  final ApiService api;
  final String userId;
  final String? myUserId;

  @override
  State<_UserProfileSheet> createState() => _UserProfileSheetState();
}

class _UserProfileSheetState extends State<_UserProfileSheet> {
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _rel;
  bool _loading = true;
  String? _err;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      final p = await widget.api.getUserPublicProfile(widget.userId);
      final r = await widget.api.getFriendRelationship(widget.userId);
      if (mounted) {
        setState(() {
          _profile = p;
          _rel = r;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _err = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _sendRequest() async {
    try {
      await widget.api.sendFriendRequest(widget.userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã gửi lời mời kết bạn'), behavior: SnackBarBehavior.floating),
        );
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _accept() async {
    final fid = _rel?['friendshipId']?.toString();
    if (fid == null) return;
    try {
      await widget.api.acceptFriendRequest(fid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã chấp nhận'), behavior: SnackBarBehavior.floating),
        );
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator(color: AppColors.purpleNeon)),
      );
    }
    if (_err != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(_err!, style: const TextStyle(color: AppColors.textSecondary)),
      );
    }
    final name = _profile?['fullName']?.toString() ?? 'User';
    final level = _profile?['level'] ?? 1;
    final streak = _profile?['currentStreak'] ?? 0;
    final avatarUrl = ApiConfig.absoluteMediaUrl(_profile?['avatarUrl']?.toString());
    final status = _rel?['friendshipStatus']?.toString();
    final isSelf = status == 'self' || widget.myUserId == widget.userId;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.purpleNeon.withValues(alpha: 0.2),
            backgroundImage: avatarUrl.isNotEmpty ? CachedNetworkImageProvider(avatarUrl) : null,
            child: avatarUrl.isEmpty
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 28,
                      color: AppColors.purpleNeon,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            'Lv.$level • 🔥 $streak ngày',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),
          if (isSelf)
            const Text('Đây là bạn', style: TextStyle(color: AppColors.textTertiary))
          else if (status == 'blocked')
            const Text('Không thể tương tác', style: TextStyle(color: AppColors.errorNeon))
          else if (status == 'accepted')
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, color: AppColors.successNeon, size: 18),
                const SizedBox(width: 6),
                const Text('Đã là bạn bè', style: TextStyle(color: AppColors.successNeon)),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.push('/dm/chat/${widget.userId}', extra: {'peerName': name});
                  },
                  child: const Text('Nhắn tin'),
                ),
              ],
            )
          else if (status == 'pending' && _rel?['isRequester'] == true)
            const Text('Đã gửi lời mời', style: TextStyle(color: AppColors.textSecondary))
          else if (status == 'pending' && _rel?['isRequester'] == false)
            ElevatedButton(
              onPressed: _accept,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.successNeon),
              child: const Text('Chấp nhận kết bạn'),
            )
          else
            ElevatedButton(
              onPressed: _sendRequest,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.purpleNeon),
              child: const Text('Kết bạn'),
            ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}
