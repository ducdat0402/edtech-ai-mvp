import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/core/widgets/bottom_nav_bar.dart';
import 'package:edtech_mobile/core/widgets/error_widget.dart';
import 'package:edtech_mobile/core/widgets/empty_state.dart';

class LeaderboardScreen extends StatefulWidget {
  final String? subjectId;

  const LeaderboardScreen({
    super.key,
    this.subjectId,
  });

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _globalData;
  Map<String, dynamic>? _weeklyData;
  Map<String, dynamic>? _subjectData;
  Map<String, dynamic>? _myRank;
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;
  int _currentPage = 1;
  final int _pageSize = 50;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.subjectId != null ? 3 : 2, vsync: this);
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
      final apiService = Provider.of<ApiService>(context, listen: false);
      
      // Load my rank
      try {
        final myRank = await apiService.getMyRank();
        setState(() {
          _myRank = myRank;
        });
      } catch (e) {
        // My rank might fail if not authenticated, ignore
      }

      // Load data for current tab
      await _loadDataForTab(_tabController.index);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDataForTab(int tabIndex) async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);

      switch (tabIndex) {
        case 0: // Global
          final globalData = await apiService.getGlobalLeaderboard(
            limit: _pageSize,
            page: _currentPage,
          );
          setState(() {
            _globalData = globalData;
          });
          break;
        case 1: // Weekly
          final weeklyData = await apiService.getWeeklyLeaderboard(
            limit: _pageSize,
            page: _currentPage,
          );
          setState(() {
            _weeklyData = weeklyData;
          });
          break;
        case 2: // Subject
          if (widget.subjectId != null) {
            final subjectData = await apiService.getSubjectLeaderboard(
              widget.subjectId!,
              limit: _pageSize,
              page: _currentPage,
            );
            setState(() {
              _subjectData = subjectData;
            });
          }
          break;
      }
    } catch (e) {
      // Handle error per tab
      setState(() {
        _error = e.toString();
      });
    }
  }

  String? _getCurrentUserId() {
    // TODO: Get current user ID from auth service
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bảng xếp hạng'),
        bottom: TabBar(
          controller: _tabController,
          tabs: widget.subjectId != null
              ? const [
                  Tab(text: 'Toàn cầu', icon: Icon(Icons.public)),
                  Tab(text: 'Tuần này', icon: Icon(Icons.calendar_view_week)),
                  Tab(text: 'Môn học', icon: Icon(Icons.book)),
                ]
              : const [
                  Tab(text: 'Toàn cầu', icon: Icon(Icons.public)),
                  Tab(text: 'Tuần này', icon: Icon(Icons.calendar_view_week)),
                ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? AppErrorWidget(
                  message: _error!,
                  onRetry: _loadData,
                )
              : Column(
                  children: [
                    // My Rank Card
                    if (_myRank != null) _buildMyRankCard(),
                    
                    // Leaderboard List
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildLeaderboardList(_globalData),
                          _buildLeaderboardList(_weeklyData),
                          if (widget.subjectId != null)
                            _buildLeaderboardList(_subjectData),
                        ],
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildMyRankCard() {
    final rank = _myRank?['rank'] as int?;
    final totalUsers = _myRank?['totalUsers'] as int?;
    final entry = _myRank?['entry'] as Map<String, dynamic>?;

    if (rank == null || entry == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.purple.shade400],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry['fullName'] ?? 'You',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hạng $rank / $totalUsers',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '${entry['totalXP'] ?? 0}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.local_fire_department, color: Colors.orange, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${entry['currentStreak'] ?? 0}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardList(Map<String, dynamic>? data) {
    if (data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final entries = data['entries'] as List<dynamic>? ?? [];
    final currentUserId = _getCurrentUserId();

    if (entries.isEmpty) {
      return const EmptyLeaderboardWidget();
    }

    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index] as Map<String, dynamic>;
        final rank = entry['rank'] as int? ?? index + 1;
        final isCurrentUser = entry['userId'] == currentUserId;

        return _LeaderboardEntryCard(
          rank: rank,
          entry: entry,
          isCurrentUser: isCurrentUser,
        );
      },
    );
  }
}

class _LeaderboardEntryCard extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> entry;
  final bool isCurrentUser;

  const _LeaderboardEntryCard({
    required this.rank,
    required this.entry,
    required this.isCurrentUser,
  });

  Color _getRankColor(int rank) {
    if (rank == 1) return Colors.amber;
    if (rank == 2) return Colors.grey.shade400;
    if (rank == 3) return Colors.brown.shade400;
    return Colors.blue;
  }

  IconData _getRankIcon(int rank) {
    if (rank == 1) return Icons.emoji_events;
    if (rank == 2) return Icons.military_tech;
    if (rank == 3) return Icons.workspace_premium;
    return Icons.person;
  }

  @override
  Widget build(BuildContext context) {
    final rankColor = _getRankColor(rank);
    final rankIcon = _getRankIcon(rank);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isCurrentUser ? rankColor.withOpacity(0.1) : null,
        border: isCurrentUser
            ? Border.all(color: rankColor, width: 2)
            : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: rank <= 3 ? rankColor.withOpacity(0.2) : Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: rank <= 3
                ? Icon(rankIcon, color: rankColor, size: 24)
                : Text(
                    '#$rank',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: rankColor,
                    ),
                  ),
          ),
        ),
        title: Text(
          entry['fullName'] ?? 'Anonymous',
          style: TextStyle(
            fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Row(
          children: [
            if (entry['currentStreak'] != null && entry['currentStreak'] > 0) ...[
              Icon(Icons.local_fire_department, size: 14, color: Colors.orange),
              const SizedBox(width: 4),
              Text('${entry['currentStreak']}'),
              const SizedBox(width: 12),
            ],
            if (entry['coins'] != null) ...[
              Icon(Icons.monetization_on, size: 14, color: Colors.amber),
              const SizedBox(width: 4),
              Text('${entry['coins']}'),
            ],
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                Text(
                  '${entry['totalXP'] ?? entry['lPoints'] ?? 0}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

