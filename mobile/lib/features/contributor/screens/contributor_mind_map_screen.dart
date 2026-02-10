import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/theme/theme.dart';
import 'package:edtech_mobile/features/lessons/editors/image_quiz_editor_screen.dart';
import 'package:edtech_mobile/features/lessons/editors/image_gallery_editor_screen.dart';
import 'package:edtech_mobile/features/lessons/editors/video_editor_screen.dart';
import 'package:edtech_mobile/features/lessons/editors/text_editor_screen.dart';
import 'package:edtech_mobile/features/lessons/screens/lesson_type_history_screen.dart';

/// Mind map editor kiểu Monica cho contributor
/// 5 tầng: Môn học -> Domain -> Topic -> Bài học -> Dạng bài
class ContributorMindMapScreen extends StatefulWidget {
  final String subjectId;
  final String? subjectName;

  const ContributorMindMapScreen({
    super.key,
    required this.subjectId,
    this.subjectName,
  });

  @override
  State<ContributorMindMapScreen> createState() =>
      _ContributorMindMapScreenState();
}

class _ContributorMindMapScreenState extends State<ContributorMindMapScreen>
    with WidgetsBindingObserver {
  bool _isLoading = true;
  bool _isFirstLoad = true;
  String? _error;

  // Data
  Map<String, dynamic>? _subjectData;
  List<dynamic> _domains = [];
  List<dynamic> _allNodes = [];
  // Topics mapped by domainId -> list of topics
  Map<String, List<dynamic>> _topicsByDomain = {};

  // Cache for lesson type contents per node (nodeId -> list of available type keys)
  final Map<String, List<String>> _lessonTypeCache = {};
  final Set<String> _lessonTypeFetching = {}; // track in-flight fetches

  // Expand state: track which nodes are expanded
  final Set<String> _expandedNodes = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Auto-reload when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    // Only show full loading on first load; subsequent loads are silent refresh
    if (_isFirstLoad) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final results = await Future.wait([
        apiService.getSubjectIntro(widget.subjectId),
        apiService.getDomainsBySubject(widget.subjectId),
        apiService.getLearningNodesBySubject(widget.subjectId),
      ]);

      final domains = results[1] as List<dynamic>;

      // Load topics for each domain
      final topicsMap = <String, List<dynamic>>{};
      for (final domain in domains) {
        final d = domain as Map<String, dynamic>;
        final domainId = d['id'] as String;
        try {
          final topics = await apiService.getTopicsByDomain(domainId);
          topicsMap[domainId] = topics;
        } catch (_) {
          topicsMap[domainId] = [];
        }
      }

      if (mounted) {
        setState(() {
          _subjectData = (results[0] as Map<String, dynamic>)['subject'];
          _domains = domains;
          _allNodes = results[2] as List<dynamic>;
          _topicsByDomain = topicsMap;
          _isLoading = false;
          _isFirstLoad = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _isFirstLoad ? e.toString() : _error;
          _isLoading = false;
          _isFirstLoad = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Prefer loaded data over static widget param (for name updates after edit)
    final subjectName =
        _subjectData?['name'] ?? widget.subjectName ?? 'Môn học';
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          subjectName,
          style: const TextStyle(
              color: Color(0xFF2D3748),
              fontWeight: FontWeight.bold,
              fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D3748)),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF2D3748)),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildMindMap(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text('Lỗi: $_error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadData, child: const Text('Thử lại')),
        ],
      ),
    );
  }

  Widget _buildMindMap() {
    return InteractiveViewer(
      boundaryMargin: const EdgeInsets.all(double.infinity),
      minScale: 0.5,
      maxScale: 3.0,
      constrained: false,
      child: RepaintBoundary(
        child: Padding(
          padding: const EdgeInsets.all(100),
          child: _buildSubjectTree(),
        ),
      ),
    );
  }

  /// Root: Môn học
  Widget _buildSubjectTree() {
    final name = _subjectData?['name'] ?? widget.subjectName ?? 'Môn học';
    final subjectKey = 'subject-${widget.subjectId}';
    final isExpanded = _expandedNodes.contains(subjectKey);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Subject node
        _buildNode(
          label: name,
          level: 0,
          isExpanded: isExpanded,
          onTap: () => _toggleExpand(subjectKey),
          onAdd: () => _addDomain(),
          onEdit: () => _showNodeActions(
            type: 'subject',
            entityId: widget.subjectId,
            currentName: name,
          ),
          childCount: _domains.length,
        ),
        // Children: Domains
        if (isExpanded && _domains.isNotEmpty) _buildHorizontalConnector(),
        if (isExpanded)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ..._domains.asMap().entries.map((entry) {
                final index = entry.key;
                final domain = entry.value as Map<String, dynamic>;
                return Padding(
                  padding: EdgeInsets.only(
                    top: index == 0 ? 0 : 8,
                    bottom: index == _domains.length - 1 ? 0 : 8,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildVerticalLine(index, _domains.length),
                      _buildDomainBranch(domain),
                    ],
                  ),
                );
              }),
              // Add domain button at end
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const SizedBox(width: 20),
                    _buildAddButton('Thêm Domain', _addDomain),
                  ],
                ),
              ),
              // Show orphan nodes (nodes without topicId) so contributors can manage them
              ..._buildOrphanNodesSection(),
            ],
          ),
      ],
    );
  }

  /// Build orphan nodes section - nodes that belong to the subject but have no topicId
  List<Widget> _buildOrphanNodesSection() {
    final orphanNodes = _allNodes.where((n) {
      final node = n as Map<String, dynamic>;
      final topicId = node['topicId'];
      return topicId == null || topicId.toString().isEmpty;
    }).toList();

    if (orphanNodes.isEmpty) return [];

    return [
      const SizedBox(height: 16),
      // Use ConstrainedBox to prevent unconstrained layout inside InteractiveViewer
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Container(
          margin: const EdgeInsets.only(left: 20),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade300, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Bài học chưa phân loại (${orphanNodes.length})',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Các bài này không thuộc Topic nào, không hiển thị cho người học.',
                style: TextStyle(fontSize: 11, color: Colors.orange.shade700),
              ),
              const SizedBox(height: 8),
              ...orphanNodes.map((n) {
                final node = n as Map<String, dynamic>;
                final nodeId = node['id'] as String;
                final title = node['title'] as String? ?? 'Bài không tên';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.article_outlined, color: Colors.orange.shade600, size: 16),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _showNodeActions(
                          type: 'lesson',
                          entityId: nodeId,
                          currentName: title,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(Icons.more_vert, color: Colors.red.shade400, size: 16),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    ];
  }

  /// Domain branch
  Widget _buildDomainBranch(Map<String, dynamic> domain) {
    final domainId = domain['id'] as String;
    final name = domain['name'] as String? ?? 'Domain';
    final topics = _topicsByDomain[domainId] ?? [];

    final domainKey = 'domain-$domainId';
    final isExpanded = _expandedNodes.contains(domainKey);

    // Only show topics (new structure)
    final children = <Map<String, dynamic>>[];
    for (final topic in topics) {
      final t = topic as Map<String, dynamic>;
      children.add({
        'type': 'topic',
        'id': t['id'],
        'name': t['name'] ?? 'Topic',
        'domainId': domainId,
      });
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildNode(
          label: name,
          level: 1,
          isExpanded: isExpanded,
          onTap: () => _toggleExpand(domainKey),
          onAdd: () => _addTopic(domainId, name),
          onEdit: () => _showNodeActions(
            type: 'domain',
            entityId: domainId,
            currentName: name,
          ),
          childCount: children.length,
        ),
        if (isExpanded && children.isNotEmpty) _buildHorizontalConnector(),
        if (isExpanded)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ...children.asMap().entries.map((entry) {
                final index = entry.key;
                final child = entry.value;
                return Padding(
                  padding: EdgeInsets.only(
                    top: index == 0 ? 0 : 4,
                    bottom: index == children.length - 1 ? 0 : 4,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildVerticalLine(index, children.length),
                      _buildTopicBranch(child),
                    ],
                  ),
                );
              }),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    const SizedBox(width: 20),
                    _buildAddButton(
                        'Thêm Topic', () => _addTopic(domainId, name)),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  /// Topic branch
  Widget _buildTopicBranch(Map<String, dynamic> topicData) {
    final topicId = topicData['id'] as String;
    final name = topicData['name'] as String;
    final domainId = topicData['domainId'] as String;
    final topicKey = 'topic-$topicId';
    final isExpanded = _expandedNodes.contains(topicKey);

    // Find lessons associated with this topic by topicId
    final topicLessons = _allNodes.where((n) {
      final node = n as Map<String, dynamic>;
      return node['topicId'] == topicId;
    }).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildNode(
          label: name,
          level: 2,
          isExpanded: isExpanded,
          onTap: () => _toggleExpand(topicKey),
          onAdd: () => _addLesson(domainId, name, topicId: topicId),
          onEdit: () => _showNodeActions(
            type: 'topic',
            entityId: topicId,
            currentName: name,
            domainId: domainId,
          ),
          childCount: topicLessons.length,
        ),
        if (isExpanded && topicLessons.isNotEmpty) _buildHorizontalConnector(),
        if (isExpanded)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ...topicLessons.asMap().entries.map((entry) {
                final index = entry.key;
                final node = entry.value as Map<String, dynamic>;
                return Padding(
                  padding: EdgeInsets.only(
                    top: index == 0 ? 0 : 4,
                    bottom: index == topicLessons.length - 1 ? 0 : 4,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildVerticalLine(index, topicLessons.length),
                      _buildLessonBranch({
                        'type': 'lesson',
                        'id': node['id'],
                        'name': node['title'] ?? 'Bài học',
                        'nodeData': node,
                      }),
                    ],
                  ),
                );
              }),
              // Add "Thêm bài học" button at end of lessons list
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    const SizedBox(width: 20),
                    _buildAddButton('Thêm bài học',
                        () => _addLesson(domainId, name, topicId: topicId)),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  // All 4 lesson format types
  static const _allLessonTypes = [
    {
      'key': 'image_quiz',
      'label': 'Hình ảnh (Quiz)',
      'icon': Icons.quiz_outlined
    },
    {
      'key': 'image_gallery',
      'label': 'Hình ảnh (Thư viện)',
      'icon': Icons.photo_library_outlined
    },
    {'key': 'video', 'label': 'Video', 'icon': Icons.play_circle_outline},
    {'key': 'text', 'label': 'Văn bản', 'icon': Icons.article_outlined},
  ];

  /// Fetch lesson type contents for a node from the API and cache them
  void _fetchLessonTypesForNode(String nodeId) {
    if (_lessonTypeCache.containsKey(nodeId) || _lessonTypeFetching.contains(nodeId)) return;
    _lessonTypeFetching.add(nodeId);
    final apiService = Provider.of<ApiService>(context, listen: false);
    apiService.getLessonTypeContents(nodeId).then((data) {
      if (!mounted) return;
      final types = (data['availableTypes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      setState(() {
        _lessonTypeCache[nodeId] = types;
        _lessonTypeFetching.remove(nodeId);
      });
    }).catchError((_) {
      if (!mounted) return;
      setState(() {
        _lessonTypeFetching.remove(nodeId);
        // Fallback: use legacy lessonType from node data
      });
    });
  }

  /// Lesson branch (level 3)
  Widget _buildLessonBranch(Map<String, dynamic> lessonData) {
    final name = lessonData['name'] as String;
    final nodeData = lessonData['nodeData'] as Map<String, dynamic>?;
    final nodeId = lessonData['id'] as String?;
    final lessonKey = 'lesson-$nodeId';
    final isExpanded = _expandedNodes.contains(lessonKey);

    // Fetch lesson types from API when expanding
    if (isExpanded && nodeId != null) {
      _fetchLessonTypesForNode(nodeId);
    }

    // Use cached data from API, fallback to legacy lessonType on node
    List<String> activeTypes;
    if (nodeId != null && _lessonTypeCache.containsKey(nodeId)) {
      activeTypes = _lessonTypeCache[nodeId]!;
    } else {
      final legacyType = nodeData?['lessonType'] as String?;
      activeTypes = legacyType != null ? [legacyType] : [];
    }
    final completedCount = activeTypes.length;

    // Extract topicId and domainId for adding new lesson types
    final topicId = nodeData?['topicId'] as String?;
    final domainId = nodeData?['domainId'] as String?;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildLessonNode(
          label: name,
          completedCount: completedCount,
          isExpanded: isExpanded,
          onTap: () => _toggleExpand(lessonKey),
          onEdit: nodeId != null
              ? () => _showNodeActions(
                    type: 'lesson',
                    entityId: nodeId,
                    currentName: name,
                  )
              : null,
        ),
        if (isExpanded) _buildHorizontalConnector(),
        if (isExpanded)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: _allLessonTypes.asMap().entries.map((entry) {
              final index = entry.key;
              final type = entry.value;
              final typeKey = type['key'] as String;
              final isActive = activeTypes.contains(typeKey);
              return Padding(
                padding: EdgeInsets.only(
                  top: index == 0 ? 0 : 4,
                  bottom: index == _allLessonTypes.length - 1 ? 0 : 4,
                ),
                child: Row(
                  children: [
                    _buildVerticalLine(index, _allLessonTypes.length),
                    _buildLessonTypeChip(
                      label: type['label'] as String,
                      icon: type['icon'] as IconData,
                      isActive: isActive,
                      onAction: isActive
                          ? () => _showLessonTypeActions(nodeId!, typeKey, type['label'] as String, nodeData!)
                          : () => _addLessonType(
                                typeKey: typeKey,
                                topicId: topicId,
                                domainId: domainId ?? '',
                                topicName: name,
                                existingNodeId: nodeId,
                                existingLessonType: activeTypes.isNotEmpty ? activeTypes.first : null,
                              ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  /// Lesson node with "X/4" counter
  Widget _buildLessonNode({
    required String label,
    required int completedCount,
    bool isExpanded = false,
    VoidCallback? onTap,
    VoidCallback? onEdit,
  }) {
    const color = Color(0xFFA8C4E6);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.25),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.article, size: 14, color: Colors.white),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            // X/4 badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: completedCount > 0
                    ? Colors.white.withValues(alpha: 0.35)
                    : Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$completedCount/4',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 3),
            Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              size: 16,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            if (onEdit != null) ...[
              const SizedBox(width: 3),
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit, size: 13, color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Lesson type chip: sáng nếu active (edit icon), mờ nếu chưa có (+ icon)
  Widget _buildLessonTypeChip({
    required String label,
    required IconData icon,
    required bool isActive,
    VoidCallback? onAction,
  }) {
    final activeColor = const Color(0xFF5B7EC2);
    return GestureDetector(
      onTap: onAction,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 190),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? activeColor : const Color(0xFFD0DEF0),
            width: 1.5,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                      color: activeColor.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2))
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? Colors.white : const Color(0xFFB0BEC5),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : const Color(0xFFB0BEC5),
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            // Active: edit icon | Inactive: add icon
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white.withValues(alpha: 0.25)
                    : const Color(0xFFD0DEF0).withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isActive ? Icons.edit : Icons.add,
                size: 12,
                color: isActive ? Colors.white : const Color(0xFF5B7EC2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================
  // UI Components
  // ==================

  static const _levelColors = [
    Color(0xFF3B4F7A), // Môn học - navy
    Color(0xFF5B7EC2), // Domain - blue
    Color(0xFF7C9ED9), // Topic - light blue
    Color(0xFFA8C4E6), // Bài học - lighter blue
    Color(0xFFD0DEF0), // Dạng bài - very light blue
  ];

  static const _levelIcons = [
    Icons.school, // Môn học
    Icons.folder_open, // Domain
    Icons.topic, // Topic
    Icons.article, // Bài học
    Icons.extension, // Dạng bài
  ];

  Widget _buildNode({
    required String label,
    required int level,
    bool isExpanded = false,
    VoidCallback? onTap,
    VoidCallback? onAdd,
    VoidCallback? onEdit,
    int childCount = 0,
  }) {
    final color = _levelColors[level.clamp(0, _levelColors.length - 1)];
    final icon = _levelIcons[level.clamp(0, _levelIcons.length - 1)];
    final maxWidth = level == 0
        ? 220.0
        : level == 4
            ? 130.0
            : 190.0;
    final vertPad = level <= 1 ? 12.0 : 8.0;
    final horizPad = level <= 1 ? 14.0 : 10.0;
    final fontSize = level == 0
        ? 14.0
        : level == 4
            ? 11.0
            : 12.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: EdgeInsets.symmetric(horizontal: horizPad, vertical: vertPad),
        decoration: BoxDecoration(
          color: level == 4 ? Colors.white : color,
          borderRadius: BorderRadius.circular(level <= 1 ? 14 : 10),
          border: Border.all(
            color: level == 4 ? color : Colors.white.withValues(alpha: 0.3),
            width: level == 4 ? 1.5 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: level == 4 ? 0.08 : 0.25),
              blurRadius: level <= 1 ? 10 : 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: level <= 1 ? 18 : 14,
                color: level == 4 ? color : Colors.white),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: level == 4 ? color : Colors.white,
                  fontSize: fontSize,
                  fontWeight: level <= 1 ? FontWeight.bold : FontWeight.w500,
                  height: 1.3,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (childCount > 0 && onTap != null) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: level == 4
                      ? color.withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$childCount',
                  style: TextStyle(
                    color: level == 4 ? color : Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            if (onTap != null) ...[
              const SizedBox(width: 3),
              Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                size: 16,
                color: level == 4
                    ? color.withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.7),
              ),
            ],
            // Edit button (pencil icon)
            if (onEdit != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color:
                        Colors.white.withValues(alpha: level == 4 ? 0.0 : 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.edit,
                      size: 13, color: level == 4 ? color : Colors.white),
                ),
              ),
            ],
            // Add button (+ icon)
            if (onAdd != null) ...[
              const SizedBox(width: 3),
              GestureDetector(
                onTap: onAdd,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color:
                        Colors.white.withValues(alpha: level == 4 ? 0.0 : 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.add,
                      size: 13, color: level == 4 ? color : Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalConnector() {
    return Container(
      width: 32,
      height: 2,
      color: const Color(0xFFB0BEC5),
    );
  }

  Widget _buildVerticalLine(int index, int total) {
    return SizedBox(
      width: 20,
      height: 40,
      child: CustomPaint(
        painter: _TreeLinePainter(
          isFirst: index == 0,
          isLast: index == total - 1,
          isSingle: total == 1,
        ),
      ),
    );
  }

  Widget _buildAddButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.contributorBlue.withOpacity(0.3),
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 14, color: AppColors.contributorBlue),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: AppColors.contributorBlue,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================
  // Actions
  // ==================

  void _toggleExpand(String key) {
    setState(() {
      if (_expandedNodes.contains(key)) {
        _expandedNodes.remove(key);
      } else {
        _expandedNodes.add(key);
      }
    });
  }

  Future<void> _addDomain() async {
    final subjectName = _subjectData?['name'] ?? widget.subjectName ?? '';
    final result = await context.push(
      '/contributor/create-domain?subjectId=${widget.subjectId}&subjectName=${Uri.encodeComponent(subjectName)}',
    );
    if (result == true) _loadData();
  }

  Future<void> _addTopic(String domainId, String domainName) async {
    final result = await context.push(
      '/contributor/create-topic?subjectId=${widget.subjectId}&domainId=$domainId&domainName=${Uri.encodeComponent(domainName)}',
    );
    if (result == true) _loadData();
  }

  Future<void> _addLesson(String domainId, String topicName,
      {String? topicId}) async {
    final queryParts = [
      'subjectId=${widget.subjectId}',
      'domainId=$domainId',
      'topicName=${Uri.encodeComponent(topicName)}',
    ];
    if (topicId != null) queryParts.add('topicId=$topicId');
    final result = await context.push(
      '/contributor/create-lesson?${queryParts.join('&')}',
    );
    if (result == true) _loadData();
  }

  /// Navigate to edit an existing lesson type (opens the relevant editor with pre-filled data)
  Future<void> _editLessonType(String nodeId, String lessonType, Map<String, dynamic> nodeData) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      // Load content for this specific lesson type from the API
      final contentResponse = await apiService.getLessonTypeContents(nodeId);
      final contents = contentResponse['contents'] as List? ?? [];

      Map<String, dynamic>? existingContent;
      for (final c in contents) {
        final m = c as Map<String, dynamic>;
        if (m['lessonType'] == lessonType) {
          existingContent = m;
          break;
        }
      }

      if (!mounted) return;
      Navigator.of(context).pop(); // dismiss loading

      final lessonData = existingContent?['lessonData'] as Map<String, dynamic>? ?? {};
      final endQuiz = existingContent?['endQuiz'] as Map<String, dynamic>?;
      final title = nodeData['title'] as String? ?? '';
      final description = nodeData['description'] as String? ?? '';
      final domainId = nodeData['domainId'] as String? ?? '';
      final topicId = nodeData['topicId'] as String?;

      // Open the appropriate editor pre-filled with existing content
      Widget editor;
      switch (lessonType) {
        case 'image_quiz':
          editor = ImageQuizEditorScreen(
            subjectId: widget.subjectId,
            domainId: domainId,
            topicId: topicId,
            nodeId: nodeId,
            initialLessonData: lessonData,
            initialEndQuiz: endQuiz,
            isEditMode: true,
            originalLessonData: lessonData,
            originalEndQuiz: endQuiz,
          );
          break;
        case 'image_gallery':
          editor = ImageGalleryEditorScreen(
            subjectId: widget.subjectId,
            domainId: domainId,
            topicId: topicId,
            nodeId: nodeId,
            initialLessonData: lessonData,
            initialEndQuiz: endQuiz,
            isEditMode: true,
            originalLessonData: lessonData,
            originalEndQuiz: endQuiz,
          );
          break;
        case 'video':
          editor = VideoEditorScreen(
            subjectId: widget.subjectId,
            domainId: domainId,
            topicId: topicId,
            nodeId: nodeId,
            initialLessonData: lessonData,
            initialEndQuiz: endQuiz,
            isEditMode: true,
            originalLessonData: lessonData,
            originalEndQuiz: endQuiz,
          );
          break;
        case 'text':
        default:
          editor = TextEditorScreen(
            subjectId: widget.subjectId,
            domainId: domainId,
            topicId: topicId,
            nodeId: nodeId,
            initialLessonData: lessonData,
            initialEndQuiz: endQuiz,
            isEditMode: true,
            originalLessonData: lessonData,
            originalEndQuiz: endQuiz,
          );
          break;
      }

      if (!mounted) return;
      final result = await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => editor),
      );
      if (result == true) _loadData();
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // dismiss loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải nội dung: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Show actions for an active (existing) lesson type: Edit, History
  void _showLessonTypeActions(String nodeId, String typeKey, String typeLabel, Map<String, dynamic> nodeData) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.extension, color: Color(0xFF5B7EC2), size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          typeLabel,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
                        ),
                        Text(
                          nodeData['title'] as String? ?? 'Bài học',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF718096)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 8),
              // Edit content
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.edit_outlined, color: Colors.blue, size: 22),
                ),
                title: const Text('Sửa nội dung', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2D3748))),
                subtitle: const Text('Chỉnh sửa nội dung bài học (cần duyệt)', style: TextStyle(fontSize: 12, color: Color(0xFF718096))),
                onTap: () {
                  Navigator.pop(ctx);
                  _editLessonType(nodeId, typeKey, nodeData);
                },
              ),
              // Version history
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.history, color: Colors.purple, size: 22),
                ),
                title: const Text('Lịch sử chỉnh sửa', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2D3748))),
                subtitle: const Text('Xem các phiên bản trước đó', style: TextStyle(fontSize: 12, color: Color(0xFF718096))),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => LessonTypeHistoryScreen(
                        nodeId: nodeId,
                        lessonType: typeKey,
                        subjectId: widget.subjectId,
                        domainId: nodeData['domainId'] as String?,
                        topicId: nodeData['topicId'] as String?,
                        lessonTitle: nodeData['title'] as String?,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// Navigate to add a new lesson type (creates a new learning node of a specific type)
  Future<void> _addLessonType({
    required String typeKey,
    String? topicId,
    required String domainId,
    required String topicName,
    String? existingNodeId,
    String? existingLessonType,
  }) async {
    final queryParts = [
      'subjectId=${widget.subjectId}',
      'domainId=$domainId',
      'topicName=${Uri.encodeComponent(topicName)}',
      'lessonType=$typeKey',
    ];
    if (topicId != null) queryParts.add('topicId=$topicId');
    if (existingNodeId != null) {
      queryParts.add('nodeId=$existingNodeId');
      queryParts.add('existingLessonNodeId=$existingNodeId');
    }
    if (existingLessonType != null) queryParts.add('existingLessonType=$existingLessonType');
    final result = await context.push(
      '/lessons/create?${queryParts.join('&')}',
    );
    if (result == true) _loadData();
  }

  void _showNodeActions({
    required String type,
    required String entityId,
    required String currentName,
    String? domainId,
  }) {
    HapticFeedback.mediumImpact();
    final typeLabel = type == 'subject'
        ? 'Môn học'
        : type == 'domain'
            ? 'Domain'
            : type == 'topic'
                ? 'Topic'
                : 'Bài học';
    final levelIndex = type == 'subject'
        ? 0
        : type == 'domain'
            ? 1
            : type == 'topic'
                ? 2
                : 3;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    _levelIcons[levelIndex],
                    color: _levelColors[levelIndex],
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          typeLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          currentName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 8),
              // Edit option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.edit_outlined,
                      color: Colors.blue, size: 22),
                ),
                title: Text(
                  'Sửa tên $typeLabel',
                  style: const TextStyle(
                    color: Color(0xFF2D3748),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Đề xuất đổi tên (cần duyệt)',
                  style: TextStyle(fontSize: 12, color: Color(0xFF718096)),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditDialog(
                    type: type,
                    entityId: entityId,
                    currentName: currentName,
                    domainId: domainId,
                  );
                },
              ),
              // Delete option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.delete_outline,
                      color: Colors.red, size: 22),
                ),
                title: Text(
                  'Xóa $typeLabel',
                  style: const TextStyle(
                    color: Color(0xFF2D3748),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Đề xuất xóa (cần duyệt)',
                  style: TextStyle(fontSize: 12, color: Color(0xFF718096)),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showDeleteDialog(
                    type: type,
                    entityId: entityId,
                    currentName: currentName,
                    domainId: domainId,
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog({
    required String type,
    required String entityId,
    required String currentName,
    String? domainId,
  }) {
    final typeLabel = type == 'subject'
        ? 'Môn học'
        : type == 'domain'
            ? 'Domain'
            : 'Topic';
    final nameController = TextEditingController(text: currentName);
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Sửa tên $typeLabel'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Tên mới',
                hintText: 'Nhập tên mới cho $typeLabel',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Lý do (tùy chọn)',
                hintText: 'Tại sao muốn đổi tên?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.amber[800]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Đề xuất sẽ được gửi cho Admin duyệt',
                      style: TextStyle(fontSize: 12, color: Colors.amber[800]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.contributorBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isEmpty || newName == currentName) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Vui lòng nhập tên mới khác tên hiện tại')),
                );
                return;
              }
              Navigator.pop(ctx);
              await _submitEditContribution(
                type: type,
                entityId: entityId,
                newName: newName,
                reason: reasonController.text.trim(),
                domainId: domainId,
              );
            },
            child: const Text('Gửi đề xuất'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog({
    required String type,
    required String entityId,
    required String currentName,
    String? domainId,
  }) {
    final typeLabel = type == 'subject'
        ? 'Môn học'
        : type == 'domain'
            ? 'Domain'
            : 'Topic';
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Text('Xóa $typeLabel'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Bạn đang đề xuất xóa $typeLabel "$currentName"',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Lý do xóa *',
                hintText: 'Vui lòng cho biết lý do xóa',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.amber[800]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Đề xuất xóa sẽ được Admin xem xét và duyệt',
                      style: TextStyle(fontSize: 12, color: Colors.amber[800]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập lý do xóa')),
                );
                return;
              }
              Navigator.pop(ctx);
              await _submitDeleteContribution(
                type: type,
                entityId: entityId,
                reason: reason,
                domainId: domainId,
              );
            },
            child: const Text('Gửi đề xuất xóa'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitEditContribution({
    required String type,
    required String entityId,
    required String newName,
    String? reason,
    String? domainId,
  }) async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.createEditContribution(
        type: type,
        entityId: entityId,
        newName: newName,
        reason: reason,
        domainId: domainId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã gửi đề xuất sửa tên thành công!'),
            backgroundColor: Colors.green[600],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitDeleteContribution({
    required String type,
    required String entityId,
    String? reason,
    String? domainId,
  }) async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.createDeleteContribution(
        type: type,
        entityId: entityId,
        reason: reason,
        domainId: domainId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã gửi đề xuất xóa thành công!'),
            backgroundColor: Colors.green[600],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Custom painter for tree connector lines
class _TreeLinePainter extends CustomPainter {
  final bool isFirst;
  final bool isLast;
  final bool isSingle;

  _TreeLinePainter({
    required this.isFirst,
    required this.isLast,
    this.isSingle = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFB0BEC5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final midX = size.width / 2;
    final midY = size.height / 2;

    if (isSingle) {
      // Single child: horizontal line
      canvas.drawLine(Offset(0, midY), Offset(midX, midY), paint);
    } else if (isFirst) {
      // First child: vertical from mid to bottom + horizontal
      canvas.drawLine(Offset(midX, midY), Offset(midX, size.height), paint);
      canvas.drawLine(Offset(midX, midY), Offset(size.width, midY), paint);
    } else if (isLast) {
      // Last child: vertical from top to mid + horizontal
      canvas.drawLine(Offset(midX, 0), Offset(midX, midY), paint);
      canvas.drawLine(Offset(midX, midY), Offset(size.width, midY), paint);
    } else {
      // Middle child: vertical full + horizontal
      canvas.drawLine(Offset(midX, 0), Offset(midX, size.height), paint);
      canvas.drawLine(Offset(midX, midY), Offset(size.width, midY), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
