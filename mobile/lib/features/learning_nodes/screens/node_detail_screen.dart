import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:edtech_mobile/core/services/api_service.dart';

class NodeDetailScreen extends StatefulWidget {
  final String nodeId;
  final String? difficulty; // Độ khó được chọn: easy, medium, hard

  const NodeDetailScreen({
    super.key,
    required this.nodeId,
    this.difficulty,
  });

  @override
  State<NodeDetailScreen> createState() => _NodeDetailScreenState();
}

class _NodeDetailScreenState extends State<NodeDetailScreen> {
  Map<String, dynamic>? _nodeData;
  Map<String, dynamic>? _progressData;
  List<dynamic>? _contentItems;
  List<dynamic>? _filteredContentItems; // Content đã lọc theo difficulty
  bool _isLoading = true;
  String? _error;
  String? _subjectId; // Store subjectId for navigation
  String _selectedDifficulty = 'medium'; // Default difficulty

  @override
  void initState() {
    super.initState();
    _selectedDifficulty = widget.difficulty ?? 'medium';
    _loadData();
  }

  // ✅ Refresh data when screen becomes visible again (e.g., returning from content viewer)
  Future<void> _refreshData() async {
    if (mounted) {
      await _loadData();
    }
  }

  /// Lọc content items theo độ khó được chọn
  /// - Nếu không có content ở độ khó được chọn, sẽ fallback về tất cả content
  List<dynamic> _filterContentByDifficulty(List<dynamic> items, String difficulty) {
    // Lọc items có difficulty trùng khớp
    final filtered = items.where((item) {
      final itemDifficulty = (item as Map<String, dynamic>)['difficulty'] as String? ?? 'medium';
      return itemDifficulty == difficulty;
    }).toList();

    // Nếu không có item nào ở độ khó này, trả về tất cả
    if (filtered.isEmpty) {
      print('⚠️ No content at difficulty "$difficulty", showing all content');
      return items;
    }

    print('✅ Filtered ${filtered.length}/${items.length} items for difficulty: $difficulty');
    return filtered;
  }

  /// Thay đổi độ khó và lọc lại content
  Future<void> _changeDifficulty(String difficulty) async {
    setState(() {
      _selectedDifficulty = difficulty;
      if (_contentItems != null) {
        _filteredContentItems = _filterContentByDifficulty(_contentItems!, difficulty);
      }
    });

    // Kiểm tra nếu không có content ở độ khó này
    if (_filteredContentItems != null && 
        _filteredContentItems!.length == _contentItems!.length &&
        _contentItems!.isNotEmpty) {
      // Content không thay đổi -> có thể chưa có content ở độ khó này
      final difficultyContent = _contentItems!.where((item) {
        final itemDiff = (item as Map<String, dynamic>)['difficulty'] as String?;
        return itemDiff == difficulty;
      }).toList();

      if (difficultyContent.isEmpty) {
        // Hiển thị dialog hỏi có muốn tạo content mới không
        _showGenerateContentDialog(difficulty);
      }
    }
  }

