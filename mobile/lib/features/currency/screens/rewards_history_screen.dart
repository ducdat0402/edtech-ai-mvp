import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/core/widgets/error_widget.dart';
import 'package:edtech_mobile/core/widgets/empty_state.dart';

class RewardsHistoryScreen extends StatefulWidget {
  const RewardsHistoryScreen({super.key});

  @override
  State<RewardsHistoryScreen> createState() => _RewardsHistoryScreenState();
}

class _RewardsHistoryScreenState extends State<RewardsHistoryScreen> {
  List<dynamic> _transactions = [];
  bool _isLoading = true;
  String? _error;
  int _currentPage = 0;
  final int _pageSize = 20;
  bool _hasMore = true;
  String? _selectedSource;

  final Map<String, String> _sourceLabels = {
    'content_item': 'Bài học',
    'quest': 'Quest',
    'skill_node': 'Skill Tree',
    'daily_streak': 'Chuỗi ngày',
    'bonus': 'Bonus',
  };

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory({bool loadMore = false}) async {
    if (loadMore && !_hasMore) return;

    setState(() {
      if (!loadMore) {
        _isLoading = true;
        _error = null;
        _currentPage = 0;
        _transactions = [];
      }
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final data = await apiService.getRewardsHistory(
        limit: _pageSize,
        offset: loadMore ? _currentPage * _pageSize : 0,
        source: _selectedSource,
      );

      final newTransactions = data['transactions'] as List<dynamic>? ?? [];
      final total = data['total'] as int? ?? 0;

      setState(() {
        if (loadMore) {
          _transactions.addAll(newTransactions);
        } else {
          _transactions = newTransactions;
        }
        _currentPage++;
        _hasMore = _transactions.length < total;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onSourceFilterChanged(String? source) {
    setState(() {
      _selectedSource = source;
    });
    _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử phần thưởng'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: _onSourceFilterChanged,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('Tất cả'),
              ),
              ..._sourceLabels.entries.map(
                (entry) => PopupMenuItem(
                  value: entry.key,
                  child: Text(entry.value),
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadHistory(),
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: _isLoading && _transactions.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? AppErrorWidget(
                  message: _error!,
                  onRetry: () => _loadHistory(),
                )
              : _transactions.isEmpty
                  ? EmptyStateWidget(
                      title: 'Chưa có lịch sử',
                      icon: Icons.history,
                      message: 'Bạn chưa nhận được phần thưởng nào',
                    )
                  : RefreshIndicator(
                      onRefresh: () => _loadHistory(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _transactions.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _transactions.length) {
                            return _buildLoadMoreButton();
                          }
                          return _buildTransactionCard(_transactions[index]);
                        },
                      ),
                    ),
    );
  }

  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ElevatedButton(
          onPressed: _isLoading ? null : () => _loadHistory(loadMore: true),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Tải thêm'),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final source = transaction['source'] as String? ?? '';
    final sourceName = transaction['sourceName'] as String? ?? '';
    final xp = transaction['xp'] as int? ?? 0;
    final coins = transaction['coins'] as int? ?? 0;
    final shards = transaction['shards'] as Map<String, dynamic>? ?? {};
    final createdAt = transaction['createdAt'] as String?;

    final sourceLabel = _sourceLabels[source] ?? source;
    final hasRewards = xp > 0 || coins > 0 || shards.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sourceName.isNotEmpty ? sourceName : sourceLabel,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sourceLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (createdAt != null)
                  Text(
                    _formatDate(createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
              ],
            ),
            if (hasRewards) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  if (xp > 0)
                    _buildRewardChip(
                      icon: Icons.star,
                      label: '$xp XP',
                      color: Colors.amber,
                    ),
                  if (coins > 0)
                    _buildRewardChip(
                      icon: Icons.monetization_on,
                      label: '$coins Coins',
                      color: Colors.orange,
                    ),
                  ...shards.entries.map(
                    (entry) => _buildRewardChip(
                      icon: Icons.diamond,
                      label: '${entry.value} ${_formatShardName(entry.key)}',
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRewardChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          if (difference.inMinutes == 0) {
            return 'Vừa xong';
          }
          return '${difference.inMinutes} phút trước';
        }
        return '${difference.inHours} giờ trước';
      } else if (difference.inDays == 1) {
        return 'Hôm qua';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} ngày trước';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateString;
    }
  }

  String _formatShardName(String name) {
    return name
        .split('-')
        .map((word) => word.isEmpty
            ? ''
            : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}

