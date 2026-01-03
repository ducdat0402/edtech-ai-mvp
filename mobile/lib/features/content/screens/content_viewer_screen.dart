import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:edtech_mobile/core/services/api_service.dart';

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

  @override
  void initState() {
    super.initState();
    _loadContent();
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
          allItems.sort((a, b) => (a['order'] as int? ?? 0).compareTo(b['order'] as int? ?? 0));
          
          final currentIndex = allItems.indexWhere((item) => item['id'] == widget.contentId);
          
          print('Loaded ${allItems.length} content items');
          print('Current content ID: ${widget.contentId}');
          print('Current index: $currentIndex');
          
          final nextItem = currentIndex >= 0 && currentIndex < allItems.length - 1
              ? allItems[currentIndex + 1]
              : null;
          final prevItem = currentIndex > 0
              ? allItems[currentIndex - 1]
              : null;
          
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
      allItems.sort((a, b) => (a['order'] as int? ?? 0).compareTo(b['order'] as int? ?? 0));
      
      final currentIndex = allItems.indexWhere((item) => item['id'] == widget.contentId);
      
      print('Reloaded ${allItems.length} content items');
      print('Current content ID: ${widget.contentId}');
      print('Current index: $currentIndex');
      
      final nextItem = currentIndex >= 0 && currentIndex < allItems.length - 1
          ? allItems[currentIndex + 1]
          : null;
      final prevItem = currentIndex > 0
          ? allItems[currentIndex - 1]
          : null;
      
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
            if (context.canPop()) {
              context.pop();
            } else {
              // Fallback: navigate to dashboard if can't pop
              final nodeId = _contentData?['nodeId'] as String?;
              if (nodeId != null) {
                context.go('/nodes/$nodeId');
              } else {
                context.go('/dashboard');
              }
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
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
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
              _contentData!['media']['imageUrl'],
              fit: BoxFit.cover,
            ),
          const SizedBox(height: 16),
          if (_contentData!['content'] != null)
            Text(
              _contentData!['content'],
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
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
              _contentData!['media']['imageUrl'],
              fit: BoxFit.cover,
            ),
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
            final isWrong = _showQuizResult &&
                isSelected &&
                index != correctAnswer;

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
                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                            : isWrong
                                ? const Icon(Icons.close, size: 16, color: Colors.white)
                                : isSelected
                                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                                    : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          options[index].toString(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
                onPressed: _selectedQuizAnswer != null ? _submitQuizAnswer : null,
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
                          print('Quiz: Navigating to previous content: $prevId');
                          if (prevId != null && prevId.isNotEmpty) {
                            context.push('/content/$prevId');
                          } else {
                            print('Quiz: Error: prevContentItem id is null or empty');
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
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline, color: Colors.grey.shade600, size: 18),
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
                            context.push('/content/$nextId');
                          } else {
                            print('Quiz: Error: nextContentItem id is null or empty');
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
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline, color: Colors.grey.shade600, size: 18),
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
                  final nodeId = _contentData?['nodeId'] as String?;
                  if (nodeId != null) {
                    context.go('/nodes/$nodeId');
                  } else {
                    if (context.canPop()) {
                      context.pop();
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
          if (_contentData!['content'] != null)
            Text(_contentData!['content']),
          const SizedBox(height: 24),
          _buildCompleteButton(),
        ],
      ),
    );
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
                          // Use push to navigate to previous content
                          context.push('/content/$prevId');
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
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline, color: Colors.grey.shade600, size: 20),
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
                          // Use push to navigate to next content
                          context.push('/content/$nextId');
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
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline, color: Colors.grey.shade600, size: 20),
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
                final nodeId = _contentData?['nodeId'] as String?;
                if (nodeId != null) {
                  // Navigate to node detail
                  context.go('/nodes/$nodeId');
                } else {
                  // Fallback: try to pop if possible
                  if (context.canPop()) {
                    context.pop();
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


