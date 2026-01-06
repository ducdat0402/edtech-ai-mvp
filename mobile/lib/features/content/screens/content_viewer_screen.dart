import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/core/config/api_config.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:edtech_mobile/features/content/widgets/web_video_player.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';

class ContentViewerScreen extends StatefulWidget {
  final String contentId;

  const ContentViewerScreen({
    super.key,
    required this.contentId,
  });

  @override
  State<ContentViewerScreen> createState() => _ContentViewerScreenState();
}

class _ContentViewerScreenState extends State<ContentViewerScreen> {
  Map<String, dynamic>? _contentData;
  Map<String, dynamic>? _nextContentItem;
  Map<String, dynamic>? _prevContentItem;
  bool _isLoading = true;
  String? _error;
  int? _selectedQuizAnswer;
  bool _showQuizResult = false;
  bool _isCompleting = false;
  bool _isCompleted = false;
  List<Map<String, dynamic>> _communityEdits = [];
  bool _isLoadingEdits = false;
  String? _userRole; // Store user role to check if admin

  @override
  void initState() {
    super.initState();
    _loadContent();
    _loadCommunityEdits();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final profile = await apiService.getUserProfile();
      setState(() {
        _userRole = profile['role'] as String?;
      });
    } catch (e) {
      // Ignore error, user might not be logged in
    }
  }

  @override
  void didUpdateWidget(ContentViewerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload content when contentId changes (e.g., when navigating with context.go())
    if (oldWidget.contentId != widget.contentId) {
      print(
          '🔄 Content ID changed from ${oldWidget.contentId} to ${widget.contentId}, reloading...');
      // Reset state before reloading
      setState(() {
        _isLoading = true;
        _error = null;
        _isCompleted = false;
        _isCompleting = false;
        _showQuizResult = false;
        _selectedQuizAnswer = null;
        _nextContentItem = null;
        _prevContentItem = null;
      });
      _loadContent();
    }
  }

  /// Helper function to convert relative path to full URL
  String _buildFullUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    // If already a full URL (starts with http:// or https://), return as is
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    // If it's a relative path (starts with /), prepend base URL
    // Extract base URL from ApiConfig (remove /api/v1)
    final baseUrl = ApiConfig.baseUrl.replaceAll('/api/v1', '');
    return '$baseUrl$url';
  }

  Future<void> _loadContent() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final data = await apiService.getContentDetail(widget.contentId);

      // Load all content items from the same node
      final nodeId = data['nodeId'] as String?;
      if (nodeId != null) {
        try {
          final allItems = await apiService.getContentByNode(nodeId);
          // Sort by order
          allItems.sort((a, b) =>
              (a['order'] as int? ?? 0).compareTo(b['order'] as int? ?? 0));

          final currentIndex =
              allItems.indexWhere((item) => item['id'] == widget.contentId);

          print('Loaded ${allItems.length} content items');
          print('Current content ID: ${widget.contentId}');
          print('Current index: $currentIndex');

          final nextItem =
              currentIndex >= 0 && currentIndex < allItems.length - 1
                  ? allItems[currentIndex + 1]
                  : null;
          final prevItem = currentIndex > 0 ? allItems[currentIndex - 1] : null;

          print('Next item: ${nextItem?['id']} - ${nextItem?['title']}');
          print('Prev item: ${prevItem?['id']} - ${prevItem?['title']}');

          setState(() {
            _contentData = data;
            _nextContentItem = nextItem;
            _prevContentItem = prevItem;
            _isLoading = false;
          });
        } catch (e) {
          // If can't load content items, just show current content
          setState(() {
            _contentData = data;
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _contentData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCommunityEdits() async {
    setState(() {
      _isLoadingEdits = true;
    });
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final edits = await apiService.getContentEdits(widget.contentId);
      setState(() {
        _communityEdits =
            edits.map((e) => Map<String, dynamic>.from(e)).toList();
        _isLoadingEdits = false;
      });
    } catch (e) {
      print('Error loading community edits: $e');
      setState(() {
        _isLoadingEdits = false;
      });
    }
  }

  Future<void> _markComplete({int? score}) async {
    if (_contentData == null || _isCompleting) return;

    setState(() {
      _isCompleting = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final nodeId = _contentData!['nodeId'] as String;
      final contentItemId = _contentData!['id'] as String;
      final itemType = _contentData!['type'] as String;

      await apiService.completeContentItem(
        nodeId: nodeId,
        contentItemId: contentItemId,
        itemType: itemType,
        score: score,
      );

      // Show success message and mark as completed
      if (mounted) {
        setState(() {
          _isCompleted = true;
        });

        // Reload content items to ensure navigation buttons are available
        await _loadContentItems();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã hoàn thành! 🎉'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCompleting = false;
        });
      }
    }
  }

  void _submitQuizAnswer() {
    if (_selectedQuizAnswer == null) return;

    final quizData = _contentData!['quizData'] as Map<String, dynamic>?;
    if (quizData == null) return;

    final correctAnswer = quizData['correctAnswer'] as int?;
    final isCorrect = _selectedQuizAnswer == correctAnswer;

    setState(() {
      _showQuizResult = true;
    });

    // Mark complete with score, then reload content items for navigation
    _markComplete(score: isCorrect ? 100 : 0).then((_) {
      // Reload content items after completion to ensure navigation buttons work
      _loadContentItems();
    });
  }

  Future<void> _loadContentItems() async {
    final nodeId = _contentData?['nodeId'] as String?;
    if (nodeId == null) return;

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final allItems = await apiService.getContentByNode(nodeId);
      // Sort by order
      allItems.sort((a, b) =>
          (a['order'] as int? ?? 0).compareTo(b['order'] as int? ?? 0));

      final currentIndex =
          allItems.indexWhere((item) => item['id'] == widget.contentId);

      print('Reloaded ${allItems.length} content items');
      print('Current content ID: ${widget.contentId}');
      print('Current index: $currentIndex');

      final nextItem = currentIndex >= 0 && currentIndex < allItems.length - 1
          ? allItems[currentIndex + 1]
          : null;
      final prevItem = currentIndex > 0 ? allItems[currentIndex - 1] : null;

      print('Next item: ${nextItem?['id']} - ${nextItem?['title']}');
      print('Prev item: ${prevItem?['id']} - ${prevItem?['title']}');

      if (mounted) {
        setState(() {
          _nextContentItem = nextItem;
          _prevContentItem = prevItem;
        });
      }
    } catch (e) {
      print('Error reloading content items: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_contentData?['title'] ?? 'Content'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Simply pop back to previous screen (maintains navigation stack)
            if (context.canPop()) {
              context.pop();
            } else {
              // Fallback: navigate to dashboard if can't pop
              context.go('/dashboard');
            }
          },
        ),
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
                        onPressed: _loadContent,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _contentData == null
                  ? const Center(child: Text('No data available'))
                  : _buildContent(),
    );
  }

  Widget _buildContent() {
    final type = _contentData!['type'] as String;

    switch (type) {
      case 'concept':
        return _buildConceptView();
      case 'example':
        return _buildExampleView();
      case 'boss_quiz':
        return _buildQuizView();
      case 'hidden_reward':
        return _buildRewardView();
      default:
        return _buildDefaultView();
    }
  }

  Widget _buildConceptView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _contentData!['title'] ?? 'Concept',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_contentData!['media']?['imageUrl'] != null)
            Image.network(
              _buildFullUrl(_contentData!['media']['imageUrl']),
              fit: BoxFit.cover,
            ),
          const SizedBox(height: 16),
          if (_contentData!['content'] != null)
            Text(
              _contentData!['content'],
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          const SizedBox(height: 24),
          _buildCommunityEditsSection(),
          const SizedBox(height: 24),
          _buildCompleteButton(),
        ],
      ),
    );
  }

  Widget _buildExampleView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _contentData!['title'] ?? 'Example',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_contentData!['content'] != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _contentData!['content'],
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'monospace',
                  color: Colors.white,
                  height: 1.5,
                ),
              ),
            ),
          const SizedBox(height: 16),
          if (_contentData!['media']?['imageUrl'] != null)
            Image.network(
              _buildFullUrl(_contentData!['media']['imageUrl']),
              fit: BoxFit.cover,
            ),
          const SizedBox(height: 24),
          _buildCommunityEditsSection(),
          const SizedBox(height: 24),
          _buildCompleteButton(),
        ],
      ),
    );
  }

  Widget _buildQuizView() {
    final quizData = _contentData!['quizData'] as Map<String, dynamic>?;
    if (quizData == null) {
      return const Center(child: Text('No quiz data available'));
    }

    final question = quizData['question'] as String? ?? '';
    final options = quizData['options'] as List<dynamic>? ?? [];
    final correctAnswer = quizData['correctAnswer'] as int?;
    final explanation = quizData['explanation'] as String?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _contentData!['title'] ?? 'Quiz',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            question,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          ...List.generate(options.length, (index) {
            final isSelected = _selectedQuizAnswer == index;
            final isCorrect = _showQuizResult && index == correctAnswer;
            final isWrong =
                _showQuizResult && isSelected && index != correctAnswer;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: _showQuizResult
                    ? null
                    : () {
                        setState(() {
                          _selectedQuizAnswer = index;
                        });
                      },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isCorrect
                        ? Colors.green.shade100
                        : isWrong
                            ? Colors.red.shade100
                            : isSelected
                                ? Colors.blue.shade100
                                : Colors.grey.shade100,
                    border: Border.all(
                      color: isCorrect
                          ? Colors.green
                          : isWrong
                              ? Colors.red
                              : isSelected
                                  ? Colors.blue
                                  : Colors.grey.shade300,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCorrect
                              ? Colors.green
                              : isWrong
                                  ? Colors.red
                                  : isSelected
                                      ? Colors.blue
                                      : Colors.transparent,
                          border: Border.all(
                            color: isCorrect
                                ? Colors.green
                                : isWrong
                                    ? Colors.red
                                    : isSelected
                                        ? Colors.blue
                                        : Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: isCorrect
                            ? const Icon(Icons.check,
                                size: 16, color: Colors.white)
                            : isWrong
                                ? const Icon(Icons.close,
                                    size: 16, color: Colors.white)
                                : isSelected
                                    ? const Icon(Icons.check,
                                        size: 16, color: Colors.white)
                                    : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          options[index].toString(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          if (_showQuizResult && explanation != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Giải thích:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(explanation),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (!_showQuizResult)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _selectedQuizAnswer != null ? _submitQuizAnswer : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Submit Answer'),
              ),
            ),
          if (_showQuizResult) ...[
            // Show navigation buttons after quiz is completed
            const SizedBox(height: 24),
            Row(
              children: [
                // Back button
                if (_prevContentItem != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        print('Quiz: Prev button pressed');
                        print('Quiz: _prevContentItem: $_prevContentItem');
                        if (_prevContentItem != null) {
                          final prevId = _prevContentItem!['id'] as String?;
                          print(
                              'Quiz: Navigating to previous content: $prevId');
                          if (prevId != null && prevId.isNotEmpty) {
                            // Use go() to replace current route instead of pushing new one
                            context.go('/content/$prevId');
                          } else {
                            print(
                                'Quiz: Error: prevContentItem id is null or empty');
                          }
                        } else {
                          print('Quiz: Error: _prevContentItem is null');
                        }
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Bài trước'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  )
                else
                  // Show info message if this is the first item
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.grey.shade600, size: 18),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Đây là bài đầu tiên',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_prevContentItem != null && _nextContentItem != null)
                  const SizedBox(width: 12),
                // Next button
                if (_nextContentItem != null)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        print('Quiz: Next button pressed');
                        print('Quiz: _nextContentItem: $_nextContentItem');
                        if (_nextContentItem != null) {
                          final nextId = _nextContentItem!['id'] as String?;
                          print('Quiz: Navigating to next content: $nextId');
                          if (nextId != null && nextId.isNotEmpty) {
                            // Use go() to replace current route instead of pushing new one
                            context.go('/content/$nextId');
                          } else {
                            print(
                                'Quiz: Error: nextContentItem id is null or empty');
                          }
                        } else {
                          print('Quiz: Error: _nextContentItem is null');
                        }
                      },
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Bài tiếp theo'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.blue,
                      ),
                    ),
                  )
                else
                  // Show info message if this is the last item
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.grey.shade600, size: 18),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Đây là bài cuối cùng',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Back to node button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  // Always navigate directly to node detail screen
                  final nodeId = _contentData?['nodeId'] as String?;
                  if (nodeId != null) {
                    context.go('/nodes/$nodeId');
                  } else {
                    // Fallback: try to pop or go to dashboard
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/dashboard');
                    }
                  }
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Quay lại Node'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRewardView() {
    final rewards = _contentData!['rewards'] as Map<String, dynamic>?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.star,
            size: 80,
            color: Colors.amber,
          ),
          const SizedBox(height: 24),
          Text(
            _contentData!['title'] ?? 'Hidden Reward',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          if (rewards != null) ...[
            if (rewards['xp'] != null)
              _RewardItem(
                icon: Icons.star,
                label: 'XP',
                value: '+${rewards['xp']}',
                color: Colors.amber,
              ),
            if (rewards['coin'] != null)
              _RewardItem(
                icon: Icons.monetization_on,
                label: 'Coins',
                value: '+${rewards['coin']}',
                color: Colors.orange,
              ),
            if (rewards['shard'] != null)
              _RewardItem(
                icon: Icons.diamond,
                label: 'Shard',
                value: '${rewards['shard']} x${rewards['shardAmount'] ?? 1}',
                color: Colors.purple,
              ),
          ],
          const SizedBox(height: 24),
          _buildCompleteButton(),
        ],
      ),
    );
  }

  Widget _buildDefaultView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _contentData!['title'] ?? 'Content',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_contentData!['content'] != null) Text(_contentData!['content']),
          const SizedBox(height: 24),
          _buildCompleteButton(),
        ],
      ),
    );
  }

  Widget _buildCommunityEditsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Đóng góp từ cộng đồng',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: () => _showAddEditDialog(),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Thêm'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoadingEdits)
          const Center(child: CircularProgressIndicator())
        else if (_communityEdits.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Chưa có đóng góp nào từ cộng đồng. Hãy là người đầu tiên!',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          ..._communityEdits.map((edit) => _buildEditCard(edit)),
      ],
    );
  }

  Widget _buildEditCard(Map<String, dynamic> edit) {
    final type = edit['type'] as String? ?? '';
    final media = edit['media'] as Map<String, dynamic>?;
    final description = edit['description'] as String?;
    final upvotes = edit['upvotes'] as int? ?? 0;
    final downvotes = edit['downvotes'] as int? ?? 0;
    final user = edit['user'] as Map<String, dynamic>?;
    final userName = user?['fullName'] as String? ??
        user?['email'] as String? ??
        'Người dùng';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  child: Text(userName[0].toUpperCase()),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        type == 'add_video'
                            ? 'Đã thêm video'
                            : type == 'add_image'
                                ? 'Đã thêm hình ảnh'
                                : 'Đã đóng góp',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.thumb_up_outlined, size: 18),
                      onPressed: () => _voteOnEdit(edit['id'], true),
                      tooltip: 'Upvote',
                    ),
                    Text('$upvotes'),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.thumb_down_outlined, size: 18),
                      onPressed: () => _voteOnEdit(edit['id'], false),
                      tooltip: 'Downvote',
                    ),
                    Text('$downvotes'),
                    if (_userRole == 'admin') ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            size: 18, color: Colors.red),
                        onPressed: () => _removeEdit(edit['id']),
                        tooltip: 'Gỡ bài',
                      ),
                    ],
                  ],
                ),
              ],
            ),
            if (description != null && description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(description),
            ],
            if (media != null) ...[
              const SizedBox(height: 12),
              if (media['imageUrl'] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _buildFullUrl(media['imageUrl']),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 200,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: Colors.grey.shade200,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image,
                                  color: Colors.grey.shade400),
                              SizedBox(height: 8),
                              Text(
                                'Không thể tải hình ảnh',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              if (media['videoUrl'] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _VideoPlayerWidget(
                      videoUrl: _buildFullUrl(media['videoUrl'])),
                ),
              if (media['caption'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    media['caption'],
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _voteOnEdit(String editId, bool isUpvote) async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.voteOnContentEdit(editId, isUpvote: isUpvote);
      _loadCommunityEdits(); // Reload to update votes
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi vote: $e')),
        );
      }
    }
  }

  Future<void> _removeEdit(String editId) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gỡ bài đóng góp'),
        content: const Text(
            'Bạn có chắc chắn muốn gỡ bài đóng góp này? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Gỡ bài'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.removeContentEdit(editId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã gỡ bài đóng góp thành công')),
        );
        _loadCommunityEdits(); // Reload to remove deleted edit
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi gỡ bài: $e')),
        );
      }
    }
  }

  Future<void> _showAddEditDialog() async {
    final success = await showDialog<bool>(
      context: context,
      builder: (context) => _AddEditDialog(
        contentId: widget.contentId,
      ),
    );

    if (success == true && mounted) {
      _loadCommunityEdits();
    }
  }

  Widget _buildCompleteButton() {
    if (_isCompleted) {
      // Show navigation buttons after completion
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Đã hoàn thành! 🎉',
                    style: TextStyle(
                      color: Colors.green.shade900,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Back button
              if (_prevContentItem != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      print('Prev button pressed');
                      print('_prevContentItem: $_prevContentItem');
                      if (_prevContentItem != null) {
                        final prevId = _prevContentItem!['id'] as String?;
                        print('Navigating to previous content: $prevId');
                        if (prevId != null && prevId.isNotEmpty) {
                          // Use go() to replace current route instead of pushing new one
                          context.go('/content/$prevId');
                        } else {
                          print('Error: prevContentItem id is null or empty');
                        }
                      } else {
                        print('Error: _prevContentItem is null');
                      }
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Bài trước'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                )
              else
                // Show info message if this is the first item
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.grey.shade600, size: 20),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Đây là bài đầu tiên',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_prevContentItem != null && _nextContentItem != null)
                const SizedBox(width: 12),
              // Next button
              if (_nextContentItem != null)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      print('Next button pressed');
                      print('_nextContentItem: $_nextContentItem');
                      if (_nextContentItem != null) {
                        final nextId = _nextContentItem!['id'] as String?;
                        print('Navigating to next content: $nextId');
                        if (nextId != null && nextId.isNotEmpty) {
                          // Use go() to replace current route instead of pushing new one
                          context.go('/content/$nextId');
                        } else {
                          print('Error: nextContentItem id is null or empty');
                        }
                      } else {
                        print('Error: _nextContentItem is null');
                      }
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Bài tiếp theo'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue,
                    ),
                  ),
                )
              else
                // Show info message if this is the last item
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.grey.shade600, size: 20),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Đây là bài cuối cùng',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Back to node button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                // Always navigate directly to node detail screen
                final nodeId = _contentData?['nodeId'] as String?;
                if (nodeId != null) {
                  context.go('/nodes/$nodeId');
                } else {
                  // Fallback: try to pop or go to dashboard
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/dashboard');
                  }
                }
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Quay lại Node'),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isCompleting ? null : () => _markComplete(),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.green,
        ),
        child: _isCompleting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Mark Complete',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}

