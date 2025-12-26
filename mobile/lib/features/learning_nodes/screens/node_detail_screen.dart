import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:edtech_mobile/core/services/api_service.dart';

class NodeDetailScreen extends StatefulWidget {
  final String nodeId;

  const NodeDetailScreen({
    super.key,
    required this.nodeId,
  });

  @override
  State<NodeDetailScreen> createState() => _NodeDetailScreenState();
}

class _NodeDetailScreenState extends State<NodeDetailScreen> {
  Map<String, dynamic>? _nodeData;
  Map<String, dynamic>? _progressData;
  List<dynamic>? _contentItems;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      
      // Load node detail, progress, and content items in parallel
      final results = await Future.wait([
        apiService.getNodeDetail(widget.nodeId),
        apiService.getNodeProgress(widget.nodeId),
        apiService.getContentByNode(widget.nodeId),
      ]);

      setState(() {
        _nodeData = results[0] as Map<String, dynamic>;
        _progressData = results[1] as Map<String, dynamic>;
        _contentItems = results[2] as List<dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onContentItemTap(Map<String, dynamic> item) {
    final itemType = item['type'] as String;
    final itemId = item['id'] as String;

    // Navigate based on content type
    switch (itemType) {
      case 'concept':
      case 'example':
        // Navigate to lesson viewer
        context.go('/content/$itemId');
        break;
      case 'hidden_reward':
        // Show reward dialog or navigate
        _showRewardDialog(item);
        break;
      case 'boss_quiz':
        // Navigate to quiz screen
        context.go('/content/$itemId');
        break;
    }
  }

  void _showRewardDialog(Map<String, dynamic> item) {
    final rewards = item['rewards'] as Map<String, dynamic>?;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.star, color: Colors.amber),
            const SizedBox(width: 8),
            Text(item['title'] ?? 'Hidden Reward'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (rewards != null) ...[
              if (rewards['xp'] != null)
                Text('XP: +${rewards['xp']}'),
              if (rewards['coin'] != null)
                Text('Coins: +${rewards['coin']}'),
              if (rewards['shard'] != null)
                Text('Shard: ${rewards['shard']} x${rewards['shardAmount'] ?? 1}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_nodeData?['title'] ?? 'Node Detail'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _nodeData == null
                  ? const Center(child: Text('No data available'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Progress HUD
                          if (_progressData != null) _buildProgressHUD(),
                          const SizedBox(height: 24),

                          // Node Info
                          _buildNodeInfo(),
                          const SizedBox(height: 24),

                          // Content Items by Type
                          _buildContentSection('concept', 'Khái niệm', Icons.lightbulb, Colors.blue),
                          _buildContentSection('example', 'Ví dụ', Icons.code, Colors.green),
                          _buildContentSection('hidden_reward', 'Phần thưởng ẩn', Icons.star, Colors.amber),
                          _buildContentSection('boss_quiz', 'Boss Quiz', Icons.quiz, Colors.red),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildProgressHUD() {
    final progress = _progressData!;
    final completed = progress['completedItems'] as int? ?? 0;
    final total = progress['totalItems'] as int? ?? 0;
    final percentage = total > 0 ? (completed / total * 100).round() : 0;

    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tiến độ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$percentage%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: total > 0 ? completed / total : 0,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Text(
              '$completed / $total items completed',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNodeInfo() {
    final contentStructure = _nodeData!['contentStructure'] as Map<String, dynamic>? ?? {};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _nodeData!['title'] ?? 'Node',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_nodeData!['description'] != null) ...[
              const SizedBox(height: 12),
              Text(
                _nodeData!['description'] ?? '',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.lightbulb,
                  label: 'Khái niệm',
                  value: '${contentStructure['concepts'] ?? 0}',
                ),
                _InfoChip(
                  icon: Icons.code,
                  label: 'Ví dụ',
                  value: '${contentStructure['examples'] ?? 0}',
                ),
                _InfoChip(
                  icon: Icons.star,
                  label: 'Rewards',
                  value: '${contentStructure['hiddenRewards'] ?? 0}',
                ),
                _InfoChip(
                  icon: Icons.quiz,
                  label: 'Boss Quiz',
                  value: '${contentStructure['bossQuiz'] ?? 0}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentSection(String type, String title, IconData icon, Color color) {
    if (_contentItems == null) return const SizedBox.shrink();

    final items = _contentItems!.where((item) => item['type'] == type).toList();
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${items.length}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items.map((item) {
          final itemData = item as Map<String, dynamic>;
          final isCompleted = _progressData?['completedItemIds']?.contains(itemData['id']) ?? false;

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: isCompleted ? color.withOpacity(0.1) : null,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: color.withOpacity(0.2),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              title: Text(itemData['title'] ?? 'Content'),
              subtitle: Text(
                type == 'hidden_reward'
                    ? 'Tap để xem phần thưởng'
                    : 'Tap để học',
              ),
              trailing: isCompleted
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _onContentItemTap(itemData),
            ),
          );
        }).toList(),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade700),
          const SizedBox(width: 6),
          Text(
            '$value $label',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}


