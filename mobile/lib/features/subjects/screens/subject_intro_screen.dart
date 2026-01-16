import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/core/utils/navigation_helper.dart';

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
  
  // Mind map interaction state
  int _currentLevel = 1; // 1 = Subject, 2 = Domains, 3 = Topics
  String? _selectedSubjectNodeId; // Selected subject node
  String? _selectedDomainNodeId; // Selected domain node

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

  Future<void> _handleTopicClick(String topicNodeId, String topicTitle) async {
    if (!mounted) return;

    final apiService = Provider.of<ApiService>(context, listen: false);
    BuildContext? dialogContext;
    Timer? progressTimer;
    StateSetter? setDialogState;
    double dialogProgress = 0.0;
    String dialogStatus = 'Đang khởi tạo...';

    // Show loading dialog with progress
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        dialogContext = ctx;
        return StatefulBuilder(
          builder: (context, setState) {
            setDialogState = setState;
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('Đang tạo bài học cho "$topicTitle"...'),
                  const SizedBox(height: 8),
                  Text(
                    dialogStatus,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${dialogProgress.toInt()}%',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: dialogProgress / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade400),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    try {
      // Start generation and get taskId
      final result = await apiService.generateLearningNodesFromTopic(
        widget.subjectId,
        topicNodeId,
      );

      final alreadyExists = result['alreadyExists'] as bool? ?? false;
      final taskId = result['taskId'] as String?;

      if (alreadyExists) {
        // Already exists, close dialog and navigate
        if (!mounted || dialogContext == null) return;
        NavigationHelper.safePop(dialogContext!);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Đang mở bài học...'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            context.go('/skill-tree?subjectId=${widget.subjectId}');
          }
        });
        return;
      }

      if (taskId == null) {
        throw Exception('Task ID not returned from server');
      }

      // Poll progress if we have a taskId
      progressTimer?.cancel();
      progressTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
        if (!mounted || dialogContext == null) {
          timer.cancel();
          return;
        }

        try {
          final progressData = await apiService.getGenerationProgress(
            widget.subjectId,
            taskId,
          );

          if (progressData['error'] != null) {
            timer.cancel();
            return;
          }

          final progress = (progressData['progress'] as num?)?.toDouble() ?? 0.0;
          final status = progressData['status'] as String? ?? 'generating';
          final currentStep = progressData['currentStep'] as String? ?? 'Đang xử lý...';

          dialogProgress = progress;
          dialogStatus = currentStep;

          // Update dialog state
          setDialogState?.call(() {});

          // If completed or error, stop polling
          if (status == 'completed') {
            timer.cancel();
            if (!mounted || dialogContext == null) return;
            NavigationHelper.safePop(dialogContext!);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Đã tạo bài học thành công!'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );

            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                context.go('/skill-tree?subjectId=${widget.subjectId}');
              }
            });
          } else if (status == 'error') {
            timer.cancel();
            if (!mounted || dialogContext == null) return;
            NavigationHelper.safePop(dialogContext!);

            final errorMsg = progressData['error'] as String? ?? 'Có lỗi xảy ra';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lỗi: $errorMsg'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } catch (e) {
          // Continue polling on error
          print('Error polling progress: $e');
        }
      });
    } catch (e) {
      progressTimer?.cancel();
      if (!mounted || dialogContext == null) return;
      NavigationHelper.safePop(dialogContext!);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

                              // Course outline
                              _buildCourseOutline(),
                              const SizedBox(height: 24),

                              // Mind map buttons
                              _buildMindMapButtons(),

                              // Mind map (knowledge graph)
                              _buildKnowledgeGraphContent(),
                              const SizedBox(height: 24),

                              // Domains list
                              _buildDomainsList(),
                              const SizedBox(height: 24),

                              // Start learning goals conversation button
                              _buildStartLearningGoalsButton(),
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

  Widget _buildMindMapButtons() {
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
        Row(
          children: [
            Expanded(
              child: _MindMapButton(
                title: 'Mind map tổng thể',
                subtitle: 'Xem toàn bộ nội dung môn học',
                icon: Icons.account_tree,
                color: Colors.blue,
                isSelected: true,
                onTap: () {
                  // Đang hiển thị mind map tổng thể
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MindMapButton(
                title: 'Mind map của bạn',
                subtitle: 'Lộ trình cá nhân hóa',
                icon: Icons.person,
                color: Colors.purple,
                isSelected: false,
                onTap: () {
                  // Chuyển đến trang personal mind map
                  context.push('/subjects/${widget.subjectId}/personal-mind-map');
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildKnowledgeGraphContent() {
    final graph = _introData?['knowledgeGraph'] as Map<String, dynamic>?;
    if (graph == null) {
      return const SizedBox.shrink();
    }
    
    final allNodes = graph['nodes'] as List? ?? [];
    final allEdges = graph['edges'] as List? ?? [];

    if (allNodes.isEmpty) {
      return const SizedBox.shrink();
    }

    // Filter nodes based on current level and selection
    final List<Map<String, dynamic>> visibleNodes = [];
    final List<Map<String, dynamic>> visibleEdges = [];

    if (_currentLevel == 1) {
      // Only show subject node (level 1)
      final subjectNode = allNodes.cast<Map<String, dynamic>>().firstWhere(
        (n) => n['level'] == 1,
        orElse: () => <String, dynamic>{},
      );
      if (subjectNode.isNotEmpty) {
        visibleNodes.add(subjectNode);
        _selectedSubjectNodeId = subjectNode['id'] as String?;
      }
    } else if (_currentLevel == 2 && _selectedSubjectNodeId != null) {
      // Show subject node + domains (level 2)
      final subjectNode = allNodes.cast<Map<String, dynamic>>().firstWhere(
        (n) => n['id'] == _selectedSubjectNodeId,
        orElse: () => <String, dynamic>{},
      );
      if (subjectNode.isNotEmpty) {
        visibleNodes.add(subjectNode);
      }

      // Get domains connected to subject
      final domainNodes = allNodes.cast<Map<String, dynamic>>().where((n) {
        return n['level'] == 2 && n['parentId'] == _selectedSubjectNodeId;
      }).toList();
      visibleNodes.addAll(domainNodes);

      // Add edges between subject and domains
      final subjectEdges = allEdges.cast<Map<String, dynamic>>().where((e) {
        return e['from'] == _selectedSubjectNodeId || e['to'] == _selectedSubjectNodeId;
      }).toList();
      visibleEdges.addAll(subjectEdges);
    } else if (_currentLevel == 3 && _selectedDomainNodeId != null) {
      // Ensure _selectedSubjectNodeId is set
      if (_selectedSubjectNodeId == null) {
        final subjectNode = allNodes.cast<Map<String, dynamic>>().firstWhere(
          (n) => n['level'] == 1,
          orElse: () => <String, dynamic>{},
        );
        if (subjectNode.isNotEmpty) {
          _selectedSubjectNodeId = subjectNode['id'] as String?;
        }
      }
      
      // Show subject + domain + topics (level 3) of selected domain
      if (_selectedSubjectNodeId != null) {
        final subjectNode = allNodes.cast<Map<String, dynamic>>().firstWhere(
          (n) => n['id'] == _selectedSubjectNodeId,
          orElse: () => <String, dynamic>{},
        );
        if (subjectNode.isNotEmpty) {
          visibleNodes.add(subjectNode);
        }
      }

      final domainNode = allNodes.cast<Map<String, dynamic>>().firstWhere(
        (n) => n['id'] == _selectedDomainNodeId,
        orElse: () => <String, dynamic>{},
      );
      if (domainNode.isNotEmpty) {
        visibleNodes.add(domainNode);
      }

      // Get topics connected to selected domain
      final topicNodes = allNodes.cast<Map<String, dynamic>>().where((n) {
        final nodeParentId = n['parentId'] as String?;
        final matches = n['level'] == 3 && nodeParentId == _selectedDomainNodeId;
        return matches;
      }).toList();
      visibleNodes.addAll(topicNodes);

      // Add edges between domain and topics
      final domainEdges = allEdges.cast<Map<String, dynamic>>().where((e) {
        return e['from'] == _selectedDomainNodeId || e['to'] == _selectedDomainNodeId;
      }).toList();
      visibleEdges.addAll(domainEdges);
      
      // Also add edges between subject and domain
      final subjectEdges = allEdges.cast<Map<String, dynamic>>().where((e) {
        return e['from'] == _selectedSubjectNodeId && e['to'] == _selectedDomainNodeId;
      }).toList();
      visibleEdges.addAll(subjectEdges);
    }

    final nodes = visibleNodes;
    final edges = visibleEdges;

    return Container(
      height: 600,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: SizedBox(
              width: 1200,
              height: 1200,
              child: Stack(
                children: [
                  // Edges (lines) - drawn first
                  CustomPaint(
                    size: const Size(1200, 1200),
                    painter: KnowledgeGraphPainter(
                  nodes: nodes,
                  edges: edges,
                ),
              ),
              // Nodes (interactive) - drawn on top
              ...nodes.map((node) {
                final nodeData = node as Map<String, dynamic>;
                final position = nodeData['position'] as Map<String, dynamic>?;
                if (position == null) return const SizedBox.shrink();
                
                final x = (position['x'] as num?)?.toDouble() ?? 0.0;
                final y = (position['y'] as num?)?.toDouble() ?? 0.0;
                final isUnlocked = nodeData['isUnlocked'] as bool? ?? false;
                final isCompleted = nodeData['isCompleted'] as bool? ?? false;
                final title = nodeData['title'] as String? ?? '';
                final level = nodeData['level'] as int? ?? 3;

                // Màu sắc và kích thước theo level
                Color nodeColor;
                double nodeWidth;
                double minHeight;
                double maxHeight;
                double fontSize;
                double borderWidth;

                switch (level) {
                  case 1: // Subject - Lớp 1
                    nodeColor = isCompleted
                        ? Colors.green.shade700
                        : Colors.orange.shade600;
                    nodeWidth = 200;
                    minHeight = 90;
                    maxHeight = 140;
                    fontSize = 13;
                    borderWidth = 4;
                    break;
                  case 2: // Domain - Lớp 2
                    nodeColor = isCompleted
                        ? Colors.green.shade600
                        : Colors.blue.shade600;
                    nodeWidth = 180;
                    minHeight = 80;
                    maxHeight = 120;
                    fontSize = 12;
                    borderWidth = 3;
                    break;
                  default: // Topic - Lớp 3
                    nodeColor = isCompleted
                        ? Colors.green.shade500
                        : isUnlocked
                            ? Colors.teal.shade500
                            : Colors.grey.shade400;
                    nodeWidth = 160;
                    minHeight = 70;
                    maxHeight = 110;
                    fontSize = 11;
                    borderWidth = 2;
                    break;
                }

                return Positioned(
                  left: x - (nodeWidth / 2),
                  top: y - (minHeight / 2),
                  child: GestureDetector(
                    onTap: () async {
                      final nodeId = nodeData['id'] as String?;
                      if (nodeId == null) return;

                      if (level == 1) {
                        // Click vào Subject: Expand để hiển thị Domains
                        setState(() {
                          _currentLevel = 2;
                          _selectedSubjectNodeId = nodeId;
                          _selectedDomainNodeId = null;
                        });
                      } else if (level == 2) {
                        // Click vào Domain: Expand để hiển thị Topics
                        setState(() {
                          _currentLevel = 3;
                          _selectedDomainNodeId = nodeId;
                        });
                      } else if (level == 3) {
                        // Click vào Topic: Generate learning nodes
                        _handleTopicClick(nodeId, title);
                      }
                    },
                    child: Container(
                      width: nodeWidth,
                      constraints: BoxConstraints(
                        minHeight: minHeight,
                        maxHeight: maxHeight,
                      ),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: nodeColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white,
                          width: borderWidth,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: level == 1 ? 12 : level == 2 ? 8 : 6,
                            spreadRadius: level == 1 ? 3 : level == 2 ? 2 : 1,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (level == 1)
                            Icon(
                              Icons.school,
                              color: Colors.white,
                              size: 28,
                            )
                          else if (level == 2)
                            Icon(
                              Icons.book,
                              color: Colors.white,
                              size: 22,
                            )
                          else
                            Icon(
                              Icons.article,
                              color: Colors.white,
                              size: 18,
                            ),
                          const SizedBox(height: 6),
                          Flexible(
                            child: Text(
                              title,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: fontSize,
                                height: 1.3,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              softWrap: true,
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
    ),
  ),
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
        NavigationHelper.safePop(context);
      }

      // Navigate to skill tree
      if (mounted) {
        context.go('/skill-tree?subjectId=${widget.subjectId}');
      }
    } catch (e) {
      // Close loading if still open
      if (mounted) {
        NavigationHelper.safePop(context);
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

  Widget _buildDomainsList() {
    // Check if subject has domains
    final domains = _introData?['subject']?['domains'] as List<dynamic>?;
    final hasDomains = domains != null && domains.isNotEmpty;
    
    if (!hasDomains) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Các chương học',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...domains.map((domain) {
          final domainData = domain as Map<String, dynamic>;
          final domainId = domainData['id'] as String?;
          final name = domainData['name'] as String? ?? 'Chương học';
          final description = domainData['description'] as String?;
          final order = domainData['order'] as int? ?? 0;
          final metadata = domainData['metadata'] as Map<String, dynamic>?;
          final icon = metadata?['icon'] as String? ?? '📚';
          final nodesCount = (domainData['nodes'] as List<dynamic>?)?.length ?? 0;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            child: InkWell(
              onTap: () {
                if (domainId != null) {
                  context.push('/domains/$domainId');
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Order badge
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${order + 1}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Icon
                    Text(
                      icon,
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(width: 16),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (description != null && description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              description,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          if (nodesCount > 0) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.book, size: 14, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  '$nodesCount bài học',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.grey.shade400),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildStartLearningGoalsButton() {
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
            onTap: () {
              // Navigate to learning goals chat
              context.push('/subjects/${widget.subjectId}/learning-goals');
            },
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
                        'Tạo ra lộ trình riêng cho bạn',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'AI sẽ giúp bạn xác định mục tiêu học tập',
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
          child: Stack(
            children: [
              Padding(
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
              // Nút X ở góc phải trên
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _skipTutorial,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
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

class _MindMapButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _MindMapButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey.shade600,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
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

      final fromNode = nodes.cast<Map<String, dynamic>>().firstWhere(
        (n) => n['id'] == fromId,
        orElse: () => <String, dynamic>{},
      );
      final toNode = nodes.cast<Map<String, dynamic>>().firstWhere(
        (n) => n['id'] == toId,
        orElse: () => <String, dynamic>{},
      );

      if (fromNode.isNotEmpty && toNode.isNotEmpty) {
        final fromPos = fromNode['position'] as Map<String, dynamic>;
        final toPos = toNode['position'] as Map<String, dynamic>;
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