class _AddEditDialog extends StatefulWidget {
  final String contentId;

  const _AddEditDialog({
    required this.contentId,
  });

  @override
  State<_AddEditDialog> createState() => _AddEditDialogState();
}

class _AddEditDialogState extends State<_AddEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _captionController = TextEditingController();
  String? _selectedType = 'add_image';
  File? _selectedImage;
  File? _selectedVideo;
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;
  String? _uploadProgress;

  @override
  void dispose() {
    _descriptionController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _selectedType = 'add_image';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi chọn hình ảnh: $e')),
      );
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        // Validate video file
        final file = File(video.path);
        final fileSize = await file.length();
        const maxSize = 100 * 1024 * 1024; // 100MB

        // Check file size
        if (fileSize > maxSize) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Video quá lớn. Kích thước tối đa: 100MB. Video của bạn: ${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB'),
              duration: const Duration(seconds: 5),
            ),
          );
          return;
        }

        // Check file extension
        final extension = video.path.toLowerCase().split('.').last;
        const allowedExtensions = ['mp4', 'webm', 'mov', 'quicktime'];
        if (!allowedExtensions.contains(extension)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Định dạng video không được hỗ trợ. Chỉ chấp nhận: MP4, WebM, MOV'),
              duration: const Duration(seconds: 5),
            ),
          );
          return;
        }

        setState(() {
          _selectedVideo = file;
          _selectedType = 'add_video';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi chọn video: $e')),
      );
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedType == 'add_image' && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn hình ảnh')),
      );
      return;
    }

    if (_selectedType == 'add_video' && _selectedVideo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn video')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _uploadProgress = 'Đang chuẩn bị...';
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      String? imageUrl;
      String? videoUrl;

      // Upload image if needed
      if (_selectedImage != null) {
        setState(() {
          _uploadProgress = 'Đang tải lên hình ảnh...';
        });
        final uploadResult = await apiService.uploadImageForEdit(
          _selectedImage!.path,
        );
        imageUrl = uploadResult['imageUrl'] as String?;
      }

      // Upload video if needed
      if (_selectedVideo != null) {
        setState(() {
          _uploadProgress = 'Đang tải lên video... (có thể mất vài phút)';
        });
        final uploadResult = await apiService.uploadVideoForEdit(
          _selectedVideo!.path,
        );
        videoUrl = uploadResult['videoUrl'] as String?;
      }

      // Submit edit
      setState(() {
        _uploadProgress = 'Đang gửi đóng góp...';
      });

      await apiService.submitContentEdit(
        contentItemId: widget.contentId,
        type: _selectedType!,
        imageUrl: imageUrl,
        videoUrl: videoUrl,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        caption: _captionController.text.isEmpty
            ? null
            : _captionController.text,
      );

      // Close dialog first
      if (mounted) {
        Navigator.of(context).pop(true);
        
        // Show success dialog
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade700, size: 28),
                const SizedBox(width: 12),
                const Text('Thành công!'),
              ],
            ),
            content: const Text(
              'Đã gửi đóng góp thành công! Cảm ơn bạn đã đóng góp. Đóng góp của bạn sẽ được admin xem xét và duyệt.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Đóng'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _uploadProgress = null;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi gửi đóng góp: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AlertDialog(
          title: const Text('Thêm đóng góp'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Loại đóng góp:'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'add_image',
                        child: Text('Thêm hình ảnh'),
                      ),
                      DropdownMenuItem(
                        value: 'add_video',
                        child: Text('Thêm video'),
                      ),
                    ],
                    onChanged: _isSubmitting
                        ? null
                        : (value) {
                            setState(() {
                              _selectedType = value;
                            });
                          },
                  ),
                  const SizedBox(height: 16),
                  if (_selectedType == 'add_image')
                    ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _pickImage,
                      icon: const Icon(Icons.image),
                      label: const Text('Chọn hình ảnh'),
                    ),
                  if (_selectedType == 'add_video') ...[
                    ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _pickVideo,
                      icon: const Icon(Icons.video_library),
                      label: const Text('Chọn video'),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline,
                                  size: 16, color: Colors.blue.shade700),
                              const SizedBox(width: 4),
                              Text(
                                'Yêu cầu video:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '• Định dạng: MP4, WebM, MOV\n• Kích thước tối đa: 100MB',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_selectedImage != null) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _selectedImage!,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                  if (_selectedVideo != null) ...[
                    const SizedBox(height: 12),
                    FutureBuilder<int>(
                      future: _selectedVideo!.length(),
                      builder: (context, snapshot) {
                        final fileSize = snapshot.data ?? 0;
                        final fileSizeMB =
                            (fileSize / 1024 / 1024).toStringAsFixed(2);
                        final fileName =
                            _selectedVideo!.path.split(Platform.pathSeparator).last;

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.video_file,
                                      color: Colors.blue.shade700),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      fileName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Kích thước: ${fileSizeMB}MB',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // For local files, show a nice placeholder instead of trying to preview
                              // Video preview for local files is not supported on all platforms
                              Container(
                                height: 150,
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue.shade200, width: 2),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.video_library,
                                      size: 48,
                                      color: Colors.blue.shade700,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Video đã được chọn',
                                      style: TextStyle(
                                        color: Colors.blue.shade900,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Video sẽ được tải lên khi bạn gửi',
                                      style: TextStyle(
                                        color: Colors.blue.shade700,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _captionController,
                    decoration: const InputDecoration(
                      labelText: 'Chú thích (tùy chọn)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    enabled: !_isSubmitting,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả về đóng góp này',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    enabled: !_isSubmitting,
                  ),
                  if (_isSubmitting && _uploadProgress != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _uploadProgress!,
                              style: TextStyle(
                                color: Colors.blue.shade900,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _handleSubmit,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Gửi'),
            ),
          ],
        ),
        // Loading overlay
        if (_isSubmitting)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
      ],
    );
  }
}

