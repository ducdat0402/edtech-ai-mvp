import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/theme/theme.dart';

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
  List<dynamic>? _filteredContentItems; // Content đã lọc theo difficulty và format
  bool _isLoading = true;
  String? _error;
  String? _subjectId; // Store subjectId for navigation
  String _selectedDifficulty = 'medium'; // Default difficulty
  String _selectedFormat = 'all'; // Default format: all, text, video, image
  bool _isPremiumLocked = false; // True if node requires premium

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

  /// Lọc content items theo format được chọn
  /// Note: Không filter theo difficulty nữa vì mức độ văn bản được chọn trong content viewer
  /// Note: Đã loại bỏ type 'example' - chỉ hiển thị concept, hidden_reward, boss_quiz
  List<dynamic> _filterContent(List<dynamic> items, String difficulty, String format) {
    // Lọc bỏ example - chỉ giữ concept, hidden_reward, boss_quiz
    var filtered = items.where((item) {
      final itemType = (item as Map<String, dynamic>)['type'] as String? ?? '';
      return itemType != 'example';
    }).toList();
    
    // Lọc theo format nếu không phải "all"
    if (format != 'all') {
      final byFormat = filtered.where((item) {
        final itemFormat = (item as Map<String, dynamic>)['format'] as String? ?? 'text';
        return itemFormat == format;
      }).toList();
      
      if (byFormat.isNotEmpty) {
        filtered = byFormat;
      } else {
        // Không có content ở format này, trả về empty để hiện placeholder
        return [];
      }
    }

    print('✅ Filtered ${filtered.length}/${items.length} items for format: $format (excluded examples)');
    return filtered;
  }

  /// Lọc content items theo độ khó được chọn (legacy - giữ cho tương thích)
  List<dynamic> _filterContentByDifficulty(List<dynamic> items, String difficulty) {
    return _filterContent(items, difficulty, _selectedFormat);
  }

  /// Thay đổi format và lọc lại content
  void _changeFormat(String format) {
    setState(() {
      _selectedFormat = format;
      if (_contentItems != null) {
        _filteredContentItems = _filterContent(_contentItems!, _selectedDifficulty, format);
      }
    });
  }

  /// Đếm số content items theo format
  Map<String, int> _countContentByFormat() {
    if (_contentItems == null) return {'all': 0, 'text': 0, 'video': 0, 'image': 0};
    
    int textCount = 0;
    int videoCount = 0;
    int imageCount = 0;
    
    for (final item in _contentItems!) {
      final format = (item as Map<String, dynamic>)['format'] as String? ?? 'text';
      switch (format) {
        case 'video':
          videoCount++;
          break;
        case 'image':
          imageCount++;
          break;
        default:
          textCount++;
      }
    }
    
    return {
      'all': _contentItems!.length,
      'text': textCount,
      'video': videoCount,
      'image': imageCount,
    };
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
      final errorStr = e.toString();
      // Check if this is a premium lock error
      if (errorStr.contains('requiresPremium') || errorStr.contains('Premium') || errorStr.contains('403')) {
        setState(() {
          _isPremiumLocked = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = errorStr;
          _isLoading = false;
        });
      }
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

  /// Build Premium Locked UI
  Widget _buildPremiumLockedUI() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Lock icon with gradient glow
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.coinGold.withOpacity(0.2),
                    AppColors.orangeNeon.withOpacity(0.1),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.coinGold.withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [AppColors.coinGold, AppColors.orangeNeon],
                ).createShader(bounds),
                child: const Icon(
                  Icons.lock_rounded,
                  size: 64,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Title
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [AppColors.coinGold, AppColors.orangeNeon],
              ).createShader(bounds),
              child: Text(
                'Nội dung Premium',
                style: AppTextStyles.h2.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            
            // Description
            Text(
              'Bài học này yêu cầu nâng cấp Premium để mở khóa.\nHãy nâng cấp để truy cập toàn bộ nội dung học tập!',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Features list
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderPrimary),
              ),
              child: Column(
                children: [
                  _buildFeatureRow(Icons.school, 'Truy cập tất cả bài học'),
                  const SizedBox(height: 12),
                  _buildFeatureRow(Icons.quiz, 'Không giới hạn quiz'),
                  const SizedBox(height: 12),
                  _buildFeatureRow(Icons.block, 'Không quảng cáo'),
                  const SizedBox(height: 12),
                  _buildFeatureRow(Icons.support_agent, 'Hỗ trợ ưu tiên'),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Upgrade button
            GamingButton(
              text: 'Nâng cấp Premium',
              onPressed: () {
                HapticFeedback.mediumImpact();
                context.push('/payment');
              },
              icon: Icons.workspace_premium,
            ),
            const SizedBox(height: 16),
            
            // Back button
            TextButton.icon(
              onPressed: _handleBack,
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Quay lại'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.successNeon.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppColors.successNeon),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: AppTextStyles.bodyMedium),
        ),
      ],
    );
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderPrimary),
            ),
            child: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 20),
          ),
          onPressed: _handleBack,
          tooltip: 'Quay lại',
        ),
        title: Text(
          _nodeData?['title'] ?? 'Node Detail',
          style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.purpleNeon))
          : _isPremiumLocked
              ? _buildPremiumLockedUI()
              : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.errorNeon.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.errorNeon),
                        ),
                        const SizedBox(height: 16),
                        Text('Error: $_error', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        GamingButton(text: 'Retry', onPressed: _loadData, icon: Icons.refresh_rounded),
                      ],
                    ),
                  ),
                )
              : _nodeData == null
                  ? Center(child: Text('No data available', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)))
                  : RefreshIndicator(
                      onRefresh: _refreshData,
                      color: AppColors.purpleNeon,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_progressData != null) _buildProgressHUD(),
                            const SizedBox(height: 24),
                            _buildNodeInfo(),
                            const SizedBox(height: 24),
                            _buildContentPath(),
                          ],
                        ),
                      ),
                    ),
    );
  }

  /// Widget chọn dạng bài học (text/video/image)
  Widget _buildFormatSelector() {
    final formatCounts = _countContentByFormat();
    
    return Card(
      color: _getFormatColor(_selectedFormat).withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _getFormatColor(_selectedFormat).withOpacity(0.3),
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
                  Icons.category,
                  color: _getFormatColor(_selectedFormat),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Dạng bài học',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getFormatColor(_selectedFormat),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getFormatLabel(_selectedFormat),
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
                _buildFormatChip('all', 'Tất cả', Icons.apps, Colors.grey.shade700, formatCounts['all'] ?? 0),
                const SizedBox(width: 6),
                _buildFormatChip('text', 'Văn bản', Icons.article, Colors.blue, formatCounts['text'] ?? 0),
                const SizedBox(width: 6),
                _buildFormatChip('video', 'Video', Icons.videocam, Colors.purple, formatCounts['video'] ?? 0),
                const SizedBox(width: 6),
                _buildFormatChip('image', 'Hình ảnh', Icons.image, Colors.teal, formatCounts['image'] ?? 0),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatChip(String format, String label, IconData icon, Color color, int count) {
    final isSelected = _selectedFormat == format;
    final hasContent = count > 0 || format == 'all';
    
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          _changeFormat(format);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color : (hasContent ? Colors.grey.shade100 : Colors.grey.shade50),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : (hasContent ? Colors.grey.shade300 : Colors.grey.shade200),
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
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    color: isSelected ? Colors.white : (hasContent ? Colors.grey.shade600 : Colors.grey.shade400),
                    size: 22,
                  ),
                  if (count > 0)
                    Positioned(
                      right: -8,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : color,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? color : Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : (hasContent ? Colors.grey.shade600 : Colors.grey.shade400),
                ),
              ),
              if (!hasContent && format != 'all')
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.add_circle_outline,
                    size: 12,
                    color: isSelected ? Colors.white70 : Colors.orange.shade400,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getFormatColor(String format) {
    switch (format) {
      case 'text':
        return Colors.blue;
      case 'video':
        return Colors.purple;
      case 'image':
        return Colors.teal;
      default:
        return Colors.grey.shade700;
    }
  }

  String _getFormatLabel(String format) {
    switch (format) {
      case 'text':
        return 'Văn bản';
      case 'video':
        return 'Video';
      case 'image':
        return 'Hình ảnh';
      default:
        return 'Tất cả';
    }
  }

  /// Tính tiến độ theo từng mức độ (difficulty)
  Map<String, Map<String, int>> _calculateProgressByDifficulty() {
    final result = {
      'easy': {'completed': 0, 'total': 0},
      'medium': {'completed': 0, 'total': 0},
      'hard': {'completed': 0, 'total': 0},
    };

    if (_contentItems == null) return result;

    // Lấy danh sách ID đã hoàn thành
    Set<String> completedIds = {};
    if (_progressData != null) {
      final progressData =
          _progressData!['progress'] as Map<String, dynamic>? ?? _progressData;
      final completedItems =
          progressData?['completedItems'] as Map<String, dynamic>? ?? {};
      
      // Collect all completed IDs from concepts, hiddenRewards (examples removed)
      for (final key in ['concepts', 'hiddenRewards']) {
        final items = completedItems[key] as List?;
        if (items != null) {
          completedIds.addAll(items.map((e) => e.toString()));
        }
      }
    }

    // Đếm theo difficulty (chỉ tính concept, không tính example, boss_quiz và hidden_reward)
    for (final item in _contentItems!) {
      final itemData = item as Map<String, dynamic>;
      final itemType = itemData['type'] as String? ?? '';
      final itemDifficulty = itemData['difficulty'] as String? ?? 'medium';
      final itemId = itemData['id'] as String? ?? '';

      // Chỉ tính concept vào tiến độ học (đã loại bỏ example)
      if (itemType == 'concept') {
        if (result.containsKey(itemDifficulty)) {
          result[itemDifficulty]!['total'] = result[itemDifficulty]!['total']! + 1;
          if (completedIds.contains(itemId)) {
            result[itemDifficulty]!['completed'] = result[itemDifficulty]!['completed']! + 1;
          }
        }
      }
    }

    return result;
  }

  /// Kiểm tra xem có ít nhất 1 mức độ đã hoàn thành 100% không
  bool _hasCompletedAnyDifficulty() {
    final progressByDiff = _calculateProgressByDifficulty();
    for (final diff in ['easy', 'medium', 'hard']) {
      final completed = progressByDiff[diff]!['completed']!;
      final total = progressByDiff[diff]!['total']!;
      if (total > 0 && completed >= total) {
        return true;
      }
    }
    return false;
  }

  /// Lấy tên mức độ đã hoàn thành (nếu có)
  String? _getCompletedDifficultyName() {
    final progressByDiff = _calculateProgressByDifficulty();
    for (final entry in [
      {'key': 'easy', 'name': 'Đơn giản'},
      {'key': 'medium', 'name': 'Chi tiết'},
      {'key': 'hard', 'name': 'Chuyên sâu'},
    ]) {
      final completed = progressByDiff[entry['key']]!['completed']!;
      final total = progressByDiff[entry['key']]!['total']!;
      if (total > 0 && completed >= total) {
        return entry['name'];
      }
    }
    return null;
  }

  Widget _buildProgressHUD() {
    final progressByDiff = _calculateProgressByDifficulty();
    
    final selectedProgress = progressByDiff[_selectedDifficulty]!;
    final completed = selectedProgress['completed']!;
    final total = selectedProgress['total']!;
    final percentage = total > 0 ? (completed / total * 100).round() : 0;
    final diffColor = _getDifficultyColor(_selectedDifficulty);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: diffColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: diffColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text('Tiến độ', style: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: diffColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getDifficultyLabel(_selectedDifficulty),
                      style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              Text(
                '$percentage%',
                style: AppTextStyles.numberMedium.copyWith(color: diffColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.bgTertiary,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              FractionallySizedBox(
                widthFactor: total > 0 ? (completed / total).clamp(0.0, 1.0) : 0,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: diffColor,
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: [BoxShadow(color: diffColor.withOpacity(0.5), blurRadius: 8)],
                  ),
                ),
              ),
            ],
          ),
          // Removed difficulty breakdown (Đơn giản/Chi tiết/Chuyên sâu) - user selects complexity in content viewer
        ],
      ),
    );
  }

  Widget _buildDifficultyProgress(String difficulty, String label, Color color, Map<String, int> progress) {
    final completed = progress['completed']!;
    final total = progress['total']!;
    final isCompleted = total > 0 && completed >= total;
    final isSelected = _selectedDifficulty == difficulty;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isCompleted ? color : (isSelected ? color : Colors.grey.shade300),
            width: isCompleted ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isCompleted)
                  Icon(Icons.check_circle, color: color, size: 14),
                if (isCompleted) const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isCompleted ? color : Colors.grey.shade700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$completed/$total',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isCompleted ? color : Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tính số lượng content theo mức độ được chọn (từ danh sách đã filter)
  Map<String, int> _getContentCountByDifficulty() {
    final result = {
      'concepts': 0,
      'examples': 0,
      'hiddenRewards': 0,
      'bossQuiz': 0,
    };

    // Sử dụng filtered content items (đã lọc theo difficulty)
    final itemsToCount = _filteredContentItems ?? _contentItems;
    if (itemsToCount == null) return result;

    for (final item in itemsToCount) {
      final itemData = item as Map<String, dynamic>;
      final itemType = itemData['type'] as String? ?? '';

      // Đếm theo type từ danh sách đã filter theo difficulty
      switch (itemType) {
        case 'concept':
          result['concepts'] = result['concepts']! + 1;
          break;
        case 'example':
          result['examples'] = result['examples']! + 1;
          break;
        case 'hidden_reward':
          result['hiddenRewards'] = result['hiddenRewards']! + 1;
          break;
        case 'boss_quiz':
          result['bossQuiz'] = result['bossQuiz']! + 1;
          break;
      }
    }

    return result;
  }

  Widget _buildNodeInfo() {
    final contentByDifficulty = _getContentCountByDifficulty();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _nodeData!['title'] ?? 'Node',
            style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
          ),
          if (_nodeData!['description'] != null) ...[
            const SizedBox(height: 12),
            Text(
              _nodeData!['description'] ?? '',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 16),
          // Info chips - only show concepts count (examples removed)
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: Icons.menu_book_rounded,
                label: 'Bài học',
                value: '${contentByDifficulty['concepts'] ?? 0}',
                color: _getDifficultyColor(_selectedDifficulty),
              ),
              _InfoChip(
                icon: Icons.star_rounded,
                label: 'Rewards',
                value: '${contentByDifficulty['hiddenRewards']}',
                color: AppColors.xpGold,
              ),
              _InfoChip(
                icon: Icons.quiz_rounded,
                label: 'Boss Quiz',
                value: '${contentByDifficulty['bossQuiz']}',
                color: AppColors.pinkNeon,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContentPath() {
    // Sử dụng filtered content nếu có, không thì dùng tất cả
    final contentToShow = _filteredContentItems ?? _contentItems;
    
    if (contentToShow == null || contentToShow.isEmpty) {
      // Nếu đang lọc theo format cụ thể và không có content
      if (_selectedFormat != 'all' && _contentItems != null && _contentItems!.isNotEmpty) {
        return _buildEmptyFormatState();
      }
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

  /// Hiển thị trạng thái trống khi không có content theo format đã chọn
  Widget _buildEmptyFormatState() {
    final formatColor = _getFormatColor(_selectedFormat);
    final formatLabel = _getFormatLabel(_selectedFormat);
    final formatIcon = _selectedFormat == 'video' ? Icons.videocam 
        : _selectedFormat == 'image' ? Icons.image : Icons.article;
    
    return Card(
      color: formatColor.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: formatColor.withOpacity(0.2), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon container
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: formatColor.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: formatColor.withOpacity(0.3), width: 3),
              ),
              child: Icon(
                formatIcon,
                size: 50,
                color: formatColor.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            
            // Title
            Text(
              'Chưa có nội dung $formatLabel',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: formatColor,
              ),
            ),
            const SizedBox(height: 12),
            
            // Description
            Text(
              'Bài học này chưa có nội dung dạng ${formatLabel.toLowerCase()}.\nBạn có thể đóng góp để giúp cộng đồng!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            
            // Rewards info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.emoji_events, color: Colors.amber.shade700, size: 24),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Phần thưởng đóng góp',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade800,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.star, size: 14, color: Colors.orange.shade600),
                          Text(' +50 XP  ', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                          Icon(Icons.monetization_on, size: 14, color: Colors.amber.shade600),
                          Text(' +30 Coin', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Contribute button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => _showContributeFormatDialog(),
                icon: Icon(_selectedFormat == 'video' ? Icons.upload : Icons.add_photo_alternate),
                label: Text(
                  'Đóng góp ${formatLabel}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: formatColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Switch format hint
            TextButton.icon(
              onPressed: () => _changeFormat('all'),
              icon: Icon(Icons.apps, size: 18, color: Colors.grey.shade600),
              label: Text(
                'Xem tất cả dạng bài học',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Dialog để đóng góp nội dung theo format
  void _showContributeFormatDialog() {
    final formatColor = _getFormatColor(_selectedFormat);
    final formatLabel = _getFormatLabel(_selectedFormat);
    final nodeTitle = _nodeData?['title'] ?? 'Bài học';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: formatColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          _selectedFormat == 'video' ? Icons.videocam : Icons.image,
                          color: formatColor,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Đóng góp $formatLabel',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              nodeTitle,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Instructions
                  const Text(
                    'Hướng dẫn đóng góp',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildContributionGuideItem(
                    Icons.info_outline,
                    'Nội dung liên quan đến "$nodeTitle"',
                    Colors.blue,
                  ),
                  _buildContributionGuideItem(
                    Icons.check_circle_outline,
                    _selectedFormat == 'video' 
                        ? 'Video rõ ràng, chất lượng tốt (720p trở lên)'
                        : 'Hình ảnh rõ nét, có chú thích',
                    Colors.green,
                  ),
                  _buildContributionGuideItem(
                    Icons.translate,
                    'Ưu tiên nội dung tiếng Việt',
                    Colors.orange,
                  ),
                  _buildContributionGuideItem(
                    Icons.timer,
                    _selectedFormat == 'video'
                        ? 'Độ dài: 2-10 phút'
                        : 'Kích thước: tối đa 10MB',
                    Colors.purple,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Rewards
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.amber.shade100, Colors.orange.shade100],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.emoji_events, color: Colors.amber, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Phần thưởng khi được duyệt',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.star, color: Colors.orange.shade600, size: 16),
                                  const Text(' +50 XP  '),
                                  Icon(Icons.monetization_on, color: Colors.amber.shade600, size: 16),
                                  const Text(' +30 Coin'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Upload button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _navigateToContribute();
                      },
                      icon: Icon(_selectedFormat == 'video' ? Icons.upload : Icons.add_photo_alternate),
                      label: Text(
                        _selectedFormat == 'video' ? 'Tải lên Video' : 'Tải lên Hình ảnh',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: formatColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildContributionGuideItem(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Navigate đến màn hình upload contribution
  void _navigateToContribute() {
    // Tạo placeholder content ID dựa trên node và format
    final nodeId = widget.nodeId;
    final format = _selectedFormat;
    final nodeTitle = _nodeData?['title'] ?? 'Bài học';
    
    context.push(
      '/contribute/new-$nodeId-$format?format=$format',
      extra: {
        'title': '${format == 'video' ? '🎬' : '🖼️'} $nodeTitle',
        'nodeId': nodeId,
        'isNewContribution': true,
        'contributionGuide': {
          'suggestedContent': 'Tạo ${format == 'video' ? 'video' : 'hình ảnh'} giải thích về "$nodeTitle"',
          'requirements': [
            format == 'video' ? 'Video rõ ràng, chất lượng 720p trở lên' : 'Hình ảnh rõ nét',
            'Nội dung liên quan đến bài học',
            'Ưu tiên tiếng Việt',
            format == 'video' ? 'Độ dài 2-10 phút' : 'Kích thước tối đa 10MB',
          ],
          'difficulty': _selectedDifficulty,
          'estimatedTime': format == 'video' ? '30-60 phút' : '15-30 phút',
        },
      },
    ).then((result) {
      if (result == true) {
        _refreshData();
      }
    });
  }

  Widget _buildPathContentItem(Map<String, dynamic> item, int stepNumber,
      bool isCompleted, String itemType, bool isUnlocked) {
    final title = item['title'] as String? ?? 'Content';
    final color = _getItemTypeColor(itemType);
    final icon = _getItemTypeIcon(itemType);

    final canAccess = isCompleted || isUnlocked;

    return GestureDetector(
      onTap: canAccess
          ? () {
              HapticFeedback.lightImpact();
              _onContentItemTap(item);
            }
          : () {
              HapticFeedback.lightImpact();
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
    final format = item['format'] as String? ?? 'text';
    final status = item['status'] as String? ?? 'published';
    final isPlaceholder = status == 'placeholder';
    final isAwaitingReview = status == 'awaiting_review';
    
    // Placeholder uses different color scheme
    final color = isPlaceholder 
        ? (format == 'video' ? Colors.purple : Colors.teal)
        : _getItemTypeColor(itemType);
    final icon = isPlaceholder
        ? (format == 'video' ? Icons.videocam : Icons.image)
        : _getItemTypeIcon(itemType);
    // Removed typeLabel - not showing type badge anymore

    final canAccess = isCompleted || isUnlocked || isPlaceholder;

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
              // Status badge for content item
              if (isPlaceholder) ...[
                Icon(Icons.volunteer_activism, color: Colors.orange.shade600, size: 14),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Cần đóng góp',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ] else if (isAwaitingReview) ...[
                Icon(Icons.hourglass_empty, color: Colors.blue.shade600, size: 14),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Đang chờ duyệt',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ] else if (isCompleted) ...[
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
                Icon(Icons.lock, color: Colors.grey.shade600, size: 14),
                const SizedBox(width: 4),
                Text(
                  'Chưa mở khóa',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ] else ...[
                // Unlocked but not completed - show ready status
                Icon(Icons.play_circle_outline, color: color, size: 14),
                const SizedBox(width: 4),
                Text(
                  'Sẵn sàng học',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
          trailing: isPlaceholder
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Đóng góp',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : isAwaitingReview
                  ? Icon(Icons.hourglass_empty, color: Colors.blue.shade400, size: 24)
                  : isCompleted
                      ? Icon(Icons.check_circle, color: Colors.green.shade600, size: 28)
                      : isUnlocked
                          ? Icon(Icons.arrow_forward_ios, size: 16, color: color)
                          : Icon(Icons.lock, color: Colors.grey.shade400, size: 20),
          onTap: canAccess
              ? () {
                  if (isPlaceholder) {
                    _showContributionDialog(item);
                  } else {
                    _onContentItemTap(item);
                  }
                }
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

  /// Hiển thị dialog cho việc đóng góp nội dung (video/image)
  void _showContributionDialog(Map<String, dynamic> item) {
    final title = item['title'] as String? ?? 'Nội dung';
    final content = item['content'] as String? ?? '';
    final format = item['format'] as String? ?? 'text';
    final contributionGuide = item['contributionGuide'] as Map<String, dynamic>?;
    final rewards = item['rewards'] as Map<String, dynamic>?;
    final itemId = item['id'] as String?;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: format == 'video'
                              ? Colors.purple.shade100
                              : Colors.teal.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          format == 'video' ? Icons.videocam : Icons.image,
                          color: format == 'video' ? Colors.purple : Colors.teal,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title.replaceAll(RegExp(r'^(🎬|🖼️)\s*'), ''),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                format == 'video' ? 'Video cần đóng góp' : 'Hình ảnh cần đóng góp',
                                style: TextStyle(
                                  color: Colors.orange.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Rewards
                  if (rewards != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.amber.shade100, Colors.orange.shade100],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.emoji_events, color: Colors.amber, size: 32),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Phần thưởng khi được duyệt',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (rewards['xp'] != null) ...[
                                      Icon(Icons.star, color: Colors.orange.shade600, size: 16),
                                      const SizedBox(width: 4),
                                      Text('+${rewards['xp']} XP'),
                                      const SizedBox(width: 12),
                                    ],
                                    if (rewards['coin'] != null) ...[
                                      Icon(Icons.monetization_on, color: Colors.amber.shade600, size: 16),
                                      const SizedBox(width: 4),
                                      Text('+${rewards['coin']} Coin'),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Description
                  const Text(
                    'Mô tả nội dung cần tạo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      contributionGuide?['suggestedContent'] as String? ?? content,
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Requirements
                  if (contributionGuide?['requirements'] != null) ...[
                    const Text(
                      'Yêu cầu kỹ thuật',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Xử lý an toàn: requirements có thể là List hoặc String
                    ...(() {
                      final raw = contributionGuide!['requirements'];
                      final reqs = raw is List 
                          ? raw 
                          : raw is String 
                              ? [raw] 
                              : <dynamic>[];
                      return reqs.map((req) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
                              const SizedBox(width: 8),
                              Expanded(child: Text(req.toString())),
                            ],
                          ),
                        );
                      });
                    })(),
                    const SizedBox(height: 24),
                  ],

                  // Difficulty & Time
                  if (contributionGuide != null) ...[
                    Row(
                      children: [
                        if (contributionGuide['difficulty'] != null) ...[
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.signal_cellular_alt, color: Colors.blue.shade600),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Độ khó',
                                        style: TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                      Text(
                                        _getDifficultyText(contributionGuide['difficulty'] as String),
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (contributionGuide['estimatedTime'] != null)
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.schedule, color: Colors.green.shade600),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Thời gian',
                                        style: TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                      Text(
                                        contributionGuide['estimatedTime'] as String,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Action button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _navigateToUpload(
                          itemId, 
                          format, 
                          title: title,
                          contributionGuide: contributionGuide,
                        );
                      },
                      icon: Icon(format == 'video' ? Icons.upload : Icons.add_photo_alternate),
                      label: Text(
                        format == 'video' ? 'Tải lên Video' : 'Tải lên Hình ảnh',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: format == 'video' ? Colors.purple : Colors.teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // History & Version buttons
                  if (itemId != null) ...[
                    Row(
                      children: [
                        // View edit history
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _showEditHistory(itemId);
                            },
                            icon: Icon(Icons.history, size: 18, color: Colors.grey.shade700),
                            label: Text(
                              'Lịch sử',
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // View versions
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _showVersions(itemId);
                            },
                            icon: Icon(Icons.folder_copy, size: 18, color: Colors.grey.shade700),
                            label: Text(
                              'Phiên bản',
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getDifficultyText(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return 'Dễ';
      case 'medium':
        return 'Trung bình';
      case 'hard':
        return 'Khó';
      default:
        return difficulty;
    }
  }

  void _navigateToUpload(String? itemId, String format, {String? title, Map<String, dynamic>? contributionGuide}) {
    if (itemId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy ID nội dung'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    context.push(
      '/contribute/$itemId?format=$format',
      extra: {
        'title': title,
        'contributionGuide': contributionGuide,
      },
    ).then((result) {
      // Refresh data if contribution was successful
      if (result == true) {
        _refreshData();
      }
    });
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

  /// Hiển thị lịch sử đóng góp của content item
  void _showEditHistory(String contentItemId) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final apiService = context.read<ApiService>();
      final history = await apiService.getHistoryForContent(contentItemId);

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.history, color: Colors.blue.shade700, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Lịch sử đóng góp',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),

                    // History list
                    if (history.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(Icons.history_toggle_off, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                'Chưa có lịch sử đóng góp',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...history.map((entry) => _buildHistoryItem(entry as Map<String, dynamic>)),
                  ],
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải lịch sử: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildHistoryItem(Map<String, dynamic> entry) {
    final action = entry['action'] as String? ?? 'unknown';
    final description = entry['description'] as String? ?? '';
    final createdAt = entry['createdAt'] as String?;
    
    // Parse date
    String formattedDate = '';
    if (createdAt != null) {
      try {
        final date = DateTime.parse(createdAt);
        formattedDate = '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      } catch (_) {
        formattedDate = createdAt;
      }
    }

    // Get action icon and color
    IconData actionIcon;
    Color actionColor;
    switch (action) {
      case 'submit':
        actionIcon = Icons.upload;
        actionColor = Colors.blue;
        break;
      case 'approve':
        actionIcon = Icons.check_circle;
        actionColor = Colors.green;
        break;
      case 'reject':
        actionIcon = Icons.cancel;
        actionColor = Colors.red;
        break;
      case 'remove':
        actionIcon = Icons.delete;
        actionColor = Colors.orange;
        break;
      default:
        actionIcon = Icons.info;
        actionColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: actionColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(actionIcon, color: actionColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedDate,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Hiển thị các phiên bản của content item
  void _showVersions(String contentItemId) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final apiService = context.read<ApiService>();
      final versions = await apiService.getVersionsForContent(contentItemId);

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.folder_copy, color: Colors.purple.shade700, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Các phiên bản',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Versions list
                    if (versions.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(Icons.folder_off, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                'Chưa có phiên bản nào',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...versions.asMap().entries.map((entry) {
                        final index = entry.key;
                        final version = entry.value as Map<String, dynamic>;
                        final isLatest = index == 0;
                        return _buildVersionItem(version, isLatest, contentItemId);
                      }),
                  ],
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải phiên bản: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildVersionItem(Map<String, dynamic> version, bool isLatest, String contentItemId) {
    final versionId = version['id'] as String? ?? '';
    final description = version['description'] as String? ?? 'Phiên bản';
    final createdAt = version['createdAt'] as String?;
    final versionNumber = version['versionNumber'] as int? ?? 1;
    
    // Parse date
    String formattedDate = '';
    if (createdAt != null) {
      try {
        final date = DateTime.parse(createdAt);
        formattedDate = '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      } catch (_) {
        formattedDate = createdAt;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isLatest ? Colors.green.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLatest ? Colors.green.shade300 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isLatest ? Colors.green : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'v$versionNumber',
                style: TextStyle(
                  color: isLatest ? Colors.white : Colors.grey.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        description,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (isLatest)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Hiện tại',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  formattedDate,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // View comparison
                    TextButton.icon(
                      onPressed: () => _showVersionComparison(versionId, version),
                      icon: Icon(Icons.compare_arrows, size: 16, color: Colors.blue.shade600),
                      label: Text(
                        'So sánh',
                        style: TextStyle(color: Colors.blue.shade600, fontSize: 12),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                      ),
                    ),
                    // Revert (only for non-current versions)
                    if (!isLatest) ...[
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () => _revertToVersion(versionId, versionNumber),
                        icon: Icon(Icons.restore, size: 16, color: Colors.orange.shade600),
                        label: Text(
                          'Khôi phục',
                          style: TextStyle(color: Colors.orange.shade600, fontSize: 12),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Hiển thị so sánh phiên bản
  void _showVersionComparison(String versionId, Map<String, dynamic> version) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final apiService = context.read<ApiService>();
      // Get edit ID from version
      final editId = version['editId'] as String?;
      
      if (editId == null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy thông tin so sánh')),
        );
        return;
      }

      final comparison = await apiService.getEditComparison(editId);

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      // Show comparison dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.compare_arrows, color: Colors.blue.shade600),
              const SizedBox(width: 8),
              const Text('So sánh phiên bản'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Original
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.remove_circle, color: Colors.red.shade600, size: 16),
                          const SizedBox(width: 4),
                          const Text('Trước', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        comparison['original']?['title']?.toString() ?? 'N/A',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Proposed
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.add_circle, color: Colors.green.shade600, size: 16),
                          const SizedBox(width: 4),
                          const Text('Sau', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        comparison['proposed']?['title']?.toString() ?? 'N/A',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Khôi phục về phiên bản trước
  void _revertToVersion(String versionId, int versionNumber) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Khôi phục phiên bản?'),
        content: Text('Bạn có chắc muốn khôi phục về phiên bản v$versionNumber?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Khôi phục', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final apiService = context.read<ApiService>();
      await apiService.revertToVersion(versionId);

      if (!mounted) return;
      Navigator.pop(context); // Close loading
      Navigator.pop(context); // Close versions sheet

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã khôi phục về v$versionNumber'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh data
      _refreshData();
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
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
  final Color? color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? Colors.grey.shade700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color != null ? color!.withOpacity(0.1) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: color != null ? Border.all(color: color!.withOpacity(0.3)) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: chipColor),
          const SizedBox(width: 6),
          Text(
            '$value $label',
            style: TextStyle(
              fontSize: 12,
              color: chipColor,
              fontWeight: color != null ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
