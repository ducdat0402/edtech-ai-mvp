import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/core/widgets/bottom_nav_bar.dart';
import 'package:edtech_mobile/core/widgets/empty_state.dart';
import 'package:edtech_mobile/theme/theme.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<dynamic> _friends = [];
  Map<String, dynamic>? _requests;
  List<dynamic> _suggestions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _loadDataForTab(_tabController.index);
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await _loadDataForTab(_tabController.index);
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDataForTab(int index) async {
    final api = Provider.of<ApiService>(context, listen: false);
    try {
      switch (index) {
        case 0:
          final friends = await api.getFriends();
          if (mounted) setState(() => _friends = friends);
          break;
        case 1:
          final requests = await api.getFriendRequests();
          if (mounted) setState(() => _requests = requests);
          break;
        case 2:
          final suggestions = await api.getFriendSuggestions();
          if (mounted) setState(() => _suggestions = suggestions);
          break;
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgSecondary,
        title: const Text('Ban be', style: TextStyle(color: AppColors.textPrimary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_rounded, color: AppColors.textPrimary),
            onPressed: () => context.push('/dm/conversations'),
          ),
          IconButton(
            icon: const Icon(Icons.search_rounded, color: AppColors.textPrimary),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.timeline_rounded, color: AppColors.textPrimary),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const _FriendActivityPage()),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.purpleNeon,
          labelColor: AppColors.purpleNeon,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            const Tab(text: 'Danh sach', icon: Icon(Icons.people_rounded, size: 20)),
            Tab(
              icon: const Icon(Icons.mail_rounded, size: 20),
              child: _buildRequestsTabLabel(),
            ),
            const Tab(text: 'Goi y', icon: Icon(Icons.person_add_rounded, size: 20)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.purpleNeon))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.errorNeon, size: 48),
                      const SizedBox(height: 16),
                      Text(_error!, style: const TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _loadData, child: const Text('Thu lai')),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildFriendsList(),
                    _buildRequestsTab(),
                    _buildSuggestionsTab(),
                  ],
                ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 3),
    );
  }

  Widget _buildRequestsTabLabel() {
    final receivedCount = (_requests?['received'] as List?)?.length ?? 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Loi moi'),
        if (receivedCount > 0) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.errorNeon,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$receivedCount',
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ],
    );
  }

  // ─── Friends List Tab ──────────────────────────────────────

  Widget _buildFriendsList() {
    if (_friends.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.people_outline_rounded,
        title: 'Chua co ban be',
        message: 'Tim kiem hoac xem goi y de ket ban!',
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadDataForTab(0),
      color: AppColors.purpleNeon,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _friends.length,
        itemBuilder: (context, index) {
          final friend = _friends[index];
          return _buildFriendCard(friend);
        },
      ),
    );
  }

  Widget _buildFriendCard(Map<String, dynamic> friend) {
    final level = friend['level'] ?? 1;
    final streak = friend['currentStreak'] ?? 0;
    final name = friend['fullName'] ?? friend['email'] ?? 'User';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderPrimary),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.purpleNeon.withOpacity(0.2),
          child: Text(
            (name as String).isNotEmpty ? name[0].toUpperCase() : '?',
            style: const TextStyle(color: AppColors.purpleNeon, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        subtitle: Row(
          children: [
            Icon(Icons.trending_up_rounded, size: 14, color: AppColors.getLevelColor(level)),
            const SizedBox(width: 4),
            Text('Lv.$level', style: TextStyle(color: AppColors.getLevelColor(level), fontSize: 12)),
            const SizedBox(width: 12),
            if (streak > 0) ...[
              const Text('🔥', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 2),
              Text('$streak ngay', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.cyanNeon),
              onPressed: () {
                final id = friend['id'] as String?;
                if (id != null) context.push('/dm/chat/$id', extra: {'peerName': name});
              },
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
              color: AppColors.bgTertiary,
              onSelected: (value) => _handleFriendAction(value, friend),
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'unfriend', child: Text('Huy ket ban', style: TextStyle(color: AppColors.errorNeon))),
                const PopupMenuItem(value: 'block', child: Text('Chan nguoi dung', style: TextStyle(color: AppColors.errorNeon))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleFriendAction(String action, Map<String, dynamic> friend) async {
    final api = Provider.of<ApiService>(context, listen: false);
    final friendshipId = friend['friendshipId'] as String?;
    final userId = friend['id'] as String?;
    if (friendshipId == null && userId == null) return;

    try {
      if (action == 'unfriend' && friendshipId != null) {
        await api.unfriend(friendshipId);
        _showSnack('Da huy ket ban');
      } else if (action == 'block' && userId != null) {
        await api.blockUser(userId);
        _showSnack('Da chan nguoi dung');
      }
      _loadDataForTab(0);
    } catch (e) {
      _showSnack('Loi: $e');
    }
  }

  // ─── Requests Tab ──────────────────────────────────────────

  Widget _buildRequestsTab() {
    final received = List<dynamic>.from(_requests?['received'] ?? []);
    final sent = List<dynamic>.from(_requests?['sent'] ?? []);

    if (received.isEmpty && sent.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.mail_outline_rounded,
        title: 'Khong co loi moi',
        message: 'Tim ban be moi hoac doi ai do gui loi moi cho ban!',
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadDataForTab(1),
      color: AppColors.purpleNeon,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (received.isNotEmpty) ...[
            _buildSectionHeader('Loi moi nhan duoc', Icons.call_received_rounded, received.length),
            const SizedBox(height: 8),
            ...received.map((r) => _buildReceivedRequestCard(r as Map<String, dynamic>)),
            const SizedBox(height: 20),
          ],
          if (sent.isNotEmpty) ...[
            _buildSectionHeader('Loi moi da gui', Icons.call_made_rounded, sent.length),
            const SizedBox(height: 8),
            ...sent.map((s) => _buildSentRequestCard(s as Map<String, dynamic>)),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, int count) {
    return Row(
      children: [
        Icon(icon, color: AppColors.purpleNeon, size: 18),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.purpleNeon.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('$count', style: const TextStyle(color: AppColors.purpleNeon, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildReceivedRequestCard(Map<String, dynamic> req) {
    final name = req['fullName'] ?? req['email'] ?? 'User';
    final level = req['level'] ?? 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.purpleNeon.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.cyanNeon.withOpacity(0.2),
              child: Text(
                (name as String).isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(color: AppColors.cyanNeon, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                  Text('Lv.$level', style: TextStyle(color: AppColors.getLevelColor(level), fontSize: 12)),
                ],
              ),
            ),
            _buildActionButton('Chap nhan', AppColors.successGlow, () => _acceptRequest(req['friendshipId'])),
            const SizedBox(width: 8),
            _buildActionButton('Tu choi', AppColors.errorGlow, () => _rejectRequest(req['friendshipId'])),
          ],
        ),
      ),
    );
  }

  Widget _buildSentRequestCard(Map<String, dynamic> req) {
    final name = req['fullName'] ?? req['email'] ?? 'User';
    final level = req['level'] ?? 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderPrimary),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.orangeNeon.withOpacity(0.2),
              child: Text(
                (name as String).isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(color: AppColors.orangeNeon, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                  Text('Lv.$level • Dang cho', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            _buildActionButton('Huy', AppColors.textTertiary, () => _cancelRequest(req['friendshipId'])),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Future<void> _acceptRequest(String? id) async {
    if (id == null) return;
    try {
      await Provider.of<ApiService>(context, listen: false).acceptFriendRequest(id);
      _showSnack('Da chap nhan loi moi!');
      _loadDataForTab(1);
      _loadDataForTab(0);
    } catch (e) {
      _showSnack('Loi: $e');
    }
  }

  Future<void> _rejectRequest(String? id) async {
    if (id == null) return;
    try {
      await Provider.of<ApiService>(context, listen: false).rejectFriendRequest(id);
      _showSnack('Da tu choi loi moi');
      _loadDataForTab(1);
    } catch (e) {
      _showSnack('Loi: $e');
    }
  }

  Future<void> _cancelRequest(String? id) async {
    if (id == null) return;
    try {
      await Provider.of<ApiService>(context, listen: false).cancelFriendRequest(id);
      _showSnack('Da huy loi moi');
      _loadDataForTab(1);
    } catch (e) {
      _showSnack('Loi: $e');
    }
  }

  // ─── Suggestions Tab ───────────────────────────────────────

  Widget _buildSuggestionsTab() {
    if (_suggestions.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.person_search_rounded,
        title: 'Khong co goi y',
        message: 'Hay hoc them de he thong goi y ban be phu hop!',
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadDataForTab(2),
      color: AppColors.purpleNeon,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          final s = _suggestions[index] as Map<String, dynamic>;
          return _buildSuggestionCard(s);
        },
      ),
    );
  }

  Widget _buildSuggestionCard(Map<String, dynamic> s) {
    final name = s['fullName'] ?? s['email'] ?? 'User';
    final level = s['level'] ?? 1;
    final mutual = s['mutualFriends'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderPrimary),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.pinkNeon.withOpacity(0.2),
              child: Text(
                (name as String).isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(color: AppColors.pinkNeon, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                  Row(
                    children: [
                      Text('Lv.$level', style: TextStyle(color: AppColors.getLevelColor(level), fontSize: 12)),
                      if (mutual > 0) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.people_rounded, size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 2),
                        Text('$mutual ban chung', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            _buildActionButton('Ket ban', AppColors.purpleNeon, () => _sendRequest(s['id'])),
          ],
        ),
      ),
    );
  }

  Future<void> _sendRequest(String? userId) async {
    if (userId == null) return;
    try {
      await Provider.of<ApiService>(context, listen: false).sendFriendRequest(userId);
      _showSnack('Da gui loi moi ket ban!');
      _loadDataForTab(2);
    } catch (e) {
      _showSnack('Loi: $e');
    }
  }

  // ─── Search ────────────────────────────────────────────────

  Future<void> _showSearchDialog() async {
    final searchController = TextEditingController();
    List<dynamic> results = [];
    Timer? debounce;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void doSearch() {
              final q = searchController.text.trim();
              if (q.length < 2) {
                setDialogState(() => results = []);
                return;
              }
              debounce?.cancel();
              debounce = Timer(const Duration(milliseconds: 400), () async {
                try {
                  final api = Provider.of<ApiService>(ctx, listen: false);
                  final r = await api.searchUsers(q);
                  setDialogState(() => results = r);
                } catch (_) {}
              });
            }

            return AlertDialog(
              backgroundColor: AppColors.bgSecondary,
              title: const Text('Tim kiem nguoi dung', style: TextStyle(color: AppColors.textPrimary)),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchController,
                      autofocus: true,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Nhap ten hoac email...',
                        hintStyle: const TextStyle(color: AppColors.textTertiary),
                        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.bgTertiary,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (_) => doSearch(),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 300,
                      child: results.isEmpty
                          ? Center(
                              child: Text(
                                searchController.text.length < 2
                                    ? 'Nhap it nhat 2 ky tu'
                                    : 'Khong tim thay',
                                style: const TextStyle(color: AppColors.textTertiary),
                              ),
                            )
                          : ListView.builder(
                              itemCount: results.length,
                              itemBuilder: (_, i) {
                                final u = results[i] as Map<String, dynamic>;
                                return _buildSearchResultTile(u, setDialogState, results);
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    debounce?.cancel();
                    Navigator.pop(ctx);
                  },
                  child: const Text('Dong', style: TextStyle(color: AppColors.textSecondary)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSearchResultTile(Map<String, dynamic> u, StateSetter setDialogState, List<dynamic> results) {
    final name = u['fullName'] ?? u['email'] ?? 'User';
    final level = u['level'] ?? 1;
    final status = u['friendshipStatus'];

    String actionLabel;
    Color actionColor;
    VoidCallback? onAction;

    if (status == 'accepted') {
      actionLabel = 'Ban be';
      actionColor = AppColors.successGlow;
      onAction = null;
    } else if (status == 'pending') {
      final isRequester = u['isRequester'] == true;
      actionLabel = isRequester ? 'Da gui' : 'Chap nhan';
      actionColor = isRequester ? AppColors.textTertiary : AppColors.successGlow;
      onAction = isRequester
          ? null
          : () async {
              try {
                await Provider.of<ApiService>(context, listen: false)
                    .acceptFriendRequest(u['friendshipId']);
                _showSnack('Da chap nhan!');
                final api = Provider.of<ApiService>(context, listen: false);
                final r = await api.searchUsers(u['fullName'] ?? '');
                setDialogState(() => results
                  ..clear()
                  ..addAll(r));
              } catch (e) {
                _showSnack('Loi: $e');
              }
            };
    } else {
      actionLabel = 'Ket ban';
      actionColor = AppColors.purpleNeon;
      onAction = () async {
        try {
          await Provider.of<ApiService>(context, listen: false).sendFriendRequest(u['id']);
          _showSnack('Da gui loi moi!');
          final api = Provider.of<ApiService>(context, listen: false);
          final r = await api.searchUsers(u['fullName'] ?? '');
          setDialogState(() => results
            ..clear()
            ..addAll(r));
        } catch (e) {
          _showSnack('Loi: $e');
        }
      };
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.bgTertiary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.cyanNeon.withOpacity(0.2),
          child: Text(
            (name as String).isNotEmpty ? name[0].toUpperCase() : '?',
            style: const TextStyle(color: AppColors.cyanNeon, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
        subtitle: Text('Lv.$level', style: TextStyle(color: AppColors.getLevelColor(level), fontSize: 12)),
        trailing: onAction != null
            ? _buildActionButton(actionLabel, actionColor, onAction)
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: actionColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(actionLabel, style: TextStyle(color: actionColor, fontSize: 11)),
              ),
      ),
    );
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.bgTertiary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Friend Activity Feed Page (separate page, accessed from AppBar)
// ═══════════════════════════════════════════════════════════════

class _FriendActivityPage extends StatefulWidget {
  const _FriendActivityPage();

  @override
  State<_FriendActivityPage> createState() => _FriendActivityPageState();
}

class _FriendActivityPageState extends State<_FriendActivityPage> {
  List<dynamic> _activities = [];
  bool _isLoading = true;
  int _page = 1;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final data = await api.getFriendActivities(page: _page);
      setState(() {
        _activities = data['activities'] ?? [];
        _total = data['total'] ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgSecondary,
        title: const Text('Hoat dong ban be', style: TextStyle(color: AppColors.textPrimary)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.purpleNeon))
          : _activities.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.timeline_rounded,
                  title: 'Chua co hoat dong',
                  message: 'Hoat dong cua ban be se xuat hien o day',
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.purpleNeon,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _activities.length + (_total > _activities.length ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _activities.length) {
                        return Center(
                          child: TextButton(
                            onPressed: () {
                              _page++;
                              _loadMore();
                            },
                            child: const Text('Xem them', style: TextStyle(color: AppColors.purpleNeon)),
                          ),
                        );
                      }
                      final a = _activities[index] as Map<String, dynamic>;
                      return _buildActivityCard(a);
                    },
                  ),
                ),
    );
  }

  Future<void> _loadMore() async {
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final data = await api.getFriendActivities(page: _page);
      setState(() {
        _activities.addAll(data['activities'] ?? []);
        _total = data['total'] ?? 0;
      });
    } catch (_) {}
  }

  Widget _buildActivityCard(Map<String, dynamic> a) {
    final user = a['user'] as Map<String, dynamic>? ?? {};
    final name = user['fullName'] ?? user['email'] ?? 'User';
    final type = a['type'] as String? ?? '';
    final meta = a['metadata'] as Map<String, dynamic>? ?? {};
    final createdAt = DateTime.tryParse(a['createdAt'] ?? '');

    final (icon, desc) = _activityDisplay(type, meta);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderPrimary),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.purpleNeon.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Text(icon, style: const TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(text: '$name ', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                      TextSpan(text: desc, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
                if (createdAt != null) ...[
                  const SizedBox(height: 4),
                  Text(_timeAgo(createdAt), style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  (String, String) _activityDisplay(String type, Map<String, dynamic> meta) {
    switch (type) {
      case 'lesson_completed':
        return ('📚', 'da hoan thanh bai hoc: ${meta['nodeName'] ?? ''}');
      case 'achievement_unlocked':
        return ('🏆', 'da mo khoa thanh tuu: ${meta['achievementName'] ?? ''}');
      case 'level_up':
        return ('⬆️', 'da len level ${meta['newLevel'] ?? ''}!');
      case 'streak_milestone':
        return ('🔥', 'dat chuoi ${meta['streak'] ?? ''} ngay hoc lien tiep!');
      case 'subject_completed':
        return ('🎓', 'da hoan thanh chu de: ${meta['topicName'] ?? ''}');
      case 'quiz_perfect':
        return ('💯', 'dat diem tuyet doi bai kiem tra!');
      default:
        return ('📌', 'co hoat dong moi');
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Vua xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phut truoc';
    if (diff.inHours < 24) return '${diff.inHours} gio truoc';
    return '${diff.inDays} ngay truoc';
  }
}
