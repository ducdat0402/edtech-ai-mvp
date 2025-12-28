import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:edtech_mobile/core/services/api_service.dart';

class SubjectIntroScreen extends StatefulWidget {
  final String subjectId;

  const SubjectIntroScreen({
    super.key,
    required this.subjectId,
  });

  @override
  State<SubjectIntroScreen> createState() => _SubjectIntroScreenState();
}

class _SubjectIntroScreenState extends State<SubjectIntroScreen> {
  Map<String, dynamic>? _introData;
  bool _isLoading = true;
  String? _error;
  int _currentTutorialStep = 0;
  bool _showTutorial = true;

  @override
  void initState() {
    super.initState();
    _loadSubjectIntro();
  }

  Future<void> _loadSubjectIntro() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final data = await apiService.getSubjectIntro(widget.subjectId);
      setState(() {
        _introData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _nextTutorialStep() {
    if (_introData == null) return;
    final steps = _introData!['tutorialSteps'] as List;
    if (_currentTutorialStep < steps.length - 1) {
      setState(() {
        _currentTutorialStep++;
      });
    } else {
      setState(() {
        _showTutorial = false;
      });
    }
  }

  void _skipTutorial() {
    setState(() {
      _showTutorial = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giới thiệu khóa học'),
        actions: [
          if (_showTutorial)
            TextButton(
              onPressed: _skipTutorial,
              child: const Text(
                'Bỏ qua',
                style: TextStyle(color: Colors.white),
              ),
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
                        onPressed: _loadSubjectIntro,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _introData == null
                  ? const Center(child: Text('No data available'))
                  : Stack(
                      children: [
                        // Main content
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Subject header
                              _buildSubjectHeader(),
                              const SizedBox(height: 24),

                              // Knowledge graph
                              _buildKnowledgeGraph(),
                              const SizedBox(height: 24),

                              // Course outline
                              _buildCourseOutline(),
                              const SizedBox(height: 24),

                              // Start learning button
                              _buildStartButton(),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),

                        // Tutorial overlay
                        if (_showTutorial) _buildTutorialOverlay(),
                      ],
                    ),
    );
  }

  Widget _buildSubjectHeader() {
    final subject = _introData!['subject'] as Map<String, dynamic>;
    final track = subject['track'] as String;
    final trackColor = track == 'explorer' ? Colors.green : Colors.blue;

    return Card(
      color: trackColor.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: trackColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    track.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              subject['name'] ?? 'Subject',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subject['description'] ?? '',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKnowledgeGraph() {
    final graph = _introData!['knowledgeGraph'] as Map<String, dynamic>;
    final nodes = graph['nodes'] as List;
    final edges = graph['edges'] as List;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bản đồ kiến thức',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 400,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                // Edges (lines) - drawn first
                CustomPaint(
                  painter: KnowledgeGraphPainter(
                    nodes: nodes,
                    edges: edges,
                  ),
                ),
                // Nodes (interactive) - drawn on top
                ...nodes.map((node) {
                  final nodeData = node as Map<String, dynamic>;
                  final position = nodeData['position'] as Map<String, dynamic>;
                  final x = (position['x'] as num).toDouble();
                  final y = (position['y'] as num).toDouble();
                  final isUnlocked = nodeData['isUnlocked'] as bool? ?? false;
                  final isCompleted = nodeData['isCompleted'] as bool? ?? false;

                  return Positioned(
                    left: x - 30,
                    top: y - 30,
                    child: GestureDetector(
                      onTap: () {
                        // Navigate to node detail
                        // context.go('/nodes/${nodeData['id']}');
                      },
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? Colors.green
                              : isUnlocked
                                  ? Colors.blue
                                  : Colors.grey.shade400,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '${nodeData['order'] ?? ''}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCourseOutline() {
    final outline = _introData!['courseOutline'] as Map<String, dynamic>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tổng quan khóa học',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _OutlineItem(
                    icon: Icons.book,
                    label: 'Chủ đề',
                    value: '${outline['totalNodes'] ?? 0}',
                  ),
                ),
                Expanded(
                  child: _OutlineItem(
                    icon: Icons.lightbulb,
                    label: 'Khái niệm',
                    value: '${outline['totalConcepts'] ?? 0}',
                  ),
                ),
                Expanded(
                  child: _OutlineItem(
                    icon: Icons.code,
                    label: 'Ví dụ',
                    value: '${outline['totalExamples'] ?? 0}',
                  ),
                ),
                Expanded(
                  child: _OutlineItem(
                    icon: Icons.calendar_today,
                    label: 'Ngày',
                    value: '${outline['estimatedDays'] ?? 0}',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startLearning() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      
      // Show loading
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // Generate skill tree
      await apiService.generateSkillTree(widget.subjectId);

      // Close loading
      if (mounted) {
        Navigator.pop(context);
      }

      // Navigate to skill tree
      if (mounted) {
        context.go('/skill-tree?subjectId=${widget.subjectId}');
      }
    } catch (e) {
      // Close loading if still open
      if (mounted) {
        Navigator.pop(context);
      }

      // Show error
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

  Widget _buildStartButton() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.purple.shade400],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _startLearning,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.account_tree,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bắt đầu học',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Tạo Skill Tree và bắt đầu hành trình',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTutorialOverlay() {
    final steps = _introData!['tutorialSteps'] as List;
    if (_currentTutorialStep >= steps.length) return const SizedBox.shrink();

    final currentStep = steps[_currentTutorialStep] as Map<String, dynamic>;

    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Bước ${currentStep['step']}/${steps.length}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  currentStep['title'] ?? '',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  currentStep['description'] ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_currentTutorialStep > 0)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _currentTutorialStep--;
                          });
                        },
                        child: const Text('Quay lại'),
                      ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (_currentTutorialStep < steps.length - 1) {
                          _nextTutorialStep();
                        } else {
                          // Last step - start learning
                          _skipTutorial();
                          _startLearning();
                        }
                      },
                      child: Text(
                        _currentTutorialStep < steps.length - 1
                            ? 'Tiếp theo'
                            : 'Bắt đầu',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OutlineItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _OutlineItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Colors.blue),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

class KnowledgeGraphPainter extends CustomPainter {
  final List nodes;
  final List edges;

  KnowledgeGraphPainter({
    required this.nodes,
    required this.edges,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw edges
    for (final edge in edges) {
      final edgeData = edge as Map<String, dynamic>;
      final fromId = edgeData['from'] as String;
      final toId = edgeData['to'] as String;

      final fromNode = nodes.firstWhere(
        (n) => (n as Map)['id'] == fromId,
        orElse: () => null,
      );
      final toNode = nodes.firstWhere(
        (n) => (n as Map)['id'] == toId,
        orElse: () => null,
      );

      if (fromNode != null && toNode != null) {
        final fromPos = (fromNode as Map)['position'] as Map<String, dynamic>;
        final toPos = (toNode as Map)['position'] as Map<String, dynamic>;
        final fromX = (fromPos['x'] as num).toDouble();
        final fromY = (fromPos['y'] as num).toDouble();
        final toX = (toPos['x'] as num).toDouble();
        final toY = (toPos['y'] as num).toDouble();

        canvas.drawLine(
          Offset(fromX, fromY),
          Offset(toX, toY),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

