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
  String? _generatingMessage;
  bool _hasNextUnlockable = false;
  bool _isUnlocking = false;
  String? _resolvedSubjectId; // Resolved subjectId from skill tree data

  @override
  void initState() {
    super.initState();
    _loadSkillTree();
  }

  Future<void> _checkNextUnlockable([String? subjectId]) async {
    print('🔍 [Frontend] _checkNextUnlockable() called');

    // Use provided subjectId, or try to resolve from widget or skill tree data
    final effectiveSubjectId =
        subjectId ?? widget.subjectId ?? _resolvedSubjectId;

    if (effectiveSubjectId == null) {
      print('⚠️  [Frontend] Cannot check next unlockable: subjectId is null');
      print(
          '⚠️  [Frontend] widget.subjectId=${widget.subjectId}, _resolvedSubjectId=$_resolvedSubjectId');
      if (mounted) {
        setState(() {
          _hasNextUnlockable = false;
        });
      }
      return;
    }

    print(
        '🔍 [Frontend] Checking next unlockable nodes for subjectId: $effectiveSubjectId');

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      print('🔍 [Frontend] Calling API getNextUnlockableNodes...');
      final nextUnlockable =
          await apiService.getNextUnlockableNodes(effectiveSubjectId);
      print('🔍 [Frontend] API response received: $nextUnlockable');

      final hasNext = nextUnlockable['hasNext'] as bool? ?? false;
      final nodes = nextUnlockable['nodes'] as List? ?? [];
      print(
          '🔍 [Frontend] Next unlockable check result: hasNext=$hasNext, nodes count=${nodes.length}');
      if (nodes.isNotEmpty) {
        print(
            '🔍 [Frontend] Unlockable nodes: ${nodes.map((n) => '${n['title']} (order: ${n['order']})').join(', ')}');
      } else {
        print('⚠️  [Frontend] No unlockable nodes found');
      }

      if (mounted) {
        setState(() {
          _hasNextUnlockable = hasNext;
        });
        print('✅ [Frontend] Updated _hasNextUnlockable to: $hasNext');
        print('✅ [Frontend] Button should ${hasNext ? "SHOW" : "HIDE"}');
      } else {
        print('⚠️  [Frontend] Widget not mounted, cannot update state');
      }
    } catch (e, stackTrace) {
      print('❌ [Frontend] Error checking next unlockable nodes: $e');
      print('Stack trace: $stackTrace');
      // Ignore error, just don't show button
      if (mounted) {
        setState(() {
          _hasNextUnlockable = false;
        });
        print('⚠️  [Frontend] Set _hasNextUnlockable to false due to error');
      }
    }
  }

  Future<void> _loadSkillTree() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _generatingMessage = null;
      _hasNextUnlockable = false;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);

      // First, try to get existing skill tree
      final skillTree =
          await apiService.getSkillTree(subjectId: widget.subjectId);

      // Check if there's a generating message (from generateSkillTree response)
      final generatingMessage = skillTree?['generatingMessage'] as String?;
      final isNewSubject = skillTree?['isNewSubject'] as bool? ?? false;

      // If skill tree is null and we have subjectId, it means we need to generate
      // Show message immediately while generating
      if (skillTree == null && widget.subjectId != null) {
        setState(() {
          _generatingMessage =
              'Bạn đợi tí, môn học này chưa có trong hệ thống, bạn chờ chúng mình tạo skill tree trong giây lát nhé';
        });

        // Generate skill tree
        try {
          final generatedTree =
              await apiService.generateSkillTree(widget.subjectId!);

          // ✅ Resolve subjectId from generated tree
          String? resolvedSubjectId = widget.subjectId;
          final subject = generatedTree['subject'] as Map<String, dynamic>?;
          if (resolvedSubjectId == null && subject != null) {
            resolvedSubjectId = subject['id'] as String?;
            print(
                '🔍 [Frontend] Resolved subjectId from generated tree: $resolvedSubjectId');
          }

          setState(() {
            _skillTreeData = generatedTree;
            _isLoading = false;
            _error = null;
            _resolvedSubjectId = resolvedSubjectId;
            // Keep message if it's a new subject
            if (generatedTree['isNewSubject'] == true) {
              _generatingMessage =
                  generatedTree['generatingMessage'] as String?;
            } else {
              _generatingMessage = null;
            }
          });

          // Check for next unlockable nodes after generation
          if (resolvedSubjectId != null) {
            print(
                '🔍 [Frontend] Generated skill tree, checking next unlockable nodes...');
            _checkNextUnlockable(resolvedSubjectId);
          }

          // Show snackbar after generation completes
          if (mounted && isNewSubject && generatingMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Đã tạo Skill Tree thành công! 🎉'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } catch (e) {
          setState(() {
            _error = 'Không thể tạo Skill Tree: ${e.toString()}';
            _isLoading = false;
            _skillTreeData = null;
            _generatingMessage = null;
          });
        }
      } else {
        // Skill tree exists or no subjectId
        // ✅ Resolve subjectId from skill tree data if not provided
        String? resolvedSubjectId = widget.subjectId;
        if (resolvedSubjectId == null && skillTree != null) {
          final subject = skillTree['subject'] as Map<String, dynamic>?;
          resolvedSubjectId = subject?['id'] as String?;
          print(
              '🔍 [Frontend] Resolved subjectId from skill tree data: $resolvedSubjectId');
        }

      setState(() {
        _skillTreeData = skillTree;
        _isLoading = false;
        _error = null;
          _generatingMessage = generatingMessage;
          _resolvedSubjectId = resolvedSubjectId;
        });

        // Check for next unlockable nodes after setting skill tree data
        if (skillTree != null && resolvedSubjectId != null) {
          print(
              '🔍 [Frontend] Skill tree loaded, checking next unlockable nodes...');
          print(
              '🔍 [Frontend] Skill tree data: ${skillTree['completedNodes']}/${skillTree['totalNodes']} completed');
          print('🔍 [Frontend] Using resolved subjectId: $resolvedSubjectId');
          _checkNextUnlockable(resolvedSubjectId);
        } else {
          print(
              '⚠️  [Frontend] Cannot check next unlockable: skillTree=${skillTree != null}, resolvedSubjectId=$resolvedSubjectId');
        }

        // Show message if it's a new subject being generated
        if (isNewSubject && generatingMessage != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(generatingMessage),
              duration: const Duration(seconds: 5),
              backgroundColor: Colors.blue,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _skillTreeData = null;
        _generatingMessage = null;
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
          tooltip: 'Quay lại',
        ),
        title: const Text('Skill Tree'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSkillTree,
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
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

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          if (_generatingMessage != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _generatingMessage!,
                          style: TextStyle(
                            color: Colors.blue.shade900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ] else ...[
            const Text(
              'Đang tải Skill Tree...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
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

  Future<void> _unlockNextNode() async {
    final effectiveSubjectId = widget.subjectId ?? _resolvedSubjectId;
    if (_isUnlocking || effectiveSubjectId == null) {
      print(
          '⚠️  [Frontend] Cannot unlock next node: _isUnlocking=$_isUnlocking, effectiveSubjectId=$effectiveSubjectId');
      return;
    }

    setState(() {
      _isUnlocking = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      print(
          '🔍 [Frontend] Unlocking next node for subjectId: $effectiveSubjectId');
      final result = await apiService.unlockNextSkillNode(effectiveSubjectId);

      final message = result['message'] as String? ?? 'Đã mở khóa node mới! 🎉';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // Reload skill tree to show updated state
      await _loadSkillTree();
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
          _isUnlocking = false;
        });
      }
    }
  }

  Widget _buildSkillTree() {
    final nodes = _skillTreeData!['nodes'] as List<dynamic>? ?? [];
    final subject = _skillTreeData!['subject'] as Map<String, dynamic>?;
    final metadata = _skillTreeData!['metadata'] as Map<String, dynamic>?;
    final completionPercentage = metadata?['completionPercentage'] as int? ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Skill Tree Header
          _buildHeader(subject, completionPercentage),
          const SizedBox(height: 24),

          // Unlock Next Node Button (if available)
          if (_hasNextUnlockable) ...[
            Card(
              color: Colors.amber.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lock_open, color: Colors.amber.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Bạn đã hoàn thành các node!',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Nhấn vào nút bên dưới để mở khóa node mới',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isUnlocking ? null : _unlockNextNode,
                        icon: _isUnlocking
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Icon(Icons.lock_open),
                        label: Text(_isUnlocking
                            ? 'Đang mở khóa...'
                            : 'Mở khóa node mới'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Skill Tree Visualization
          _buildTreeVisualization(nodes),
        ],
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic>? subject, int completionPercentage) {
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

  Widget _buildStatItem(
      IconData icon, String label, String value, Color color) {
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

    // ✅ Sort nodes by order to create a path/roadmap
    final sortedNodes = List<Map<String, dynamic>>.from(
        nodes.map((n) => Map<String, dynamic>.from(n as Map)));
    sortedNodes.sort((a, b) {
      final orderA = a['order'] as int? ?? 0;
      final orderB = b['order'] as int? ?? 0;
      return orderA.compareTo(orderB);
    });

    // Calculate path dimensions
    final nodeSize = 70.0;
    final nodeSpacing = 100.0;
    final pathPadding = 60.0;
    final pathCurveHeight = 80.0; // Height for path curves

    // Calculate total dimensions for a winding path
    final totalNodes = sortedNodes.length;
    final segmentsPerRow = 3; // 3 nodes per row segment
    final rows = (totalNodes / segmentsPerRow).ceil();
    final totalWidth = (segmentsPerRow * nodeSpacing) + (pathPadding * 2);
    final totalHeight =
        (rows * (nodeSpacing + pathCurveHeight)) + (pathPadding * 2);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Container(
          width: totalWidth,
          height: totalHeight,
          decoration: BoxDecoration(
            // ✅ Add landscape background
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.lightBlue.shade50,
                Colors.green.shade50,
                Colors.green.shade100,
              ],
            ),
          ),
          child: Stack(
            children: [
              // ✅ Draw path/road first (behind nodes)
              CustomPaint(
                size: Size(totalWidth, totalHeight),
                painter: SkillTreePathPainter(
                  nodes: sortedNodes,
                  nodeSize: nodeSize,
                  nodeSpacing: nodeSpacing,
                  pathPadding: pathPadding,
                  pathCurveHeight: pathCurveHeight,
                  segmentsPerRow: segmentsPerRow,
                ),
              ),
              // ✅ Draw nodes along the path
              ...sortedNodes.asMap().entries.map((entry) {
                      final index = entry.key;
                      final node = entry.value;

                // Calculate position along the winding path
                final row = index ~/ segmentsPerRow;
                final col = index % segmentsPerRow;
                final isEvenRow = row % 2 == 0;

                // Alternate direction for each row (zigzag pattern)
                final x = isEvenRow
                    ? pathPadding + (col * nodeSpacing)
                    : pathPadding + ((segmentsPerRow - 1 - col) * nodeSpacing);
                final y = pathPadding +
                    (row * (nodeSpacing + pathCurveHeight)) +
                    (pathCurveHeight / 2);

                return Positioned(
                  left: x - (nodeSize / 2),
                  top: y - (nodeSize / 2),
                  child: _buildPathNode(node, index + 1),
                      );
                    }).toList(),
            ],
          ),
        ),
                  ),
                );
  }

  Widget _buildPathNode(Map<String, dynamic> node, int nodeNumber) {
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
              content: Text(
                  'Node này chưa được unlock. Hoàn thành các prerequisites trước!'),
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
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ✅ Node number badge
          Positioned(
            top: -8,
            right: -8,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isLocked ? Colors.grey.shade400 : Colors.blue.shade600,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '$nodeNumber',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          // Node container
          Container(
            width: isBoss ? 90 : 70,
            height: isBoss ? 90 : 70,
            decoration: BoxDecoration(
              // ✅ Chỉ dùng gradient cho unlocked/completed, color cho locked
              color: isLocked ? Colors.grey.shade300 : null,
              // ✅ Gradient cho unlocked nodes để sáng và nổi bật
              gradient: isLocked
                  ? null
                  : isCompleted
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.green.shade400,
                            Colors.green.shade600,
                          ],
                        )
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            color.withOpacity(0.9), // Rất sáng ở góc trên trái
                            color.withOpacity(0.6), // Đậm hơn ở góc dưới phải
                            color.withOpacity(0.7), // Trung bình
                          ],
                        ),
              border: Border.all(
                color: isLocked
                    ? Colors.grey.shade400
                    : isCompleted
                        ? Colors.green.shade700
                        : Colors.white, // Unlocked: border màu trắng sáng
                width: isBoss
                    ? 3
                    : (isUnlocked ? 3 : 2), // Unlocked: border dày hơn
              ),
              borderRadius: BorderRadius.circular(isBoss ? 20 : 16),
              boxShadow: isCompleted
                  ? [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.8),
                        blurRadius: 15,
                        spreadRadius: 4,
                      ),
                    ]
                  : isUnlocked
                      ? [
                          // ✅ Unlocked nodes có shadow sáng và nổi bật
                          BoxShadow(
                            color: color.withOpacity(0.7),
                            blurRadius: 10,
                            spreadRadius: 3,
                          ),
                          BoxShadow(
                            color: Colors.white.withOpacity(0.5),
                            blurRadius: 6,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ✅ Icon với background sáng cho unlocked nodes
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: isUnlocked && !isCompleted
                      ? BoxDecoration(
                          color: Colors.white.withOpacity(0.4),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.5),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        )
                      : null,
                  child: Icon(
                    _getIconData(icon),
                    size: isBoss ? 28 : 22,
                    color: isLocked
                        ? Colors.grey.shade600
                        : isCompleted
                            ? Colors.white
                            : Colors
                                .white, // Unlocked: icon màu trắng để nổi bật
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title.length > 8 ? '${title.substring(0, 8)}...' : title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isBoss ? 11 : 9,
                    fontWeight: isUnlocked ? FontWeight.bold : FontWeight.w600,
                    color: isLocked
                        ? Colors.grey.shade600
                        : isCompleted
                            ? Colors.white
                            : Colors
                                .white, // Unlocked: text màu trắng để nổi bật
                    shadows: isUnlocked || isCompleted
                        ? [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 3,
                              offset: const Offset(1, 1),
                            ),
                          ]
                        : null,
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
                  const Icon(Icons.check_circle, color: Colors.white, size: 14),
                if (isLocked)
                  const Icon(Icons.lock, color: Colors.grey, size: 14),
              ],
            ),
          ),
        ],
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
              content: Text(
                  'Node này chưa được unlock. Hoàn thành các prerequisites trước!'),
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
          // ✅ Chỉ dùng gradient cho unlocked/completed, color cho locked
          color: isLocked ? Colors.grey.shade300 : null,
          // ✅ Gradient cho unlocked nodes để sáng và nổi bật
          gradient: isLocked
              ? null
              : isCompleted
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.green.shade400,
                        Colors.green.shade600,
                      ],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withOpacity(0.9), // Rất sáng ở góc trên trái
                        color.withOpacity(0.6), // Đậm hơn ở góc dưới phải
                        color.withOpacity(0.7), // Trung bình
                      ],
                    ),
          border: Border.all(
            color: isLocked
                ? Colors.grey.shade400
                : isCompleted
                    ? Colors.green.shade700
                    : Colors.white, // Unlocked: border màu trắng sáng
            width:
                isBoss ? 3 : (isUnlocked ? 3 : 2), // Unlocked: border dày hơn
          ),
          borderRadius: BorderRadius.circular(isBoss ? 20 : 16),
          boxShadow: isCompleted
              ? [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.8),
                    blurRadius: 15,
                    spreadRadius: 4,
                  ),
                ]
              : isUnlocked
                  ? [
                      // ✅ Unlocked nodes có shadow sáng và nổi bật
                      BoxShadow(
                        color: color.withOpacity(0.7),
                        blurRadius: 10,
                        spreadRadius: 3,
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.5),
                        blurRadius: 6,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ✅ Icon với background sáng cho unlocked nodes
            Container(
              padding: const EdgeInsets.all(6),
              decoration: isUnlocked && !isCompleted
                  ? BoxDecoration(
                      color: Colors.white.withOpacity(0.4),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    )
                  : null,
              child: Icon(
              _getIconData(icon),
              size: isBoss ? 32 : 24,
                color: isLocked
                    ? Colors.grey.shade600
                    : isCompleted
                        ? Colors.white
                        : Colors.white, // Unlocked: icon màu trắng để nổi bật
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title.length > 10 ? '${title.substring(0, 10)}...' : title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isBoss ? 12 : 10,
                fontWeight: isUnlocked ? FontWeight.bold : FontWeight.w600,
                color: isLocked
                    ? Colors.grey.shade600
                    : isCompleted
                        ? Colors.white
                        : Colors.white, // Unlocked: text màu trắng để nổi bật
                shadows: isUnlocked || isCompleted
                    ? [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 3,
                          offset: const Offset(1, 1),
                        ),
                      ]
                    : null,
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
            if (isLocked) const Icon(Icons.lock, color: Colors.grey, size: 16),
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

/// Custom painter to draw path/road connecting skill tree nodes
class SkillTreePathPainter extends CustomPainter {
  final List<Map<String, dynamic>> nodes;
  final double nodeSize;
  final double nodeSpacing;
  final double pathPadding;
  final double pathCurveHeight;
  final int segmentsPerRow;

  SkillTreePathPainter({
    required this.nodes,
    required this.nodeSize,
    required this.nodeSpacing,
    required this.pathPadding,
    required this.pathCurveHeight,
    required this.segmentsPerRow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (nodes.isEmpty) return;

    // Draw path connecting all nodes in order
    final path = Path();
    final pathPaint = Paint()
      ..color = Colors.brown.shade300
      ..strokeWidth = 24
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Shadow paint for depth
    final shadowPaint = Paint()
      ..color = Colors.brown.shade600.withOpacity(0.3)
      ..strokeWidth = 26
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Calculate positions for all nodes
    final positions = <Offset>[];
    for (int i = 0; i < nodes.length; i++) {
      final row = i ~/ segmentsPerRow;
      final col = i % segmentsPerRow;
      final isEvenRow = row % 2 == 0;

      final x = isEvenRow
          ? pathPadding + (col * nodeSpacing)
          : pathPadding + ((segmentsPerRow - 1 - col) * nodeSpacing);
      final y = pathPadding +
          (row * (nodeSpacing + pathCurveHeight)) +
          (pathCurveHeight / 2);

      positions.add(Offset(x, y));
    }

    // Draw path connecting nodes
    if (positions.length > 1) {
      // Start from first node
      path.moveTo(positions[0].dx, positions[0].dy);

      // Draw path to each subsequent node with curves
      for (int i = 1; i < positions.length; i++) {
        final current = positions[i - 1];
        final next = positions[i];

        // Check if we're moving to a new row
        final currentRow = (i - 1) ~/ segmentsPerRow;
        final nextRow = i ~/ segmentsPerRow;

        if (nextRow > currentRow) {
          // Moving to new row - draw curved path
          final midY = current.dy + (pathCurveHeight / 2);
          final controlPoint1 = Offset(current.dx, midY);
          final controlPoint2 = Offset(next.dx, midY);

          path.cubicTo(
            controlPoint1.dx,
            controlPoint1.dy,
            controlPoint2.dx,
            controlPoint2.dy,
            next.dx,
            next.dy,
          );
        } else {
          // Same row - draw straight line
          path.lineTo(next.dx, next.dy);
        }
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
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter to draw connections between skill tree nodes (kept for backward compatibility)
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
        final childX =
            childStartX + (childIndex * nodeSpacing) + (nodeSize / 2);
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
