import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:edtech_mobile/core/widgets/app_bar_leading_back_home.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/core/services/tutorial_service.dart';
import 'package:edtech_mobile/core/tutorial/tutorial_helper.dart';
import 'package:edtech_mobile/theme/theme.dart';

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
  String _userRole = 'user';

  bool get _isContributor => _userRole == 'contributor' || _userRole == 'admin';

  // Mind map interaction state
  int _currentLevel = 1;
  String? _selectedSubjectNodeId;
  String? _selectedDomainNodeId;

  // Tutorial keys
  final _courseOutlineKey = GlobalKey();
  final _mindMapButtonsKey = GlobalKey();
  final _knowledgeGraphKey = GlobalKey();
  final _domainsListKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadSubjectIntro();
  }

  void _showSubjectIntroTutorial() {
    if (!mounted || _introData == null) return;

    final targets = <TargetFocus>[];

    targets.add(TutorialHelper.buildTarget(
      key: _courseOutlineKey,
      title: 'Tổng quan khóa học',
      description: 'Xem số lượng bài học, topic và domain của môn học.',
      icon: Icons.info_outline,
      stepLabel: 'Bước 1/4',
    ));

    targets.add(TutorialHelper.buildTarget(
      key: _mindMapButtonsKey,
      title: 'Chế độ xem',
      description:
          'Mind map: bản đồ kiến thức, Lộ trình: danh sách bài học, Cá nhân: tạo lộ trình riêng.',
      icon: Icons.view_module,
      stepLabel: 'Bước 2/4',
    ));

    targets.add(TutorialHelper.buildTarget(
      key: _knowledgeGraphKey,
      title: 'Bản đồ kiến thức',
      description:
          'Nhấn vào node để mở rộng: Môn học → Domain → Topic. Khám phá cấu trúc kiến thức!',
      icon: Icons.account_tree,
      stepLabel: 'Bước 3/4',
      align: ContentAlign.top,
    ));

    final domains = _introData?['subject']?['domains'] as List<dynamic>?;
    if (domains != null && domains.isNotEmpty) {
      targets.add(TutorialHelper.buildTarget(
        key: _domainsListKey,
        title: 'Các chương học',
        description: 'Nhấn vào từng chương để xem chi tiết bài học bên trong.',
        icon: Icons.library_books,
        stepLabel: 'Bước 4/4',
        align: ContentAlign.top,
      ));
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      TutorialHelper.showTutorial(
        context: context,
        tutorialId: TutorialService.subjectIntroTutorial,
        targets: targets,
      );
    });
  }

  Future<void> _loadSubjectIntro() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final results = await Future.wait([
        apiService.getSubjectIntro(widget.subjectId),
        apiService.getUserProfile(),
      ]);
      setState(() {
        _introData = results[0];
        final profile = results[1];
        _userRole = profile['role'] as String? ?? 'user';
        _isLoading = false;
      });
      _showSubjectIntroTutorial();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showTopicInfoDialog(Map<String, dynamic> nodeData) {
    final title = nodeData['title'] as String? ?? 'Chủ đề';
    final isCompleted = nodeData['isCompleted'] as bool? ?? false;
    final isUnlocked = nodeData['isUnlocked'] as bool? ?? false;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? Colors.green.shade50
                          : isUnlocked
                              ? Colors.teal.shade50
                              : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isCompleted
                          ? Icons.check_circle
                          : isUnlocked
                              ? Icons.article
                              : Icons.lock_outline,
                      color: isCompleted
                          ? Colors.green
                          : isUnlocked
                              ? Colors.teal
                              : Colors.grey,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isCompleted
                              ? 'Đã hoàn thành'
                              : isUnlocked
                                  ? 'Đã mở khóa'
                                  : 'Chưa mở khóa',
                          style: TextStyle(
                            fontSize: 13,
                            color: isCompleted
                                ? Colors.green
                                : isUnlocked
                                    ? Colors.teal
                                    : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.amber.shade700, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Bản đồ kiến thức chỉ hiển thị tới cấp chủ đề. Hãy vào "Lộ trình cá nhân" để xem chi tiết bài học.',
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.amber.shade800,
                            height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Đã hiểu',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Giới thiệu khóa học',
            style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary)),
        leading: const AppBarLeadingBackAndHome(),
        leadingWidth: 112,
        automaticallyImplyLeading: false,
        actions: const [],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppColors.purpleNeon),
                  const SizedBox(height: 16),
                  Text('Đang tải...',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.errorNeon.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.error_outline_rounded,
                            size: 48, color: AppColors.errorNeon),
                      ),
                      const SizedBox(height: 16),
                      Text('Lỗi: $_error',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 16),
                      GamingButton(
                          text: 'Thử lại',
                          onPressed: _loadSubjectIntro,
                          icon: Icons.refresh_rounded),
                    ],
                  ),
                )
              : _introData == null
                  ? Center(
                      child: Text('Không có dữ liệu',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textSecondary)))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSubjectHeader(),
                          const SizedBox(height: 24),
                          KeyedSubtree(
                            key: _courseOutlineKey,
                            child: _buildCourseOutline(),
                          ),
                          const SizedBox(height: 16),
                          if (!_isContributor) _buildUnlockBanner(),
                          const SizedBox(height: 16),
                          KeyedSubtree(
                            key: _mindMapButtonsKey,
                            child: _buildMindMapButtons(),
                          ),
                          KeyedSubtree(
                            key: _knowledgeGraphKey,
                            child: _buildKnowledgeGraphContent(),
                          ),
                          const SizedBox(height: 24),
                          KeyedSubtree(
                            key: _domainsListKey,
                            child: _buildDomainsList(),
                          ),
                          const SizedBox(height: 24),
                          if (_isContributor) _buildContributorQuickAccess(),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildSubjectHeader() {
    final subject = _introData!['subject'] as Map<String, dynamic>;
    final track = subject['track'] as String;
    final trackColor =
        track == 'explorer' ? AppColors.successNeon : AppColors.primaryLight;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            trackColor.withValues(alpha: 0.15),
            trackColor.withValues(alpha: 0.05)
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: trackColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [trackColor, trackColor.withValues(alpha: 0.8)]),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: trackColor.withValues(alpha: 0.4), blurRadius: 8)
              ],
            ),
            child: Text(
              track.toUpperCase(),
              style: AppTextStyles.labelSmall.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Text(subject['name'] ?? 'Subject',
              style: AppTextStyles.h2.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          Text(
            subject['description'] ?? '',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildContributorQuickAccess() {
    final subjectName = _introData?['subject']?['name'] as String? ?? '';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.contributorBlue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.contributorBlue.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        onTap: () async {
          await context.push(
            '/contributor/mind-map?subjectId=${widget.subjectId}&subjectName=${Uri.encodeComponent(subjectName)}',
          );
          // Reload data when returning from mind map editor
          _loadSubjectIntro();
        },
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.contributorBlue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.account_tree,
                  color: AppColors.contributorBlue, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chỉnh sửa cấu trúc môn học',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.contributorBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Thêm domain, topic, bài học dạng mind map',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.contributorBlue),
          ],
        ),
      ),
    );
  }

  Widget _buildMindMapButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bản đồ kiến thức',
            style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary)),
        const SizedBox(height: 16),
        // Single row with 3 equal compact buttons
        Row(
          children: [
            Expanded(
              child: _CompactMindMapButton(
                title: 'Mind map',
                icon: Icons.account_tree_rounded,
                color: AppColors.primaryLight,
                isSelected: true,
                onTap: () {
                  // Scroll down to show the mind map on this page
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Kéo xuống để xem Mind map'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _CompactMindMapButton(
                title: 'Lộ trình',
                icon: Icons.route_rounded,
                color: AppColors.successNeon,
                isSelected: false,
                onTap: () {
                  // Navigate to all lessons screen (sequential view)
                  context.push('/subjects/${widget.subjectId}/all-lessons');
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _CompactMindMapButton(
                title: _isContributor ? 'Chỉnh sửa' : 'Cá nhân',
                icon: _isContributor
                    ? Icons.edit_note_rounded
                    : Icons.person_rounded,
                color: _isContributor
                    ? AppColors.contributorBlue
                    : AppColors.purpleNeon,
                isSelected: false,
                onTap: () async {
                  if (_isContributor) {
                    // Contributor: navigate to mind map editor
                    final subjectName = _introData?['subject']?['name'] ?? '';
                    await context.push(
                      '/contributor/mind-map?subjectId=${widget.subjectId}&subjectName=${Uri.encodeComponent(subjectName)}',
                    );
                    // Reload data when returning from mind map editor
                    _loadSubjectIntro();
                    return;
                  }
                  // Learner: navigate to learning path choice screen
                  context.push(
                      '/subjects/${widget.subjectId}/learning-path-choice');
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  /// Build centered subject node for level 1
  Widget _buildCenteredSubjectNode(Map<String, dynamic> nodeData) {
    final isCompleted = nodeData['isCompleted'] as bool? ?? false;
    final title = nodeData['title'] as String? ?? '';
    final nodeId = nodeData['id'] as String?;

    final nodeColor =
        isCompleted ? Colors.green.shade700 : Colors.orange.shade600;

    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: GestureDetector(
          onTap: () {
            if (nodeId != null) {
              setState(() {
                _currentLevel = 2;
                _selectedSubjectNodeId = nodeId;
                _selectedDomainNodeId = null;
              });
            }
          },
          child: Container(
            width: 220,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [nodeColor.withValues(alpha: 0.9), nodeColor],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: nodeColor.withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isCompleted ? Icons.check_circle : Icons.school,
                  color: Colors.white,
                  size: 40,
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.touch_app, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Nhấn để mở rộng',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
        return e['from'] == _selectedSubjectNodeId ||
            e['to'] == _selectedSubjectNodeId;
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
        final matches =
            n['level'] == 3 && nodeParentId == _selectedDomainNodeId;
        return matches;
      }).toList();
      visibleNodes.addAll(topicNodes);

      // Add edges between domain and topics
      final domainEdges = allEdges.cast<Map<String, dynamic>>().where((e) {
        return e['from'] == _selectedDomainNodeId ||
            e['to'] == _selectedDomainNodeId;
      }).toList();
      visibleEdges.addAll(domainEdges);

      // Also add edges between subject and domain
      final subjectEdges = allEdges.cast<Map<String, dynamic>>().where((e) {
        return e['from'] == _selectedSubjectNodeId &&
            e['to'] == _selectedDomainNodeId;
      }).toList();
      visibleEdges.addAll(subjectEdges);
    }

    final nodes = visibleNodes;
    final edges = visibleEdges;

    // Khi chỉ có 1 node (subject) - hiển thị căn giữa
    if (_currentLevel == 1 && nodes.length == 1) {
      return _buildCenteredSubjectNode(nodes.first);
    }

    // Tính bounding box của tất cả nodes để căn giữa
    double minX = double.infinity, maxX = double.negativeInfinity;
    double minY = double.infinity, maxY = double.negativeInfinity;

    for (final node in nodes) {
      final pos = node['position'] as Map<String, dynamic>?;
      if (pos != null) {
        final x = (pos['x'] as num?)?.toDouble() ?? 0.0;
        final y = (pos['y'] as num?)?.toDouble() ?? 0.0;
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }

    // Tính kích thước cần thiết và padding
    final graphWidth = (maxX - minX) + 300; // Thêm padding cho nodes
    final graphHeight = (maxY - minY) + 200;
    final containerHeight = graphHeight.clamp(400.0, 800.0);

    return Container(
      height: containerHeight,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Tính offset để căn giữa graph trong container
            final centerX = constraints.maxWidth / 2;
            final centerY = constraints.maxHeight / 2;
            final graphCenterX = (minX + maxX) / 2;
            final graphCenterY = (minY + maxY) / 2;
            final offsetX = centerX - graphCenterX;
            final offsetY = centerY - graphCenterY;

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: SizedBox(
                  width: graphWidth.clamp(constraints.maxWidth, 1500.0),
                  height: graphHeight.clamp(constraints.maxHeight, 1500.0),
                  child: Stack(
                    children: [
                      // Edges (lines) - drawn first with offset
                      CustomPaint(
                        size: Size(graphWidth, graphHeight),
                        painter: KnowledgeGraphPainter(
                          nodes: nodes,
                          edges: edges,
                          offsetX: offsetX,
                          offsetY: offsetY,
                        ),
                      ),
                      // Nodes (interactive) - drawn on top
                      ...nodes.map((node) {
                        final nodeData = node;
                        final position =
                            nodeData['position'] as Map<String, dynamic>?;
                        if (position == null) return const SizedBox.shrink();

                        final x = ((position['x'] as num?)?.toDouble() ?? 0.0) +
                            offsetX;
                        final y = ((position['y'] as num?)?.toDouble() ?? 0.0) +
                            offsetY;
                        final isUnlocked =
                            nodeData['isUnlocked'] as bool? ?? false;
                        final isCompleted =
                            nodeData['isCompleted'] as bool? ?? false;
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
                                // Click vào Topic: chỉ hiện thông tin, không mở learning nodes
                                _showTopicInfoDialog(nodeData);
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
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: level == 1
                                        ? 12
                                        : level == 2
                                            ? 8
                                            : 6,
                                    spreadRadius: level == 1
                                        ? 3
                                        : level == 2
                                            ? 2
                                            : 1,
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  if (level == 1)
                                    const Icon(
                                      Icons.school,
                                      color: Colors.white,
                                      size: 28,
                                    )
                                  else if (level == 2)
                                    const Icon(
                                      Icons.book,
                                      color: Colors.white,
                                      size: 22,
                                    )
                                  else
                                    const Icon(
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
                      }),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCourseOutline() {
    final outline = _introData!['courseOutline'] as Map<String, dynamic>;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x332D363D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tổng quan khóa học',
              style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                  child: _OutlineItem(
                      icon: Icons.book_rounded,
                      label: 'Bài học',
                      value: '${outline['totalLessons'] ?? 0}',
                      color: AppColors.purpleNeon)),
              Expanded(
                  child: _OutlineItem(
                      icon: Icons.topic_rounded,
                      label: 'Topic',
                      value: '${outline['totalTopics'] ?? 0}',
                      color: AppColors.primaryLight)),
              Expanded(
                  child: _OutlineItem(
                      icon: Icons.category_rounded,
                      label: 'Domain',
                      value: '${outline['totalDomains'] ?? 0}',
                      color: AppColors.coinGold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUnlockBanner() {
    return InkWell(
      onTap: () async {
        await context.push('/subjects/${widget.subjectId}/unlock');
        // Reload data when returning
        _loadSubjectIntro();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.purpleNeon.withValues(alpha: 0.12),
              AppColors.primaryLight.withValues(alpha: 0.08)
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: AppColors.purpleNeon.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.purpleNeon.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('💎', style: TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mở khóa bài học',
                    style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Dùng kim cương để mở khóa từng bài, chương hoặc cả môn',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.purpleNeon.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.chevron_right_rounded,
                  color: AppColors.purpleNeon, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDomainsList() {
    // Check if subject has domains
    final domains = _introData?['subject']?['domains'] as List<dynamic>?;
    final hasDomains = domains != null && domains.isNotEmpty;

    if (!hasDomains) {
      return const SizedBox.shrink();
    }

    final colors = [
      [AppColors.purpleNeon, AppColors.primaryLight],
      [AppColors.primaryLight, AppColors.successNeon],
      [AppColors.coinGold, AppColors.orangeNeon],
      [AppColors.primaryLight, AppColors.purpleNeon],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Các chương học',
            style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary)),
        const SizedBox(height: 16),
        ...domains.asMap().entries.map((entry) {
          final index = entry.key;
          final domainData = entry.value as Map<String, dynamic>;
          final domainId = domainData['id'] as String?;
          final name = domainData['name'] as String? ?? 'Chương học';
          final description = domainData['description'] as String?;
          final order = domainData['order'] as int? ?? 0;
          final metadata = domainData['metadata'] as Map<String, dynamic>?;
          final icon = metadata?['icon'] as String? ?? '📚';
          final nodesCount =
              (domainData['nodes'] as List<dynamic>?)?.length ?? 0;
          final colorPair = colors[index % colors.length];

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x332D363D)),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (domainId != null) {
                    context.push('/domains/$domainId');
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Order badge
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: colorPair),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                                color: colorPair[0].withValues(alpha: 0.3),
                                blurRadius: 8)
                          ],
                        ),
                        child: Center(
                          child: Text('${order + 1}',
                              style: AppTextStyles.labelLarge
                                  .copyWith(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Icon
                      Text(icon, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 14),
                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name,
                                style: AppTextStyles.labelLarge
                                    .copyWith(color: AppColors.textPrimary)),
                            if (description != null &&
                                description.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                description,
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: AppColors.textSecondary),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            if (nodesCount > 0) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.book_rounded,
                                      size: 14, color: AppColors.textTertiary),
                                  const SizedBox(width: 4),
                                  Text('$nodesCount bài học',
                                      style: AppTextStyles.caption.copyWith(
                                          color: AppColors.textTertiary)),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.bgTertiary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.chevron_right_rounded,
                            color: AppColors.textSecondary, size: 20),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _OutlineItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _OutlineItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: AppTextStyles.numberMedium
                  .copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(label,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textTertiary)),
        ],
      ),
    );
  }
}

/// Mind map style tile (compact, 3-column layout on intro)
class _CompactMindMapButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _CompactMindMapButton({
    required this.title,
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
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.5)
                : const Color(0x332D363D),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 8)]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTextStyles.caption.copyWith(
                color: isSelected ? color : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
  final double offsetX;
  final double offsetY;

  KnowledgeGraphPainter({
    required this.nodes,
    required this.edges,
    this.offsetX = 0,
    this.offsetY = 0,
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
        final fromX = (fromPos['x'] as num).toDouble() + offsetX;
        final fromY = (fromPos['y'] as num).toDouble() + offsetY;
        final toX = (toPos['x'] as num).toDouble() + offsetX;
        final toY = (toPos['y'] as num).toDouble() + offsetY;

        canvas.drawLine(
          Offset(fromX, fromY),
          Offset(toX, toY),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant KnowledgeGraphPainter oldDelegate) {
    return oldDelegate.offsetX != offsetX || oldDelegate.offsetY != offsetY;
  }
}
