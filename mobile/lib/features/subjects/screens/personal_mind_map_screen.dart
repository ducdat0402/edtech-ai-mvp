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

      setState(() {
        _exists = false;
        _mindMapData = null;
      });

      // Bắt đầu chat mới
      await _startSubjectChat();
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
        // Mind map list view - CHỈ HIỂN THỊ CÁC BÀI HỌC CÓ LIÊN KẾT
        Expanded(
          child: Builder(
            builder: (context) {
              // Lọc chỉ lấy các node có bài học thực tế
              final lessonsWithContent = nodes.where((node) {
                final n = node as Map<String, dynamic>;
                final metadata = n['metadata'] as Map<String, dynamic>?;
                final linkedLearningNodeId =
                    metadata?['linkedLearningNodeId'] as String?;
                final level = n['level'] as int? ?? 3;
                // Chỉ hiển thị các node level 3 (lessons) có liên kết đến bài học
                return level == 3 &&
                    linkedLearningNodeId != null &&
                    linkedLearningNodeId.isNotEmpty;
              }).toList();

              if (lessonsWithContent.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Chưa có bài học nào trong lộ trình này',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: lessonsWithContent.length,
                itemBuilder: (context, index) {
                  final node =
                      lessonsWithContent[index] as Map<String, dynamic>;
                  final title = node['title'] as String? ?? '';
                  final status = node['status'] as String? ?? 'not_started';
                  final priority = node['priority'] as String? ?? 'medium';
                  final metadata = node['metadata'] as Map<String, dynamic>?;
                  final icon = metadata?['icon'] as String? ?? '📖';
                  final nodeId = node['id'] as String;
                  final estimatedDays = node['estimatedDays'] as int? ?? 0;
                  final linkedLearningNodeId =
                      metadata?['linkedLearningNodeId'] as String?;

                  return _buildNodeCard(
                    nodeId: nodeId,
                    title: title,
                    status: status,
                    priority: priority,
                    icon: icon,
                    estimatedDays: estimatedDays,
                    index: index + 1, // Start from 1
                    linkedLearningNodeId: linkedLearningNodeId,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNodeCard({
    required String nodeId,
    required String title,
    required String status,
    required String priority,
    required String icon,
    required int estimatedDays,
    required int index,
    String? linkedLearningNodeId,
  }) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Hoàn thành';
        break;
      case 'in_progress':
        statusColor = Colors.blue;
        statusIcon = Icons.play_circle;
        statusText = 'Đang học';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.circle_outlined;
        statusText = 'Chưa bắt đầu';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: status == 'completed'
              ? Colors.green.shade200
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () =>
            _showNodeOptions(nodeId, title, status, linkedLearningNodeId),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Index
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Icon
              Text(icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
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
                        if (estimatedDays > 0) ...[
                          const SizedBox(width: 12),
                          Icon(Icons.schedule,
                              size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            '$estimatedDays ngày',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                        if (linkedLearningNodeId != null) ...[
                          const SizedBox(width: 12),
                          Icon(Icons.link,
                              size: 14, color: Colors.purple.shade400),
                          const SizedBox(width: 4),
                          Text(
                            'Có bài học',
                            style: TextStyle(
                                fontSize: 12, color: Colors.purple.shade400),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Priority badge
              if (priority == 'high')
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Ưu tiên',
                    style: TextStyle(fontSize: 10, color: Colors.red.shade700),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNodeOptions(String nodeId, String title, String currentStatus,
      String? linkedLearningNodeId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              // Nút bắt đầu học nếu có linkedLearningNodeId
              if (linkedLearningNodeId != null) ...[
                ListTile(
                  leading: const Icon(Icons.play_arrow, color: Colors.green),
                  title: const Text('Bắt đầu học'),
                  subtitle: const Text('Chọn mức độ phù hợp với bạn'),
                  onTap: () {
                    Navigator.pop(context);
                    _showDifficultySelection(linkedLearningNodeId, title);
                  },
                ),
                const Divider(),
              ],
              ListTile(
                leading: Icon(
                  Icons.circle_outlined,
                  color: currentStatus == 'not_started'
                      ? Colors.blue
                      : Colors.grey,
                ),
                title: const Text('Chưa bắt đầu'),
                onTap: () {
                  Navigator.pop(context);
                  _updateNodeStatus(nodeId, 'not_started');
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.play_circle,
                  color: currentStatus == 'in_progress'
                      ? Colors.blue
                      : Colors.grey,
                ),
                title: const Text('Đang học'),
                onTap: () {
                  Navigator.pop(context);
                  _updateNodeStatus(nodeId, 'in_progress');
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.check_circle,
                  color:
                      currentStatus == 'completed' ? Colors.green : Colors.grey,
                ),
                title: const Text('Đã hoàn thành'),
                onTap: () {
                  Navigator.pop(context);
                  _updateNodeStatus(nodeId, 'completed');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Hiển thị dialog chọn độ khó trước khi bắt đầu học
  void _showDifficultySelection(String learningNodeId, String title) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                const Icon(
                  Icons.school,
                  size: 48,
                  color: Colors.purple,
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Chọn mức độ học phù hợp với bạn',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),

                // Difficulty options
                _buildDifficultyOption(
                  icon: Icons.sentiment_satisfied,
                  title: 'Đơn giản',
                  subtitle: 'Nội dung cơ bản, dễ hiểu',
                  color: Colors.green,
                  difficulty: 'easy',
                  learningNodeId: learningNodeId,
                ),
                const SizedBox(height: 12),
                _buildDifficultyOption(
                  icon: Icons.auto_awesome,
                  title: 'Chi tiết',
                  subtitle: 'Nội dung đầy đủ, cân bằng',
                  color: Colors.blue,
                  difficulty: 'medium',
                  learningNodeId: learningNodeId,
                ),
                const SizedBox(height: 12),
                _buildDifficultyOption(
                  icon: Icons.rocket_launch,
                  title: 'Chuyên sâu',
                  subtitle: 'Nội dung nâng cao, thử thách',
                  color: Colors.orange,
                  difficulty: 'hard',
                  learningNodeId: learningNodeId,
                ),

                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDifficultyOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required String difficulty,
    required String learningNodeId,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        // Navigate với difficulty parameter
        context.push('/nodes/$learningNodeId?difficulty=$difficulty');
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
          color: color.withOpacity(0.05),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: color),
          ],
        ),
      ),
    );
  }

  Future<void> _updateNodeStatus(String nodeId, String status) async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final result = await apiService.updatePersonalMindMapNode(
        widget.subjectId,
        nodeId,
        status,
      );

      final mindMap = result['mindMap'] as Map<String, dynamic>?;
      if (mindMap != null) {
        setState(() {
          _mindMapData = mindMap;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật trạng thái'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
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
}