  /// Hiển thị dialog hỏi có muốn tạo content mới theo độ khó không
  void _showGenerateContentDialog(String difficulty) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lightbulb, color: _getDifficultyColor(difficulty)),
            const SizedBox(width: 8),
            const Expanded(child: Text('Chưa có nội dung')),
          ],
        ),
        content: Text(
          'Chưa có nội dung ở mức "${_getDifficultyLabel(difficulty)}". Bạn có muốn AI tạo nội dung mới phù hợp với mức độ này không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Để sau'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _generateContentForDifficulty(difficulty);
            },
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Tạo nội dung'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _getDifficultyColor(difficulty),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Gọi API tạo content mới theo độ khó
  Future<void> _generateContentForDifficulty(String difficulty) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(
              child: Text('Đang tạo nội dung ${_getDifficultyLabel(difficulty)}...'),
            ),
          ],
        ),
      ),
    );

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final result = await apiService.generateContentByDifficulty(
        widget.nodeId,
        difficulty,
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      final success = result['success'] as bool? ?? false;
      final message = result['message'] as String? ?? '';

      if (success) {
        // Reload data
        await _loadData();
        // Change to new difficulty
        setState(() {
          _selectedDifficulty = difficulty;
          if (_contentItems != null) {
            _filteredContentItems = _filterContentByDifficulty(_contentItems!, difficulty);
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message.isNotEmpty ? message : 'Không thể tạo nội dung'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Lấy tên hiển thị cho độ khó
  String _getDifficultyLabel(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return 'Đơn giản';
      case 'medium':
        return 'Chi tiết';
      case 'hard':
        return 'Chuyên sâu';
      default:
        return 'Chi tiết';
    }
  }

  /// Lấy màu cho độ khó
  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.blue;
      case 'hard':
        return Colors.orange;
      default:
        return Colors.blue;
    }
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

      final nodeData = results[0] as Map<String, dynamic>;

      final allContent = results[2] as List<dynamic>;
      
      setState(() {
        _nodeData = nodeData;
        _progressData = results[1] as Map<String, dynamic>;
        _contentItems = allContent;
        // Lọc content theo difficulty được chọn
        _filteredContentItems = _filterContentByDifficulty(allContent, _selectedDifficulty);
        _isLoading = false;
        // Extract subjectId from nodeData (could be subjectId or subject.id)
        _subjectId = nodeData['subjectId'] as String? ??
            (nodeData['subject'] as Map<String, dynamic>?)?['id'] as String?;
      });

      // ✅ Debug: Print progress data structure
      print('🔍 Progress Data Structure:');
      print('  - Full progressData: $_progressData');
      if (_progressData != null) {
        print(
            '  - Has "progress" key: ${_progressData!.containsKey("progress")}');
        print('  - Has "hud" key: ${_progressData!.containsKey("hud")}');
        if (_progressData!.containsKey('progress')) {
          final progress = _progressData!['progress'] as Map<String, dynamic>?;
          print('  - progress.completedItems: ${progress?['completedItems']}');
        }
        if (_progressData!.containsKey('hud')) {
          final hud = _progressData!['hud'] as Map<String, dynamic>?;
          print('  - hud.progressPercentage: ${hud?['progressPercentage']}');
          print('  - hud: $hud');
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onContentItemTap(Map<String, dynamic> item) async {
    final itemType = item['type'] as String;
    final itemId = item['id'] as String;

    // Navigate based on content type
    switch (itemType) {
      case 'concept':
      case 'example':
        // Navigate to lesson viewer and refresh when returning
        await context.push('/content/$itemId');
        // ✅ Refresh data when returning from content viewer
        _refreshData();
        break;
      case 'hidden_reward':
        // Show reward dialog or navigate
        _showRewardDialog(item);
        break;
      case 'boss_quiz':
        // Navigate to quiz screen and refresh when returning
        await context.push('/content/$itemId');
        // ✅ Refresh data when returning from content viewer
        _refreshData();
        break;
    }
  }

  void _showRewardDialog(Map<String, dynamic> item) async {
    final rewards = item['rewards'] as Map<String, dynamic>?;
    final itemId = item['id'] as String;
    final nodeId = _nodeData?['id'] as String?;
    final itemType = item['type'] as String? ?? 'hidden_reward';

    // Check if already completed
    final completedItemIds = <String>{};
    if (_progressData != null) {
      final progress = _progressData!['progress'] as Map<String, dynamic>?;
      if (progress != null) {
        final completedItems =
            progress['completedItems'] as Map<String, dynamic>? ?? {};
        completedItems.forEach((type, ids) {
          if (ids is List) {
            completedItemIds.addAll(ids.cast<String>());
          }
        });
      }
    }

    final isCompleted = completedItemIds.contains(itemId);

    if (isCompleted) {
      // Already completed - just show info
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              Text(item['title'] ?? 'Hidden Reward'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bạn đã nhận thưởng này rồi!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (rewards != null) ...[
                if (rewards['xp'] != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Text('XP: +${rewards['xp']}'),
                      ],
                    ),
                  ),
                if (rewards['coin'] != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.monetization_on,
                            color: Colors.amber, size: 20),
                        const SizedBox(width: 8),
                        Text('Coins: +${rewards['coin']}'),
                      ],
                    ),
                  ),
                if (rewards['shard'] != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.diamond, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Text(
                            'Shard: ${rewards['shard']} x${rewards['shardAmount'] ?? 1}'),
                      ],
                    ),
                  ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/dashboard');
                }
              },
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
      return;
    }

    // Not completed - show claim dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 32),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item['title'] ?? 'Phần thưởng ẩn',
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chúc mừng! Bạn đã tìm thấy phần thưởng ẩn! 🎉',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            if (rewards != null) ...[
              const Text(
                'Phần thưởng:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              if (rewards['xp'] != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.star,
                            color: Colors.orange, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'XP',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              '+${rewards['xp']}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              if (rewards['coin'] != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.monetization_on,
                            color: Colors.amber, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Coins',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              '+${rewards['coin']}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              if (rewards['shard'] != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.diamond,
                            color: Colors.blue, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Shard',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              '${rewards['shard']} x${rewards['shardAmount'] ?? 1}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ] else
              const Text('Không có phần thưởng'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/dashboard');
              }
            },
            child: const Text('Hủy'),
          ),
          ElevatedButton.icon(
            onPressed: nodeId != null
                ? () async {
                    try {
                      final apiService =
                          Provider.of<ApiService>(context, listen: false);

                      // Mark as complete
                      await apiService.completeContentItem(
                        nodeId: nodeId,
                        contentItemId: itemId,
                        itemType: itemType,
                      );

                      // Close dialog
                      if (context.mounted) {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/dashboard');
                        }

                        // Refresh data
                        await _refreshData();

                        // Show success message
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã nhận thưởng thành công! 🎉'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/dashboard');
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Lỗi: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                : null,
            icon: const Icon(Icons.check),
            label: const Text('Nhận thưởng'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _handleBack() {
    try {
      if (context.canPop()) {
        context.pop();
        return; // Exit after successful pop
      }
    } catch (e) {
      print('⚠️ Error popping: $e');
    }
    
    // If cannot pop or pop failed, navigate to skill tree or dashboard
    if (_subjectId != null) {
      context.go('/skill-tree?subjectId=$_subjectId');
    } else {
      context.go('/dashboard');
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _handleBack,
          tooltip: 'Quay lại',
        ),
        title: Text(_nodeData?['title'] ?? 'Node Detail'),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
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
                  : RefreshIndicator(
                      onRefresh: _refreshData,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Difficulty Selector
                            _buildDifficultySelector(),
                            const SizedBox(height: 16),
                            
                            // Progress HUD
                            if (_progressData != null) _buildProgressHUD(),
                            const SizedBox(height: 24),

                            // Node Info
                            _buildNodeInfo(),
                            const SizedBox(height: 24),

                            // Content Items Path
                            _buildContentPath(),
                          ],
                        ),
                      ),
                    ),
    );
  }

  /// Widget chọn độ khó
  Widget _buildDifficultySelector() {
    return Card(
      color: _getDifficultyColor(_selectedDifficulty).withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _getDifficultyColor(_selectedDifficulty).withOpacity(0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.tune,
                  color: _getDifficultyColor(_selectedDifficulty),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Mức độ học',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(_selectedDifficulty),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getDifficultyLabel(_selectedDifficulty),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildDifficultyChip('easy', 'Đơn giản', Icons.sentiment_satisfied, Colors.green),
                const SizedBox(width: 8),
                _buildDifficultyChip('medium', 'Chi tiết', Icons.auto_awesome, Colors.blue),
                const SizedBox(width: 8),
                _buildDifficultyChip('hard', 'Chuyên sâu', Icons.rocket_launch, Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyChip(String difficulty, String label, IconData icon, Color color) {
    final isSelected = _selectedDifficulty == difficulty;
    
    return Expanded(
      child: InkWell(
        onTap: () => _changeDifficulty(difficulty),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey.shade600,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressHUD() {
    final progress = _progressData!;

    // ✅ Backend returns structure: { progress: UserProgress, node: LearningNode, hud: {...} }
    // Debug: Print structure
    print('📊 Building Progress HUD');
    print('  - progress keys: ${progress.keys.toList()}');
    print('  - has hud: ${progress.containsKey('hud')}');
    print('  - has progress: ${progress.containsKey('progress')}');

    int completed = 0;
    int total = 0;
    double percentage = 0;

    // Try to get from hud first (backend returns this)
    if (progress.containsKey('hud') && progress['hud'] != null) {
      print('  ✅ Using hud data');
      final hud = progress['hud'] as Map<String, dynamic>;
      percentage = (hud['progressPercentage'] as num?)?.toDouble() ?? 0;

      // Calculate total and completed from hud
      final concepts = hud['concepts'] as Map<String, dynamic>? ?? {};
      final examples = hud['examples'] as Map<String, dynamic>? ?? {};
      final hiddenRewards = hud['hiddenRewards'] as Map<String, dynamic>? ?? {};
      final bossQuiz = hud['bossQuiz'] as Map<String, dynamic>? ?? {};

      completed = (concepts['completed'] as int? ?? 0) +
          (examples['completed'] as int? ?? 0) +
          (hiddenRewards['completed'] as int? ?? 0) +
          ((bossQuiz['completed'] as int? ?? 0) > 0 ? 1 : 0);

      total = (concepts['total'] as int? ?? 0) +
          (examples['total'] as int? ?? 0) +
          (hiddenRewards['total'] as int? ?? 0) +
          (bossQuiz['total'] as int? ?? 0);

      print('  - hud.progressPercentage: $percentage');
      print('  - hud.completed: $completed');
      print('  - hud.total: $total');
    } else if (progress.containsKey('progress') &&
        progress['progress'] != null) {
      // Fallback: calculate from progress.completedItems
      print('  ⚠️ Using progress.completedItems (fallback)');
      final progressData = progress['progress'] as Map<String, dynamic>;
      final completedItems =
          progressData['completedItems'] as Map<String, dynamic>? ?? {};

      print('  - completedItems: $completedItems');

      final concepts = (completedItems['concepts'] as List?)?.length ?? 0;
      final examples = (completedItems['examples'] as List?)?.length ?? 0;
      final hiddenRewards =
          (completedItems['hiddenRewards'] as List?)?.length ?? 0;
      final bossQuiz = (completedItems['bossQuiz'] as List?)?.length ?? 0;

      completed = concepts + examples + hiddenRewards + (bossQuiz > 0 ? 1 : 0);

      // Get total from node data
      final nodeData = _nodeData;
      if (nodeData != null) {
        final contentStructure =
            nodeData['contentStructure'] as Map<String, dynamic>? ?? {};
        total = (contentStructure['concepts'] as int? ?? 0) +
            (contentStructure['examples'] as int? ?? 0) +
            (contentStructure['hiddenRewards'] as int? ?? 0) +
            (contentStructure['bossQuiz'] as int? ?? 0);
      }

      percentage = total > 0 ? (completed / total * 100) : 0;
      print('  - calculated completed: $completed');
      print('  - calculated total: $total');
      print('  - calculated percentage: $percentage');
    } else {
      // Last resort: try to read directly from progress if it's the progress object itself
      print('  ⚠️ Trying direct progress reading');
      final completedItems =
          progress['completedItems'] as Map<String, dynamic>?;
      if (completedItems != null) {
        final concepts = (completedItems['concepts'] as List?)?.length ?? 0;
        final examples = (completedItems['examples'] as List?)?.length ?? 0;
        final hiddenRewards =
            (completedItems['hiddenRewards'] as List?)?.length ?? 0;
        final bossQuiz = (completedItems['bossQuiz'] as List?)?.length ?? 0;

        completed =
            concepts + examples + hiddenRewards + (bossQuiz > 0 ? 1 : 0);

        final nodeData = _nodeData;
        if (nodeData != null) {
          final contentStructure =
              nodeData['contentStructure'] as Map<String, dynamic>? ?? {};
          total = (contentStructure['concepts'] as int? ?? 0) +
              (contentStructure['examples'] as int? ?? 0) +
              (contentStructure['hiddenRewards'] as int? ?? 0) +
              (contentStructure['bossQuiz'] as int? ?? 0);
        }

        percentage = total > 0 ? (completed / total * 100) : 0;
        print('  - direct completed: $completed');
        print('  - direct total: $total');
        print('  - direct percentage: $percentage');
      }
    }

    final percentageInt = percentage.round();
    print('  📈 Final: $completed/$total = $percentageInt%');

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
                  '$percentageInt%',
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
              value: total > 0 ? (completed / total).clamp(0.0, 1.0) : 0,
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
    final contentStructure =
        _nodeData!['contentStructure'] as Map<String, dynamic>? ?? {};

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

  Widget _buildContentPath() {
    // Sử dụng filtered content nếu có, không thì dùng tất cả
    final contentToShow = _filteredContentItems ?? _contentItems;
    
    if (contentToShow == null || contentToShow.isEmpty) {
      return const SizedBox.shrink();
    }

    // ✅ Sort all content items by order
    final sortedItems = List<Map<String, dynamic>>.from(
        contentToShow.map((item) => Map<String, dynamic>.from(item as Map)));
    sortedItems.sort((a, b) {
      final orderA = a['order'] as int? ?? 0;
      final orderB = b['order'] as int? ?? 0;
      return orderA.compareTo(orderB);
    });

    // ✅ Get completed item IDs from progress
    final completedItemIds = <String>{};
    if (_progressData != null) {
      // Backend returns: { progress: UserProgress, node: LearningNode, hud: {...} }
      final progressData =
          _progressData!['progress'] as Map<String, dynamic>? ?? _progressData;
      final completedItems =
          progressData?['completedItems'] as Map<String, dynamic>? ?? {};

      // Extract all completed item IDs from all types
      completedItems.forEach((type, ids) {
        if (ids is List) {
          completedItemIds.addAll(ids.cast<String>());
        }
      });

      // Debug: print completed items
      print('✅ Completed items: $completedItemIds');
      print('✅ Total completed: ${completedItemIds.length}');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lộ trình học tập',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Hoàn thành các bài theo thứ tự để mở khóa bài tiếp theo',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 16),
        // ✅ Path visualization with landscape background
        Container(
          height: 140,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.lightBlue.shade50,
                Colors.green.shade50,
                Colors.green.shade100,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.shade200, width: 1),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Builder(
              builder: (context) {
                // ✅ Calculate proper width: nodeSize (70) + spacing (80) for each additional node
                final nodeSize = 70.0;
                final nodeSpacing = 80.0;
                final horizontalPadding = 16.0;
                final totalWidth = horizontalPadding +
                    nodeSize +
                    (sortedItems.length > 1
                        ? (sortedItems.length - 1) * (nodeSpacing + nodeSize)
                        : 0) +
                    horizontalPadding;

                return Container(
                  width: totalWidth,
                  padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding, vertical: 8),
                  child: Stack(
                    children: [
                      // ✅ Draw path behind nodes
                      CustomPaint(
                        size: Size(totalWidth, 140),
                        painter: ContentPathPainter(
                          items: sortedItems,
                          completedItemIds: completedItemIds,
                          nodeSize: nodeSize,
                          nodeSpacing: nodeSpacing,
                          horizontalPadding: horizontalPadding,
                        ),
                      ),
                      // ✅ Nodes on top
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: sortedItems.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          final itemId = item['id'] as String;
                          final isCompleted = completedItemIds.contains(itemId);
                          final itemType = item['type'] as String? ?? 'concept';

                          // Check unlock status
                          bool isUnlocked = true;
                          if (index > 0) {
                            for (int i = 0; i < index; i++) {
                              final prevItemId =
                                  sortedItems[i]['id'] as String?;
                              if (prevItemId != null &&
                                  !completedItemIds.contains(prevItemId)) {
                                isUnlocked = false;
                                break;
                              }
                            }
                          }

                          return Padding(
                            padding: EdgeInsets.only(
                              left: index > 0 ? nodeSpacing : 0,
                            ),
                            child: _buildPathContentItem(item, index + 1,
                                isCompleted, itemType, isUnlocked),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Content items list
        ...sortedItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final itemId = item['id'] as String;
          final isCompleted = completedItemIds.contains(itemId);
          final itemType = item['type'] as String? ?? 'concept';

          // Check unlock status
          bool isUnlocked = true;
          if (index > 0) {
            for (int i = 0; i < index; i++) {
              final prevItemId = sortedItems[i]['id'] as String?;
              if (prevItemId != null &&
                  !completedItemIds.contains(prevItemId)) {
                isUnlocked = false;
                break;
              }
            }
          }

          return _buildPathContentItemCard(
              item, index + 1, isCompleted, itemType, isUnlocked);
        }).toList(),
      ],
    );
  }

  Widget _buildPathContentItem(Map<String, dynamic> item, int stepNumber,
      bool isCompleted, String itemType, bool isUnlocked) {
    final title = item['title'] as String? ?? 'Content';
    final color = _getItemTypeColor(itemType);
    final icon = _getItemTypeIcon(itemType);

    final canAccess = isCompleted || isUnlocked;

    return GestureDetector(
      onTap: canAccess
          ? () => _onContentItemTap(item)
          : () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Hoàn thành các bài trước để mở khóa bài này!'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
      child: Opacity(
        opacity: canAccess ? 1.0 : 0.5, // Dim locked items
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            // ✅ Locked: grey background
            color: isCompleted
                ? null
                : (isUnlocked ? Colors.grey.shade200 : Colors.grey.shade300),
            // ✅ Completed: bright gradient with glow effect
            // ✅ Unlocked but not completed: lighter gradient
            gradient: isCompleted
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withOpacity(0.95), // Very bright
                      color.withOpacity(0.7),
                      color.withOpacity(0.85),
                    ],
                  )
                : isUnlocked
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color.withOpacity(0.6),
                          color.withOpacity(0.4),
                        ],
                      )
                    : null,
            border: Border.all(
              color: isCompleted
                  ? Colors.white
                  : isUnlocked
                      ? color.withOpacity(0.5)
                      : Colors.grey.shade400,
              width: isCompleted ? 3 : (isUnlocked ? 2.5 : 2),
            ),
            borderRadius: BorderRadius.circular(16),
            // ✅ Enhanced shadow for completed items to make them glow
            boxShadow: isCompleted
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.8),
                      blurRadius: 15,
                      spreadRadius: 4,
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.6),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 6,
                    ),
                  ]
                : isUnlocked
                    ? [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 6,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Step number badge
              Positioned(
                top: -6,
                right: -6,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? Colors.blue.shade600
                        : Colors.grey.shade400,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: isCompleted
                        ? [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.5),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '$stepNumber',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              // Icon with glow effect for completed items
              Container(
                padding:
                    isCompleted ? const EdgeInsets.all(4) : EdgeInsets.zero,
                decoration: isCompleted
                    ? BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.6),
                            blurRadius: 6,
                            spreadRadius: 2,
                          ),
                        ],
                      )
                    : null,
                child: Icon(
                  icon,
                  color: isCompleted
                      ? Colors.white
                      : isUnlocked
                          ? color
                          : Colors.grey.shade600,
                  size: isCompleted ? 28 : 24, // Larger icon for completed
                ),
              ),
              // Title
              Positioned(
                bottom: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: isCompleted
                      ? BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        )
                      : null,
                  child: Text(
                    title.length > 6 ? '${title.substring(0, 6)}...' : title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: isCompleted ? Colors.white : Colors.grey.shade600,
                      shadows: isCompleted
                          ? [
                              Shadow(
                                color: Colors.black.withOpacity(0.7),
                                blurRadius: 3,
                                offset: const Offset(1, 1),
                              ),
                            ]
                          : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              // ✅ Completed checkmark badge (sáng và nổi bật)
              if (isCompleted)
                Positioned(
                  bottom: -6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.green.shade600,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.8),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: Colors.white.withOpacity(0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              // ✅ Lock icon for locked items
              if (!isUnlocked && !isCompleted)
                Positioned(
                  bottom: -6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade700,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.lock,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPathContentItemCard(Map<String, dynamic> item, int stepNumber,
      bool isCompleted, String itemType, bool isUnlocked) {
    final title = item['title'] as String? ?? 'Content';
    final color = _getItemTypeColor(itemType);
    final icon = _getItemTypeIcon(itemType);
    final typeLabel = _getItemTypeLabel(itemType);

    final canAccess = isCompleted || isUnlocked;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      // ✅ Completed items have bright background and glow
      color: isCompleted
          ? color.withOpacity(0.15)
          : isUnlocked
              ? color.withOpacity(0.05)
              : Colors.grey.shade50,
      elevation: isCompleted ? 6 : (isUnlocked ? 2 : 1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCompleted
              ? color.withOpacity(0.5)
              : isUnlocked
                  ? color.withOpacity(0.3)
                  : Colors.grey.shade300,
          width: isCompleted ? 2 : 1,
        ),
      ),
      child: Opacity(
        opacity: canAccess ? 1.0 : 0.6,
        child: ListTile(
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              // ✅ Completed: bright gradient, Unlocked: lighter, Locked: grey
              color: isCompleted
                  ? null
                  : (isUnlocked
                      ? color.withOpacity(0.1)
                      : Colors.grey.shade200),
              gradient: isCompleted
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withOpacity(0.8),
                        color.withOpacity(0.6),
                      ],
                    )
                  : null,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCompleted
                    ? Colors.white
                    : isUnlocked
                        ? color.withOpacity(0.5)
                        : Colors.grey.shade300,
                width: isCompleted ? 2.5 : 2,
              ),
              boxShadow: isCompleted
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.6),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  icon,
                  color: isCompleted
                      ? Colors.white
                      : isUnlocked
                          ? color
                          : Colors.grey.shade600,
                  size: 24,
                ),
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? Colors.blue.shade600
                          : isUnlocked
                              ? Colors.blue.shade400
                              : Colors.grey.shade400,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 1.5,
                      ),
                      boxShadow: isCompleted
                          ? [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.5),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '$stepNumber',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
              color: isCompleted ? _getDarkerColor(color) : null,
            ),
          ),
          subtitle: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? color.withOpacity(0.3)
                      : color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  typeLabel,
                  style: TextStyle(
                    color: isCompleted ? _getDarkerColor(color) : color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isCompleted) ...[
                const SizedBox(width: 8),
                Icon(Icons.check_circle,
                    color: Colors.green.shade600, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Đã hoàn thành',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ] else if (!isUnlocked) ...[
                const SizedBox(width: 8),
                Icon(Icons.lock, color: Colors.grey.shade600, size: 14),
                const SizedBox(width: 4),
                Text(
                  'Chưa mở khóa',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
          trailing: isCompleted
              ? Icon(Icons.check_circle, color: Colors.green.shade600, size: 28)
              : isUnlocked
                  ? Icon(Icons.arrow_forward_ios, size: 16, color: color)
                  : Icon(Icons.lock, color: Colors.grey.shade400, size: 20),
          onTap: canAccess
              ? () => _onContentItemTap(item)
              : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Hoàn thành các bài trước để mở khóa bài này!'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
        ),
      ),
    );
  }

  Color _getItemTypeColor(String type) {
    switch (type) {
      case 'concept':
        return Colors.blue;
      case 'example':
        return Colors.green;
      case 'hidden_reward':
        return Colors.amber;
      case 'boss_quiz':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getItemTypeIcon(String type) {
    switch (type) {
      case 'concept':
        return Icons.lightbulb;
      case 'example':
        return Icons.code;
      case 'hidden_reward':
        return Icons.star;
      case 'boss_quiz':
        return Icons.quiz;
      default:
        return Icons.circle;
    }
  }

  String _getItemTypeLabel(String type) {
    switch (type) {
      case 'concept':
        return 'Khái niệm';
      case 'example':
        return 'Ví dụ';
      case 'hidden_reward':
        return 'Phần thưởng';
      case 'boss_quiz':
        return 'Boss Quiz';
      default:
        return 'Content';
    }
  }

  Color _getDarkerColor(Color color) {
    // Convert to darker shade
    return Color.fromRGBO(
      (color.red * 0.7).round().clamp(0, 255),
      (color.green * 0.7).round().clamp(0, 255),
      (color.blue * 0.7).round().clamp(0, 255),
      1.0,
    );
  }
}

/// Custom painter to draw path connecting content items
class ContentPathPainter extends CustomPainter {
  final List<Map<String, dynamic>> items;
  final Set<String> completedItemIds;
  final double nodeSize;
  final double nodeSpacing;
  final double horizontalPadding;

  ContentPathPainter({
    required this.items,
    required this.completedItemIds,
    required this.nodeSize,
    required this.nodeSpacing,
    required this.horizontalPadding,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (items.length < 2) return;

    final centerY = size.height / 2;

    // Draw path connecting all items
    final path = Path();
    final pathPaint = Paint()
      ..color = Colors.brown.shade300
      ..strokeWidth = 20
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Shadow paint for depth
    final shadowPaint = Paint()
      ..color = Colors.brown.shade600.withOpacity(0.3)
      ..strokeWidth = 22
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // ✅ Calculate positions for all nodes matching the Row layout
    final positions = <Offset>[];
    for (int i = 0; i < items.length; i++) {
      final x = horizontalPadding +
          (nodeSize / 2) +
          (i > 0 ? i * (nodeSpacing + nodeSize) : 0);
      positions.add(Offset(x, centerY));
    }

    // Draw path connecting nodes
    path.moveTo(positions[0].dx, positions[0].dy);
    for (int i = 1; i < positions.length; i++) {
      path.lineTo(positions[i].dx, positions[i].dy);
    }

    // Draw shadow first
    canvas.drawPath(path, shadowPaint);
    // Draw main path
    canvas.drawPath(path, pathPaint);

    // Draw path center line for detail
    final centerLinePaint = Paint()
      ..color = Colors.brown.shade100
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, centerLinePaint);

    // ✅ Draw completed path segments in brighter color (sáng lên khi hoàn thành)
    for (int i = 0; i < items.length - 1; i++) {
      final currentItemId = items[i]['id'] as String?;
      final nextItemId = items[i + 1]['id'] as String?;

      if (currentItemId != null && nextItemId != null) {
        final currentCompleted = completedItemIds.contains(currentItemId);
        final nextCompleted = completedItemIds.contains(nextItemId);

        if (currentCompleted && nextCompleted) {
          // ✅ Both items completed - draw bright glowing path segment
          final completedPath = Path();
          completedPath.moveTo(positions[i].dx, positions[i].dy);
          completedPath.lineTo(positions[i + 1].dx, positions[i + 1].dy);

          // Outer glow
          final glowPaint = Paint()
            ..color = Colors.green.shade300.withOpacity(0.4)
            ..strokeWidth = 24
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round;
          canvas.drawPath(completedPath, glowPaint);

          // Main bright path
          final completedPaint = Paint()
            ..color = Colors.green.shade500
            ..strokeWidth = 20
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round;
          canvas.drawPath(completedPath, completedPaint);

          // Inner highlight
          final highlightPaint = Paint()
            ..color = Colors.green.shade200
            ..strokeWidth = 4
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round;
          canvas.drawPath(completedPath, highlightPaint);
        } else if (currentCompleted) {
          // ✅ Current completed but next not - draw half bright path
          final halfPath = Path();
          halfPath.moveTo(positions[i].dx, positions[i].dy);
          final midX = (positions[i].dx + positions[i + 1].dx) / 2;
          final midY = (positions[i].dy + positions[i + 1].dy) / 2;
          halfPath.lineTo(midX, midY);

          final halfPaint = Paint()
            ..color = Colors.green.shade400
            ..strokeWidth = 18
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round;
          canvas.drawPath(halfPath, halfPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