class _VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final bool isLocalFile;

  const _VideoPlayerWidget({
    required this.videoUrl,
    this.isLocalFile = false,
  });

  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _useHtmlPlayer = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void didUpdateWidget(_VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reinitialize if video URL changed
    if (oldWidget.videoUrl != widget.videoUrl) {
      _controller?.dispose();
      _isInitialized = false;
      _hasError = false;
      _errorMessage = null;
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    try {
      VideoPlayerController controller;
      if (widget.isLocalFile) {
        // Check if file exists
        final file = File(widget.videoUrl);
        if (!await file.exists()) {
          throw Exception('File không tồn tại: ${widget.videoUrl}');
        }
        
        // Check file size to ensure it's readable
        final fileSize = await file.length();
        if (fileSize == 0) {
          throw Exception('File rỗng hoặc không thể đọc được');
        }
        
        controller = VideoPlayerController.file(file);
        
        // Set error handler
        controller.addListener(() {
          if (controller.value.hasError) {
            if (mounted) {
              setState(() {
                _hasError = true;
                _errorMessage = controller.value.errorDescription ?? 'Lỗi không xác định';
              });
            }
          }
        });
      } else {
        // Video URL should already be full URL from parent widget
        controller =
            VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      }

      // Initialize with timeout
      await controller.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout khi khởi tạo video. Video có thể quá lớn hoặc không hỗ trợ định dạng này.');
        },
      );
      
      if (mounted) {
        setState(() {
          _controller = controller;
          _isInitialized = true;
          _hasError = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      print('Error initializing video: $e');
      print('Error type: ${e.runtimeType}');
      print('Is local file: ${widget.isLocalFile}');
      if (mounted) {
        final errorStr = e.toString();
        final isUnimplementedError = errorStr.contains('UnimplementedError') || 
                                     errorStr.contains('unimplemented');
        
        print('Is UnimplementedError: $isUnimplementedError');
        
        if (isUnimplementedError && widget.isLocalFile) {
          // Local file UnimplementedError
          setState(() {
            _hasError = true;
            _errorMessage = 'Preview video local không được hỗ trợ trên platform này. Video sẽ được tải lên khi bạn gửi.';
          });
        } else if (isUnimplementedError && !widget.isLocalFile) {
          // Network video UnimplementedError - check platform
          // On mobile (Android/iOS), video_player should work, so this might be a different issue
          // On desktop, we'll use fallback player
          print('UnimplementedError detected for network video');
          try {
            // Check if we're on a platform that supports video_player
            final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
            if (isMobile) {
              // On mobile, try to retry with a delay or show error
              print('Mobile platform detected, showing error with retry option');
              setState(() {
                _hasError = true;
                _errorMessage = 'Không thể tải video. Vui lòng thử lại hoặc kiểm tra kết nối mạng.';
              });
            } else {
              // On desktop/web, use fallback player
              print('Desktop/Web platform detected, using fallback player');
              setState(() {
                _hasError = false;
                _useHtmlPlayer = true;
              });
            }
          } catch (e) {
            // If Platform check fails, assume desktop and use fallback
            print('Platform check failed, using fallback player: $e');
            setState(() {
              _hasError = false;
              _useHtmlPlayer = true;
            });
          }
        } else {
          // Other errors
          setState(() {
            _hasError = true;
            _errorMessage = errorStr.replaceAll('Exception: ', '').replaceAll('UnimplementedError: ', '');
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Widget _buildHtmlVideoPlayer() {
    // Use WebVideoPlayer widget for web platforms
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: WebVideoPlayer(
        videoUrl: widget.videoUrl,
        height: 200,
      ),
    );
  }

  Future<void> _openVideoInBrowser() async {
    if (widget.isLocalFile) {
      // Can't open local files in browser
      return;
    }
    
    try {
      final uri = Uri.parse(widget.videoUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể mở video trong trình duyệt')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      // Check for UnimplementedError - check both error message and error type
      final isUnimplementedError = _errorMessage != null && 
          (_errorMessage!.contains('Preview video local không được hỗ trợ') ||
           _errorMessage!.toLowerCase().contains('unimplemented') ||
           _errorMessage!.contains('UnimplementedError'));
      
      // Check if it's a network video error (not local file)
      final isNetworkVideoError = !widget.isLocalFile && isUnimplementedError;
      
      print('Build: _hasError=$_hasError, isUnimplementedError=$isUnimplementedError, isNetworkVideoError=$isNetworkVideoError, isLocalFile=${widget.isLocalFile}');
      print('Build: errorMessage=$_errorMessage');
      
      return Container(
        height: widget.isLocalFile ? 150 : 200,
        decoration: BoxDecoration(
          color: isUnimplementedError && widget.isLocalFile 
              ? Colors.blue.shade50 
              : Colors.black,
          borderRadius: BorderRadius.circular(8),
          border: isUnimplementedError && widget.isLocalFile
              ? Border.all(color: Colors.blue.shade200, width: 2)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUnimplementedError && widget.isLocalFile
                  ? Icons.video_library_outlined
                  : isNetworkVideoError
                      ? Icons.video_library_outlined
                      : Icons.error_outline,
              color: isUnimplementedError && widget.isLocalFile
                  ? Colors.blue.shade700
                  : isNetworkVideoError
                      ? Colors.white70
                      : Colors.white70,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              isUnimplementedError && widget.isLocalFile
                  ? 'Video đã được chọn'
                  : isNetworkVideoError
                      ? 'Không thể preview video trên platform này'
                      : 'Không thể preview video',
              style: TextStyle(
                color: isUnimplementedError && widget.isLocalFile
                    ? Colors.blue.shade900
                    : Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: isUnimplementedError && widget.isLocalFile
                        ? Colors.blue.shade800
                        : Colors.white54,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            if (widget.isLocalFile && !isUnimplementedError) ...[
              const SizedBox(height: 8),
              const Text(
                'Video sẽ được tải lên khi bạn gửi',
                style: TextStyle(color: Colors.white54, fontSize: 10),
              ),
            ],
            // Show "Open in browser" button for network videos with UnimplementedError
            if (isNetworkVideoError) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.videoUrl,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _openVideoInBrowser,
                      icon: const Icon(Icons.open_in_browser, size: 16),
                      label: const Text('Mở trong trình duyệt'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextButton.icon(
                      onPressed: _initializeVideo,
                      icon: const Icon(Icons.refresh, color: Colors.white70, size: 16),
                      label: const Text(
                        'Thử lại',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    }

    // Use HTML5 video player if video_player doesn't work
    if (_useHtmlPlayer) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _buildHtmlVideoPlayer(),
      );
    }

    if (!_isInitialized || _controller == null) {
      return Container(
        height: widget.isLocalFile ? 150 : 200,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 8),
              Text(
                'Đang tải video...',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: VideoPlayer(_controller!),
        ),
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              setState(() {
                if (_controller!.value.isPlaying) {
                  _controller!.pause();
                } else {
                  _controller!.play();
                }
              });
            },
            child: Container(
              color: Colors.transparent,
              child: Center(
                child: Icon(
                  _controller!.value.isPlaying
                      ? Icons.pause_circle_outline
                      : Icons.play_circle_outline,
                  size: 64,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 8,
          left: 8,
          right: 8,
          child: VideoProgressIndicator(
            _controller!,
            allowScrubbing: true,
            colors: const VideoProgressColors(
              playedColor: Colors.blue,
              bufferedColor: Colors.grey,
              backgroundColor: Colors.white24,
            ),
          ),
        ),
      ],
    );
  }
}

class _RewardItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _RewardItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
