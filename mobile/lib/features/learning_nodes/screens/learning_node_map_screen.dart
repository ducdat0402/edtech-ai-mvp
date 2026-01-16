import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:edtech_mobile/core/services/api_service.dart';

class LearningNodeMapScreen extends StatefulWidget {
  final String subjectId;

  const LearningNodeMapScreen({
    super.key,
    required this.subjectId,
  });

  @override
  State<LearningNodeMapScreen> createState() => _LearningNodeMapScreenState();
}

class _LearningNodeMapScreenState extends State<LearningNodeMapScreen> {
  Map<String, dynamic>? _introData;
  List<dynamic>? _availableNodes;
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
      
      // Load both intro data (for full graph) and available nodes (for unlock status)
      final introData = await apiService.getSubjectIntro(widget.subjectId);
      final availableNodes = await apiService.getSubjectNodes(widget.subjectId);
      
      setState(() {
        _introData = introData;
        _availableNodes = availableNodes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onNodeTap(String nodeId, bool isUnlocked) {
    if (!isUnlocked) {
      // Show message that node is locked
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chủ đề này chưa được mở khóa. Hãy hoàn thành các chủ đề trước đó!'),
        ),
      );
      return;
    }

    // Navigate to node detail or content
    // TODO: Create node detail screen
    // context.go('/nodes/$nodeId');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _introData?['subject']?['name'] ?? 'Bản đồ kiến thức',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // Show info dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Fog of War'),
                  content: const Text(
                    'Bạn chỉ thấy các chủ đề đã mở khóa. Hoàn thành chủ đề trước để mở khóa chủ đề tiếp theo.',
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
                      child: const Text('Hiểu rồi'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
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
              : _introData == null
                  ? const Center(child: Text('No data available'))
                  : _buildNodeMap(),
    );
  }

  Widget _buildNodeMap() {
    final graph = _introData!['knowledgeGraph'] as Map<String, dynamic>;
    final nodes = graph['nodes'] as List;
    final edges = graph['edges'] as List;
    final availableNodeIds = _availableNodes?.map((n) => n['id'] as String).toList() ?? [];

    // Update unlock status based on available nodes
    final updatedNodes = (nodes as List<dynamic>).map((node) {
      final nodeData = Map<String, dynamic>.from(node as Map);
      final nodeId = nodeData['id'] as String;
      nodeData['isUnlocked'] = availableNodeIds.contains(nodeId);
      return nodeData;
    }).toList();

    return SingleChildScrollView(
      child: Column(
        children: [
          // Legend
          _buildLegend(),
          const SizedBox(height: 16),
          
          // Node Map
          Container(
            height: MediaQuery.of(context).size.height * 0.7,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  // Background with fog effect
                  CustomPaint(
                    painter: FogOfWarPainter(
                      nodes: updatedNodes,
                      edges: edges,
                    ),
                    size: Size.infinite,
                  ),
                  
                  // Interactive nodes
                  ...updatedNodes.map((node) {
                    final nodeData = node as Map<String, dynamic>;
                    final position = nodeData['position'] as Map<String, dynamic>;
                    final x = (position['x'] as num).toDouble();
                    final y = (position['y'] as num).toDouble();
                    final isUnlocked = nodeData['isUnlocked'] as bool? ?? false;
                    final isCompleted = nodeData['isCompleted'] as bool? ?? false;
                    final nodeId = nodeData['id'] as String;

                    return Positioned(
                      left: x - 50,
                      top: y - 50,
                      child: GestureDetector(
                        onTap: () {
                          if (isUnlocked) {
                            context.push('/nodes/$nodeId');
                          } else {
                            _onNodeTap(nodeId, isUnlocked);
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? Colors.green.shade400
                                : isUnlocked
                                    ? Colors.blue.shade400
                                    : Colors.grey.shade400,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (isCompleted
                                        ? Colors.green
                                        : isUnlocked
                                            ? Colors.blue
                                            : Colors.grey)
                                    .withOpacity(0.5),
                                blurRadius: isUnlocked ? 12 : 4,
                                spreadRadius: isUnlocked ? 2 : 0,
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Node number
                              Text(
                                '${nodeData['order'] ?? ''}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              ),
                              // Lock icon for locked nodes
                              if (!isUnlocked)
                                Positioned(
                                  bottom: 8,
                                  child: Icon(
                                    Icons.lock,
                                    color: Colors.white.withOpacity(0.8),
                                    size: 20,
                                  ),
                                ),
                              // Check icon for completed nodes
                              if (isCompleted)
                                const Positioned(
                                  top: 8,
                                  child: Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          
          // Node list (alternative view)
          _buildNodeList(updatedNodes),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _LegendItem(
            color: Colors.green,
            label: 'Đã hoàn thành',
          ),
          _LegendItem(
            color: Colors.blue,
            label: 'Đã mở khóa',
          ),
          _LegendItem(
            color: Colors.grey,
            label: 'Chưa mở khóa',
          ),
        ],
      ),
    );
  }

  Widget _buildNodeList(List<dynamic> nodes) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Danh sách chủ đề',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...nodes.map((node) {
            final nodeData = node as Map<String, dynamic>;
            final isUnlocked = nodeData['isUnlocked'] as bool? ?? false;
            final isCompleted = nodeData['isCompleted'] as bool? ?? false;
            final nodeId = nodeData['id'] as String;
            final title = nodeData['title'] as String? ?? '';

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: isCompleted
                  ? Colors.green.shade50
                  : isUnlocked
                      ? Colors.blue.shade50
                      : Colors.grey.shade100,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isCompleted
                      ? Colors.green
                      : isUnlocked
                          ? Colors.blue
                          : Colors.grey,
                  child: Text(
                    '${nodeData['order'] ?? ''}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(title),
                subtitle: Text(
                  isCompleted
                      ? 'Đã hoàn thành'
                      : isUnlocked
                          ? 'Đã mở khóa - Sẵn sàng học'
                          : 'Chưa mở khóa',
                ),
                trailing: isUnlocked
                    ? const Icon(Icons.arrow_forward_ios, size: 16)
                    : const Icon(Icons.lock, size: 20),
                onTap: () => _onNodeTap(nodeId, isUnlocked),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}

class FogOfWarPainter extends CustomPainter {
  final List nodes;
  final List edges;

  FogOfWarPainter({
    required this.nodes,
    required this.edges,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw fog background
    final fogPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), fogPaint);

    // Draw edges (only for unlocked nodes)
    final edgePaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (final edge in edges) {
      final edgeData = edge as Map<String, dynamic>;
      final fromId = edgeData['from'] as String;
      final toId = edgeData['to'] as String;

      final fromNode = nodes.firstWhere(
        (n) => n['id'] == fromId,
        orElse: () => null,
      );
      final toNode = nodes.firstWhere(
        (n) => n['id'] == toId,
        orElse: () => null,
      );

      if (fromNode != null && toNode != null) {
        final fromUnlocked = fromNode['isUnlocked'] as bool? ?? false;
        final toUnlocked = toNode['isUnlocked'] as bool? ?? false;

        // Only draw edge if at least one node is unlocked
        if (fromUnlocked || toUnlocked) {
          final fromPos = fromNode['position'] as Map<String, dynamic>;
          final toPos = toNode['position'] as Map<String, dynamic>;
          final fromX = (fromPos['x'] as num).toDouble();
          final fromY = (fromPos['y'] as num).toDouble();
          final toX = (toPos['x'] as num).toDouble();
          final toY = (toPos['y'] as num).toDouble();

          // Fade edge if one node is locked
          edgePaint.color = (fromUnlocked && toUnlocked)
              ? Colors.blue.shade300
              : Colors.grey.shade400.withOpacity(0.5);

          canvas.drawLine(
            Offset(fromX, fromY),
            Offset(toX, toY),
            edgePaint,
          );
        }
      }
    }

    // Draw fog overlay for locked nodes
    final lockedNodes = nodes.where((n) {
      final nodeData = n as Map<String, dynamic>;
      return !(nodeData['isUnlocked'] as bool? ?? false);
    }).toList();

    for (final node in lockedNodes) {
      final nodeData = node as Map<String, dynamic>;
      final position = nodeData['position'] as Map<String, dynamic>;
      final x = (position['x'] as num).toDouble();
      final y = (position['y'] as num).toDouble();

      // Draw fog circle around locked node
      final fogCirclePaint = Paint()
        ..color = Colors.black.withOpacity(0.4)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(x, y),
        60,
        fogCirclePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

