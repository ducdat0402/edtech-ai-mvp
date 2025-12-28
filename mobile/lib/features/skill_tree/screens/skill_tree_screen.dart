import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/core/widgets/error_widget.dart';
import 'package:edtech_mobile/core/widgets/empty_state.dart';
import 'package:edtech_mobile/core/widgets/skeleton_loader.dart';

class SkillTreeScreen extends StatefulWidget {
  final String? subjectId;

  const SkillTreeScreen({
    super.key,
    this.subjectId,
  });

  @override
  State<SkillTreeScreen> createState() => _SkillTreeScreenState();
}

class _SkillTreeScreenState extends State<SkillTreeScreen> {
  Map<String, dynamic>? _skillTreeData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSkillTree();
  }

  Future<void> _loadSkillTree() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final skillTree = await apiService.getSkillTree(subjectId: widget.subjectId);

      setState(() {
        _skillTreeData = skillTree;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _skillTreeData = null;
      });
    }
  }

  Future<void> _generateSkillTree(String subjectId) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.generateSkillTree(subjectId);
      await _loadSkillTree();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã tạo Skill Tree thành công! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });

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

  Future<void> _unlockNode(String nodeId) async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.unlockSkillNode(nodeId);
      await _loadSkillTree();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã unlock node! 🔓'),
            backgroundColor: Colors.blue,
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
    }
  }

  Future<void> _completeNode(String nodeId) async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.completeSkillNode(nodeId);
      await _loadSkillTree();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã hoàn thành node! 🎉'),
            backgroundColor: Colors.green,
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Skill Tree'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSkillTree,
          ),
        ],
      ),
      body: _isLoading
          ? _buildSkeletonLoader()
          : _error != null
              ? AppErrorWidget(
                  message: _error!,
                  onRetry: _loadSkillTree,
                )
              : _skillTreeData == null
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadSkillTree,
                      child: _buildSkillTree(),
                    ),
    );
  }

  Widget _buildSkeletonLoader() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SkeletonCard(height: 100),
          const SizedBox(height: 24),
          SkeletonCard(height: 300),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getUserProfileForSubject(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final userData = snapshot.data ?? {};
        final hasPlacementTest = userData['placementTestLevel'] != null ||
            userData['placementTestScore'] != null;
        final placementTestLevel = userData['placementTestLevel'] as String?;

        return EmptyStateWidget(
          icon: Icons.account_tree,
          title: 'Chưa có Skill Tree',
          message: hasPlacementTest
              ? 'Bạn đã hoàn thành placement test (${placementTestLevel ?? 'N/A'}). Hãy chọn môn học để tạo Skill Tree.'
              : 'Hãy hoàn thành placement test để tạo Skill Tree',
          action: hasPlacementTest
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => context.go('/subjects'),
                      icon: const Icon(Icons.school),
                      label: const Text('Chọn môn học'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => context.go('/placement-test'),
                      child: const Text('Làm lại Placement Test'),
                    ),
                  ],
                )
              : ElevatedButton(
                  onPressed: () => context.go('/placement-test'),
                  child: const Text('Bắt đầu Placement Test'),
                ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getUserProfileForSubject() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      return await apiService.getUserProfile();
    } catch (e) {
      return {};
    }
  }

  Widget _buildSkillTree() {
    final nodes = _skillTreeData!['nodes'] as List<dynamic>? ?? [];
    final subject = _skillTreeData!['subject'] as Map<String, dynamic>?;
    final metadata = _skillTreeData!['metadata'] as Map<String, dynamic>?;
    final completionPercentage =
        metadata?['completionPercentage'] as int? ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Skill Tree Header
          _buildHeader(subject, completionPercentage),
          const SizedBox(height: 24),

          // Skill Tree Visualization
          _buildTreeVisualization(nodes),
        ],
      ),
    );
  }

  Widget _buildHeader(
      Map<String, dynamic>? subject, int completionPercentage) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_tree, size: 32, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject?['name'] ?? 'Skill Tree',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_skillTreeData!['completedNodes']}/${_skillTreeData!['totalNodes']} nodes completed',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tiến độ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '$completionPercentage%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: completionPercentage / 100,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  minHeight: 8,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  Icons.star,
                  'XP',
                  '${_skillTreeData!['totalXP'] ?? 0}',
                  Colors.orange,
                ),
                _buildStatItem(
                  Icons.lock_open,
                  'Unlocked',
                  '${_skillTreeData!['unlockedNodes'] ?? 0}',
                  Colors.green,
                ),
                _buildStatItem(
                  Icons.check_circle,
                  'Completed',
                  '${_skillTreeData!['completedNodes'] ?? 0}',
                  Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
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

  Widget _buildTreeVisualization(List<dynamic> nodes) {
    // Convert to Map for easier lookup
    final nodeMap = <String, Map<String, dynamic>>{};
    for (final node in nodes) {
      final nodeData = Map<String, dynamic>.from(node as Map);
      final nodeId = nodeData['id'] as String;
      nodeMap[nodeId] = nodeData;
    }

    // Group nodes by tier for layout
    final nodesByTier = <int, List<Map<String, dynamic>>>{};
    for (final node in nodes) {
      final nodeMap = Map<String, dynamic>.from(node as Map);
      final position = nodeMap['position'] as Map<String, dynamic>?;
      final tier = position?['tier'] as int? ?? 0;

      if (!nodesByTier.containsKey(tier)) {
        nodesByTier[tier] = [];
      }
      nodesByTier[tier]!.add(nodeMap);
    }

    final sortedTiers = nodesByTier.keys.toList()..sort();
    final maxTier = sortedTiers.isNotEmpty ? sortedTiers.last : 0;

    // Calculate tree dimensions
    final nodeSize = 80.0;
    final nodeSpacing = 120.0;
    final tierSpacing = 150.0;
    final padding = 40.0;

    // Calculate total width and height
    final maxNodesPerTier = nodesByTier.values
        .map((list) => list.length)
        .reduce((a, b) => a > b ? a : b);
    final totalWidth = (maxNodesPerTier * nodeSpacing) + (padding * 2);
    final totalHeight = ((maxTier + 1) * tierSpacing) + (padding * 2);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Container(
          width: totalWidth,
          height: totalHeight,
          padding: EdgeInsets.all(padding),
          child: Stack(
            children: [
              // Draw connections first (behind nodes)
              CustomPaint(
                size: Size(totalWidth, totalHeight),
                painter: SkillTreeConnectionsPainter(
                  nodes: nodeMap,
                  nodeSize: nodeSize,
                  nodeSpacing: nodeSpacing,
                  tierSpacing: tierSpacing,
                  padding: padding,
                ),
              ),
              // Draw nodes on top
              ...sortedTiers.map((tier) {
                final tierNodes = nodesByTier[tier]!;
                final tierY = (tier * tierSpacing) + padding;
                final tierWidth = tierNodes.length * nodeSpacing;
                final startX = (totalWidth - tierWidth) / 2;

                return Positioned(
                  left: startX,
                  top: tierY - (nodeSize / 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: tierNodes.asMap().entries.map((entry) {
                      final index = entry.key;
                      final node = entry.value;
                      return Padding(
                        padding: EdgeInsets.only(
                          left: index > 0 ? nodeSpacing : 0,
                        ),
                        child: _buildSkillNode(node),
                      );
                    }).toList(),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkillNode(Map<String, dynamic> node) {
    final title = node['title'] as String? ?? 'Node';
    final type = node['type'] as String? ?? 'skill';
    final visual = node['visual'] as Map<String, dynamic>?;
    final color = _getNodeColor(visual?['color'] as String?);
    final icon = visual?['icon'] as String? ?? 'star';
    final isBoss = type == 'boss';

    // Get user progress (if available in node data)
    final progress = node['userProgress'] as List<dynamic>?;
    final userProgress = progress?.isNotEmpty == true
        ? Map<String, dynamic>.from(progress![0] as Map)
        : null;
    final status = userProgress?['status'] as String? ?? 'locked';
    final progressValue = userProgress?['progress'] as int? ?? 0;

    final isLocked = status == 'locked';
    final isUnlocked = status == 'unlocked' || status == 'in_progress';
    final isCompleted = status == 'completed';

    return GestureDetector(
      onTap: () {
        if (isLocked) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Node này chưa được unlock. Hoàn thành các prerequisites trước!'),
              backgroundColor: Colors.orange,
            ),
          );
        } else if (isCompleted) {
          // Navigate to node detail to review
          final learningNodeId = node['learningNodeId'] as String?;
          if (learningNodeId != null) {
            context.push('/nodes/$learningNodeId');
          }
        } else {
          // Navigate to node detail to learn
          final learningNodeId = node['learningNodeId'] as String?;
          if (learningNodeId != null) {
            context.push('/nodes/$learningNodeId');
          }
        }
      },
      child: Container(
        width: isBoss ? 100 : 80,
        height: isBoss ? 100 : 80,
        decoration: BoxDecoration(
          color: isLocked
              ? Colors.grey.shade300
              : isCompleted
                  ? color.withOpacity(0.3)
                  : color.withOpacity(0.2),
          border: Border.all(
            color: isLocked
                ? Colors.grey.shade400
                : isCompleted
                    ? Colors.green
                    : color,
            width: isBoss ? 3 : 2,
          ),
          borderRadius: BorderRadius.circular(isBoss ? 20 : 16),
          boxShadow: isCompleted
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : isUnlocked
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIconData(icon),
              size: isBoss ? 32 : 24,
              color: isLocked ? Colors.grey.shade600 : color,
            ),
            const SizedBox(height: 4),
            Text(
              title.length > 10 ? '${title.substring(0, 10)}...' : title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isBoss ? 12 : 10,
                fontWeight: FontWeight.bold,
                color: isLocked ? Colors.grey.shade600 : Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (isUnlocked && !isCompleted) ...[
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: progressValue / 100,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 2,
              ),
            ],
            if (isCompleted)
              const Icon(Icons.check_circle, color: Colors.green, size: 16),
            if (isLocked)
              const Icon(Icons.lock, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }

  Color _getNodeColor(String? colorStr) {
    if (colorStr == null) return Colors.blue;
    switch (colorStr.toLowerCase()) {
      case '#ff6b6b':
      case 'red':
        return Colors.red;
      case '#ffd93d':
      case 'yellow':
        return Colors.amber;
      case '#4ecdc4':
      case 'teal':
        return Colors.teal;
      case '#45b7d1':
      case 'blue':
        return Colors.blue;
      case '#96ceb4':
      case 'green':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

      IconData _getIconData(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'star':
        return Icons.star;
      case 'boss':
        return Icons.military_tech;
      case 'reward':
        return Icons.card_giftcard;
      case 'skill':
        return Icons.school;
      default:
        return Icons.circle;
    }
  }
}

/// Custom painter to draw connections between skill tree nodes
class SkillTreeConnectionsPainter extends CustomPainter {
  final Map<String, Map<String, dynamic>> nodes;
  final double nodeSize;
  final double nodeSpacing;
  final double tierSpacing;
  final double padding;

  SkillTreeConnectionsPainter({
    required this.nodes,
    required this.nodeSize,
    required this.nodeSpacing,
    required this.tierSpacing,
    required this.padding,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate max nodes per tier for centering
    final nodesByTier = <int, List<Map<String, dynamic>>>{};
    for (final node in nodes.values) {
      final position = node['position'] as Map<String, dynamic>?;
      final tier = position?['tier'] as int? ?? 0;
      if (!nodesByTier.containsKey(tier)) {
        nodesByTier[tier] = [];
      }
      nodesByTier[tier]!.add(node);
    }

    // Draw connections from parent to children
    for (final node in nodes.values) {
      final nodeId = node['id'] as String;
      final children = node['children'] as List<dynamic>? ?? [];
      final position = node['position'] as Map<String, dynamic>?;
      final tier = position?['tier'] as int? ?? 0;

      // Get user progress status
      final progress = node['userProgress'] as List<dynamic>?;
      final userProgress = progress?.isNotEmpty == true
          ? Map<String, dynamic>.from(progress![0] as Map)
          : null;
      final status = userProgress?['status'] as String? ?? 'locked';
      final isUnlocked = status != 'locked';

      // Calculate parent position
      final tierNodes = nodesByTier[tier]!;
      final parentIndex = tierNodes.indexWhere((n) => n['id'] == nodeId);
      final tierWidth = tierNodes.length * nodeSpacing;
      final startX = (size.width - tierWidth) / 2;
      final parentX = startX + (parentIndex * nodeSpacing) + (nodeSize / 2);
      final parentY = (tier * tierSpacing) + padding + (nodeSize / 2);

      // Draw lines to children
      for (final childId in children) {
        final childNode = nodes[childId];
        if (childNode == null) continue;

        final childPosition = childNode['position'] as Map<String, dynamic>?;
        final childTier = childPosition?['tier'] as int? ?? 0;
        final childTierNodes = nodesByTier[childTier]!;
        final childIndex = childTierNodes.indexWhere((n) => n['id'] == childId);
        if (childIndex == -1) continue;

        final childTierWidth = childTierNodes.length * nodeSpacing;
        final childStartX = (size.width - childTierWidth) / 2;
        final childX = childStartX + (childIndex * nodeSpacing) + (nodeSize / 2);
        final childY = (childTier * tierSpacing) + padding + (nodeSize / 2);

        // Get child status
        final childProgress = childNode['userProgress'] as List<dynamic>?;
        final childUserProgress = childProgress?.isNotEmpty == true
            ? Map<String, dynamic>.from(childProgress![0] as Map)
            : null;
        final childStatus = childUserProgress?['status'] as String? ?? 'locked';
        final childUnlocked = childStatus != 'locked';

        // Determine line color based on unlock status
        final linePaint = Paint()
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke;

        if (isUnlocked && childUnlocked) {
          // Both unlocked - bright color
          linePaint.color = Colors.blue.shade400;
        } else if (isUnlocked || childUnlocked) {
          // One unlocked - dim color
          linePaint.color = Colors.grey.shade400.withOpacity(0.5);
        } else {
          // Both locked - very dim
          linePaint.color = Colors.grey.shade300.withOpacity(0.3);
        }

        // Draw curved line (bezier curve for better visual)
        final path = Path();
        path.moveTo(parentX, parentY);
        
        // Control points for smooth curve
        final controlPoint1 = Offset(parentX, parentY + (tierSpacing / 3));
        final controlPoint2 = Offset(childX, childY - (tierSpacing / 3));
        
        path.cubicTo(
          controlPoint1.dx,
          controlPoint1.dy,
          controlPoint2.dx,
          controlPoint2.dy,
          childX,
          childY,
        );

        canvas.drawPath(path, linePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

