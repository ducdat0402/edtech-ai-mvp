import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:go_router/go_router.dart';

class PersonalMindMapScreen extends StatefulWidget {
  final String subjectId;

  const PersonalMindMapScreen({
    super.key,
    required this.subjectId,
  });

  @override
  State<PersonalMindMapScreen> createState() => _PersonalMindMapScreenState();
}

class _PersonalMindMapScreenState extends State<PersonalMindMapScreen> {
  bool _isLoading = true;
  bool _exists = false;
  Map<String, dynamic>? _mindMapData;
  String? _error;

  // Chat state - chat riêng cho từng môn học
  bool _isChatMode = false;
  List<Map<String, String>> _chatMessages = [];
  final TextEditingController _chatController = TextEditingController();
  bool _isSending = false;
  bool _canGenerate = false;
  bool _isGenerating = false;
  Map<String, dynamic>? _subjectInfo;

  @override
  void initState() {
    super.initState();
    _checkAndLoadMindMap();
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _checkAndLoadMindMap() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);

      final checkResult =
          await apiService.checkPersonalMindMap(widget.subjectId);
      final exists = checkResult['exists'] as bool? ?? false;

      if (exists) {
        final mindMapResult =
            await apiService.getPersonalMindMap(widget.subjectId);
        setState(() {
          _exists = true;
          _mindMapData = mindMapResult['mindMap'] as Map<String, dynamic>?;
          _isLoading = false;
        });
      } else {
        setState(() {
          _exists = false;
          _mindMapData = null;
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

  /// Bắt đầu chat để tạo lộ trình - HỎI DỰA TRÊN NỘI DUNG MÔN HỌC
  Future<void> _startSubjectChat() async {
    setState(() {
      _isChatMode = true;
      _isLoading = true;
      _chatMessages = [];
      _canGenerate = false;
      _subjectInfo = null;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);

      // Bắt đầu chat session với môn học cụ thể
      final result =
          await apiService.startPersonalMindMapChat(widget.subjectId);

      setState(() {
        _subjectInfo = result['subjectInfo'] as Map<String, dynamic>?;
        _chatMessages = [
          {
            'role': 'assistant',
            'content': result['response'] as String? ?? 'Xin chào!'
          }
        ];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _isChatMode = false;
      });
    }
  }

  /// Gửi tin nhắn trong chat
  Future<void> _sendMessage() async {
    if (_chatController.text.trim().isEmpty || _isSending) return;

    final message = _chatController.text.trim();
    _chatController.clear();

    setState(() {
      _chatMessages.add({'role': 'user', 'content': message});
      _isSending = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final result =
          await apiService.personalMindMapChat(widget.subjectId, message);

      setState(() {
        _chatMessages.add({
          'role': 'assistant',
          'content': result['response'] as String? ?? ''
        });
        _canGenerate = result['canGenerate'] as bool? ?? false;
        _isSending = false;
      });
    } catch (e) {
      setState(() {
        _isSending = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Lỗi: ${e.toString()}'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Tạo lộ trình từ chat đã hoàn thành
  Future<void> _generateMindMap() async {
    setState(() => _isGenerating = true);

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final result =
          await apiService.generatePersonalMindMapFromChat(widget.subjectId);

      final success = result['success'] as bool? ?? false;
      final mindMap = result['mindMap'] as Map<String, dynamic>?;
      final message = result['message'] as String? ?? '';

      if (success && mindMap != null) {
        setState(() {
          _exists = true;
          _mindMapData = mindMap;
          _isChatMode = false;
          _isGenerating = false;
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
        setState(() => _isGenerating = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(message.isNotEmpty ? message : 'Không thể tạo lộ trình'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Lỗi: ${e.toString()}'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Xóa và tạo lại lộ trình
  Future<void> _recreateMindMap() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tạo lại lộ trình?'),
        content: const Text(
          'Lộ trình hiện tại sẽ bị xóa và bạn sẽ cần trả lời lại các câu hỏi để tạo lộ trình mới.\n\n'
          'Bạn có chắc chắn muốn tiếp tục?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Tạo lại', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);

      // Xóa mind map cũ
      await apiService.deletePersonalMindMap(widget.subjectId);

      // Reset chat session
      await apiService.resetPersonalMindMapChat(widget.subjectId);

      if (mounted) {
        // Chuyển sang màn hình chọn phương thức tạo lộ trình (2 options)
        context.pushReplacement(
          '/subjects/${widget.subjectId}/learning-path-choice?force=true',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Lỗi: ${e.toString()}'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lộ trình của bạn'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_isChatMode && !_exists) {
              setState(() => _isChatMode = false);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          if (_exists)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'refresh') {
                  _checkAndLoadMindMap();
                } else if (value == 'recreate') {
                  _recreateMindMap();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'refresh',
                  child: Row(
                    children: [
                      Icon(Icons.refresh, size: 20),
                      SizedBox(width: 8),
                      Text('Làm mới'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'recreate',
                  child: Row(
                    children: [
                      Icon(Icons.replay, size: 20, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Tạo lại lộ trình',
                          style: TextStyle(color: Colors.orange)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorView()
              : _isChatMode
                  ? _buildChatView()
                  : _exists
                      ? _buildMindMapView()
                      : _buildWelcomeView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Lỗi: $_error', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _error = null;
                _isLoading = true;
              });
              _checkAndLoadMindMap();
            },
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade300, Colors.blue.shade400],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.route, size: 60, color: Colors.white),
          ),
          const SizedBox(height: 32),
          const Text(
            'Tạo Lộ Trình Cá Nhân',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'AI sẽ hỏi bạn về kinh nghiệm, mục tiêu và sở thích để tạo lộ trình học tập phù hợp nhất với bạn.',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          // Features
          _buildFeatureItem(Icons.school, 'Hỏi về kinh nghiệm với môn học này'),
          _buildFeatureItem(Icons.flag, 'Xác định mục tiêu học tập cụ thể'),
          _buildFeatureItem(Icons.category, 'Gợi ý các chương bạn quan tâm'),
          _buildFeatureItem(
              Icons.auto_awesome, 'Tạo lộ trình từ bài học có sẵn'),
          const SizedBox(height: 40),
          // Start button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _startSubjectChat,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Tạo lộ trình riêng cho bạn',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.purple),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  /// Chat view - hỏi dựa trên nội dung môn học
  Widget _buildChatView() {
    return Column(
      children: [
        // Header với thông tin môn học và trạng thái
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.purple.shade50,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_subjectInfo != null) ...[
                Row(
                  children: [
                    const Icon(Icons.school, color: Colors.purple, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _subjectInfo!['name'] as String? ?? 'Môn học',
                        style: TextStyle(
                          color: Colors.purple.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      '${_subjectInfo!['totalLessons'] ?? 0} bài học',
                      style: TextStyle(
                        color: Colors.purple.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  const Icon(Icons.psychology, color: Colors.purple, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _canGenerate
                          ? '✅ Đã đủ thông tin! Bạn có thể tạo lộ trình.'
                          : '🔄 Đang thu thập thông tin từ bạn...',
                      style: TextStyle(
                        color: Colors.purple.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (_canGenerate)
                    TextButton.icon(
                      onPressed: _isGenerating ? null : _generateMindMap,
                      icon: _isGenerating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome, size: 18),
                      label:
                          Text(_isGenerating ? 'Đang tạo...' : 'Tạo lộ trình'),
                    ),
                ],
              ),
            ],
          ),
        ),
        // Chat messages
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _chatMessages.length + (_isSending ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _chatMessages.length && _isSending) {
                return _buildTypingIndicator();
              }
              final msg = _chatMessages[index];
              return _buildChatBubble(
                msg['content']!,
                msg['role'] == 'user',
              );
            },
          ),
        ),
        // Input
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  decoration: InputDecoration(
                    hintText: 'Nhập tin nhắn...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _isSending ? null : _sendMessage,
                icon: Icon(
                  Icons.send,
                  color: _isSending ? Colors.grey : Colors.purple,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChatBubble(String text, bool isUser) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.purple.shade100,
              child:
                  const Icon(Icons.smart_toy, size: 18, color: Colors.purple),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? Colors.purple : Colors.grey.shade100,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue.shade100,
              child: const Icon(Icons.person, size: 18, color: Colors.blue),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.purple.shade100,
            child: const Icon(Icons.smart_toy, size: 18, color: Colors.purple),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                _buildDot(1),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + index * 200),
      builder: (context, value, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey.shade400,
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildMindMapView() {
    if (_mindMapData == null) {
      return const Center(child: Text('Không có dữ liệu'));
    }

    final nodes = _mindMapData!['nodes'] as List<dynamic>? ?? [];
    final learningGoal = _mindMapData!['learningGoal'] as String? ?? '';

    // Chỉ tính progress từ các node có bài học thực tế
    final nodesWithContent = nodes.where((n) {
      final node = n as Map<String, dynamic>;
      final metadata = node['metadata'] as Map<String, dynamic>?;
      final linkedLearningNodeId = metadata?['linkedLearningNodeId'] as String?;
      final level = node['level'] as int? ?? 3;
      return level == 3 &&
          linkedLearningNodeId != null &&
          linkedLearningNodeId.isNotEmpty;
    }).toList();

    final totalNodes = nodesWithContent.length;
    final completedNodes = nodesWithContent.where((n) {
      final node = n as Map<String, dynamic>;
      return node['status'] == 'completed';
    }).length;
    final progressPercent =
        totalNodes > 0 ? (completedNodes / totalNodes) * 100 : 0.0;

    return Column(
      children: [
        // Progress header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade400, Colors.blue.shade400],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Mục tiêu của bạn',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ),
                  // Nút tạo lại lộ trình
                  TextButton.icon(
                    onPressed: _recreateMindMap,
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white24,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                    ),
                    icon:
                        const Icon(Icons.replay, color: Colors.white, size: 16),
                    label: const Text(
                      'Tạo lại',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                learningGoal,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tiến độ: $completedNodes/$totalNodes bước',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: progressPercent / 100,
                          backgroundColor: Colors.white24,
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.white),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '${progressPercent.toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Mind map list view - Chỉ hiện tới topic (level 2)
        Expanded(
          child: _buildLearnerMindMapList(nodes),
        ),
      ],
    );
  }

  /// Learner view: chỉ hiện level 1 (root) và level 2 (topics/milestones)
  /// Không hiện level 3 (learning nodes) - cần hoàn thành bài tập để unlock
  Widget _buildLearnerMindMapList(List<dynamic> allNodes) {
    // Lấy level 2 nodes (topics/milestones)
    final topicNodes = allNodes.where((n) {
      final node = n as Map<String, dynamic>;
      final level = node['level'] as int? ?? 3;
      return level == 2;
    }).toList();

    if (topicNodes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Chưa có chủ đề nào trong lộ trình này',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: topicNodes.length,
      itemBuilder: (context, index) {
        final topic = topicNodes[index] as Map<String, dynamic>;
        final topicId = topic['id'] as String;
        final title = topic['title'] as String? ?? 'Chủ đề';
        final description = topic['description'] as String? ?? '';
        final status = topic['status'] as String? ?? 'not_started';
        final metadata = topic['metadata'] as Map<String, dynamic>?;
        final icon = metadata?['icon'] as String? ?? '📁';

        // Đếm số bài học con (level 3) thuộc topic này
        final childLessons = allNodes.where((n) {
          final node = n as Map<String, dynamic>;
          return node['parentId'] == topicId && (node['level'] as int? ?? 3) == 3;
        }).toList();

        final completedLessons = childLessons.where((n) {
          final node = n as Map<String, dynamic>;
          return node['status'] == 'completed';
        }).length;

        final totalLessons = childLessons.length;

        // Check diamond lock status from backend
        final allLessonsLocked = childLessons.every((l) {
          final lesson = l as Map<String, dynamic>;
          return lesson['isLocked'] == true && lesson['status'] != 'completed';
        });

        Color statusColor;
        IconData statusIcon;
        String statusText;

        if (completedLessons == totalLessons && totalLessons > 0) {
          statusColor = Colors.green;
          statusIcon = Icons.check_circle;
          statusText = 'Hoàn thành';
        } else if (completedLessons > 0) {
          statusColor = Colors.blue;
          statusIcon = Icons.play_circle;
          statusText = 'Đang học';
        } else if (!allLessonsLocked) {
          statusColor = Colors.blue;
          statusIcon = Icons.play_circle;
          statusText = 'Sẵn sàng';
        } else {
          statusColor = Colors.orange;
          statusIcon = Icons.lock;
          statusText = 'Cần mở khóa 💎';
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: completedLessons == totalLessons && totalLessons > 0
                  ? Colors.green.shade200
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: InkWell(
            onTap: () {
              _showTopicLessons(
                title: title,
                description: description,
                icon: icon,
                totalLessons: totalLessons,
                completedLessons: completedLessons,
                status: status,
                childLessons: childLessons,
              );
            },
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Index
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Icon
                      Text(icon, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      // Title & status
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(statusIcon, size: 14, color: statusColor),
                                const SizedBox(width: 4),
                                Text(
                                  statusText,
                                  style: TextStyle(fontSize: 12, color: statusColor),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Lesson count badge
                      if (totalLessons > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$completedLessons/$totalLessons',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                  // Description
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      description,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  // Progress bar
                  if (totalLessons > 0) ...[
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: totalLessons > 0 ? completedLessons / totalLessons : 0,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      minHeight: 4,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Hiện danh sách bài học trong topic để learner chọn học
  /// Uses diamond-based lock from backend (isLocked field)
  void _showTopicLessons({
    required String title,
    required String description,
    required String icon,
    required int totalLessons,
    required int completedLessons,
    required String status,
    required List<dynamic> childLessons,
  }) {
    // Check if ALL lessons in this topic are locked (diamond-based)
    final allLocked = childLessons.every((l) {
      final lesson = l as Map<String, dynamic>;
      final isLocked = lesson['isLocked'] as bool? ?? false;
      final lessonStatus = lesson['status'] as String? ?? 'not_started';
      return isLocked && lessonStatus != 'completed';
    });

    if (allLocked && completedLessons == 0) {
      // All lessons locked -> show unlock dialog
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔒', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'Chủ đề này cần mở khóa bằng kim cương.\nBạn có thể mở khóa từng topic, chương hoặc cả môn.',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Đóng'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.push('/subjects/${widget.subjectId}/unlock');
                      },
                      icon: const Text('💎', style: TextStyle(fontSize: 16)),
                      label: const Text('Mở khóa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      return;
    }

    // Show lesson list with diamond-based lock status
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          maxChildSize: 0.85,
          minChildSize: 0.3,
          expand: false,
          builder: (_, scrollController) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Title row
                  Row(
                    children: [
                      Text(icon, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(
                              '$completedLessons/$totalLessons bài hoàn thành',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: totalLessons > 0 ? completedLessons / totalLessons : 0,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Lesson list
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: childLessons.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final lesson = childLessons[index] as Map<String, dynamic>;
                        final lessonTitle = lesson['title'] as String? ?? 'Bài học';
                        final lessonStatus = lesson['status'] as String? ?? 'not_started';
                        final lessonMeta = lesson['metadata'] as Map<String, dynamic>?;
                        final lessonIcon = lessonMeta?['icon'] as String? ?? '📖';
                        final linkedNodeId = lessonMeta?['linkedLearningNodeId'] as String?;
                        final isLocked = lesson['isLocked'] as bool? ?? false;
                        final diamondCost = lesson['diamondCost'] as int? ?? 25;
                        final isCompleted = lessonStatus == 'completed';
                        final accessible = !isLocked || isCompleted;

                        Color tileColor;
                        IconData trailingIcon;
                        if (isCompleted) {
                          tileColor = Colors.green;
                          trailingIcon = Icons.replay;
                        } else if (accessible) {
                          tileColor = Colors.blue;
                          trailingIcon = Icons.play_circle_fill;
                        } else {
                          tileColor = Colors.grey;
                          trailingIcon = Icons.lock_outline;
                        }

                        return Material(
                          color: isCompleted
                              ? Colors.green.withOpacity(0.04)
                              : accessible ? null : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: () {
                              if (accessible && linkedNodeId != null) {
                                Navigator.pop(ctx);
                                context.push(
                                  '/lessons/$linkedNodeId/types',
                                  extra: {'title': lessonTitle},
                                ).then((_) => _checkAndLoadMindMap());
                              } else if (!accessible) {
                                Navigator.pop(ctx);
                                _showUnlockDialog(linkedNodeId ?? '', lessonTitle);
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isCompleted
                                      ? Colors.green.withOpacity(0.3)
                                      : accessible ? tileColor.withOpacity(0.3) : Colors.grey.shade200,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 30, height: 30,
                                    decoration: BoxDecoration(
                                      color: tileColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: isCompleted
                                          ? Icon(Icons.check, color: tileColor, size: 18)
                                          : Text('${index + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: tileColor, fontSize: 14)),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(lessonIcon, style: const TextStyle(fontSize: 22)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(lessonTitle, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: accessible ? null : Colors.grey)),
                                        const SizedBox(height: 2),
                                        if (isCompleted)
                                          Row(children: [
                                            Icon(Icons.check_circle, size: 12, color: Colors.green.shade400),
                                            const SizedBox(width: 3),
                                            Text('Đã hoàn thành', style: TextStyle(fontSize: 11, color: Colors.green.shade600)),
                                            const SizedBox(width: 6),
                                            Text('· Nhấn để xem lại', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                                          ])
                                        else if (accessible)
                                          Text('Nhấn để học', style: TextStyle(fontSize: 11, color: tileColor))
                                        else
                                          Row(children: [
                                            Icon(Icons.lock, size: 11, color: Colors.orange.shade400),
                                            const SizedBox(width: 3),
                                            Text('$diamondCost 💎 để mở khóa', style: TextStyle(fontSize: 11, color: Colors.orange.shade600)),
                                          ]),
                                      ],
                                    ),
                                  ),
                                  Icon(trailingIcon, color: tileColor, size: 24),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
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

  void _showUnlockDialog(String nodeId, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bài học chưa mở khóa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bài "$title" cần được mở khóa bằng kim cương.'),
            const SizedBox(height: 12),
            const Text('Bạn có thể mở khóa từng topic, chương, hoặc cả môn để tiết kiệm hơn.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/subjects/${widget.subjectId}/unlock');
            },
            icon: const Text('💎', style: TextStyle(fontSize: 16)),
            label: const Text('Mở khóa'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/payment');
            },
            child: const Text('Mua kim cương'),
          ),
        ],
      ),
    );
  }
}
