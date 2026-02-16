import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/core/utils/navigation_helper.dart';
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
  int _currentTutorialStep = 0;
  bool _showTutorial = false;
  bool _dontShowAgain = false;
  String _userRole = 'user';

  bool get _isContributor => _userRole == 'contributor' || _userRole == 'admin';

  // Mind map interaction state
  int _currentLevel = 1; // 1 = Subject, 2 = Domains, 3 = Topics
  String? _selectedSubjectNodeId; // Selected subject node
  String? _selectedDomainNodeId; // Selected domain node

  static const String _tutorialPrefKey = 'mindmap_tutorial_done';

  @override
  void initState() {
    super.initState();
    _checkTutorialPref();
    _loadSubjectIntro();
  }

  Future<void> _checkTutorialPref() async {
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getBool(_tutorialPrefKey) ?? false;
    if (!done && mounted) {
      setState(() => _showTutorial = true);
    }
  }

  Future<void> _saveTutorialPref() async {
    if (_dontShowAgain) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_tutorialPrefKey, true);
    }
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
    _saveTutorialPref();
    setState(() => _showTutorial = false);
  }

  void _nextStep() {
    if (_currentTutorialStep < 2) {
      setState(() => _currentTutorialStep++);
    } else {
      _skipTutorial();
    }
  }

  void _prevStep() {
    if (_currentTutorialStep > 0) {
      setState(() => _currentTutorialStep--);
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
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.blue.shade400),
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
      progressTimer =
          Timer.periodic(const Duration(milliseconds: 500), (timer) async {
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

          final progress =
              (progressData['progress'] as num?)?.toDouble() ?? 0.0;
          final status = progressData['status'] as String? ?? 'generating';
          final currentStep =
              progressData['currentStep'] as String? ?? 'Đang xử lý...';

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
                content:
                    Text(result['message'] ?? 'Đã tạo bài học thành công!'),
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

            final errorMsg =
                progressData['error'] as String? ?? 'Có lỗi xảy ra';
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
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Giới thiệu khóa học',
            style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary)),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderPrimary),
            ),
            child: const Icon(Icons.arrow_back,
                color: AppColors.textPrimary, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_showTutorial)
            TextButton(
              onPressed: _skipTutorial,
              child: Text('Bỏ qua',
                  style: AppTextStyles.labelMedium
                      .copyWith(color: AppColors.cyanNeon)),
            ),
        ],
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
                          color: AppColors.errorNeon.withOpacity(0.15),
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
                              const SizedBox(height: 16),

                              // Unlock button (diamond)
                              if (!_isContributor) _buildUnlockBanner(),
                              const SizedBox(height: 16),

                              // Mind map buttons
                              _buildMindMapButtons(),

                              // Mind map (knowledge graph)
                              _buildKnowledgeGraphContent(),
                              const SizedBox(height: 24),

                              // Domains list
                              _buildDomainsList(),
                              const SizedBox(height: 24),

                              // Contributor: nút vào mind map editor
                              if (_isContributor)
                                _buildContributorQuickAccess(),
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
    final trackColor =
        track == 'explorer' ? AppColors.successNeon : AppColors.cyanNeon;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [trackColor.withOpacity(0.15), trackColor.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: trackColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [trackColor, trackColor.withOpacity(0.8)]),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: trackColor.withOpacity(0.4), blurRadius: 8)
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
        color: AppColors.contributorBlue.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.contributorBlue.withOpacity(0.2)),
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
                color: AppColors.contributorBlue.withOpacity(0.12),
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
                color: AppColors.cyanNeon,
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
                colors: [nodeColor.withOpacity(0.9), nodeColor],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: nodeColor.withOpacity(0.4),
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
                    color: Colors.white.withOpacity(0.2),
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
                                    color: Colors.black.withOpacity(0.3),
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
        border: Border.all(color: AppColors.borderPrimary),
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
                      color: AppColors.cyanNeon)),
              Expanded(
                  child: _OutlineItem(
                      icon: Icons.category_rounded,
                      label: 'Domain',
                      value: '${outline['totalDomains'] ?? 0}',
                      color: AppColors.pinkNeon)),
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
              AppColors.purpleNeon.withOpacity(0.12),
              AppColors.cyanNeon.withOpacity(0.08)
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.purpleNeon.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.purpleNeon.withOpacity(0.2),
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
                    'Mo khoa bai hoc',
                    style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Su dung kim cuong de mo khoa tung bai, chuong hoac ca mon',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.purpleNeon.withOpacity(0.15),
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

      // Skill tree generation removed (tables dropped)

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

    final colors = [
      [AppColors.purpleNeon, AppColors.pinkNeon],
      [AppColors.cyanNeon, AppColors.successNeon],
      [AppColors.orangeNeon, AppColors.xpGold],
      [AppColors.pinkNeon, AppColors.purpleNeon],
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
              border: Border.all(color: AppColors.borderPrimary),
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
                                color: colorPair[0].withOpacity(0.3),
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

  Widget _buildTutorialOverlay() {
    final isLast = _currentTutorialStep == 2;

    return Container(
      color: Colors.black.withOpacity(0.9),
      child: SafeArea(
        child: Column(
          children: [
            // Header with skip button
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Bước ${_currentTutorialStep + 1}/3',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.7), fontSize: 14),
                  ),
                  TextButton(
                    onPressed: _skipTutorial,
                    child: const Text('Bỏ qua',
                        style: TextStyle(color: Colors.white70)),
                  ),
                ],
              ),
            ),

            // Title
            const Text(
              'Hướng dẫn sử dụng Mind Map',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Illustration
            Expanded(child: _buildIllustration()),

            // Checkbox for last step
            if (isLast)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Checkbox(
                      value: _dontShowAgain,
                      onChanged: (v) =>
                          setState(() => _dontShowAgain = v ?? false),
                      fillColor: WidgetStateProperty.all(Colors.orange),
                    ),
                    const Text('Không hiển thị lại',
                        style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),

            // Navigation
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_currentTutorialStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _prevStep,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Quay lại'),
                      ),
                    ),
                  if (_currentTutorialStep > 0) const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(isLast ? 'Bắt đầu!' : 'Tiếp theo'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIllustration() {
    switch (_currentTutorialStep) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
      case 2:
        return _buildStep3();
      default:
        return const SizedBox.shrink();
    }
  }

  // Step 1: Click Subject
  Widget _buildStep1() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Subject node illustration
        Container(
          width: 180,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [Colors.orange.shade400, Colors.orange.shade600]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.orange.withOpacity(0.5), blurRadius: 20)
            ],
          ),
          child: Column(
            children: [
              const Icon(Icons.school, color: Colors.white, size: 48),
              const SizedBox(height: 8),
              const Text('Môn học',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.touch_app,
                      color: Colors.yellow.shade300, size: 20),
                  const SizedBox(width: 4),
                  Text('Nhấn vào đây',
                      style: TextStyle(
                          color: Colors.yellow.shade300, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Nhấn vào node Môn học để mở rộng và xem các Domain (lĩnh vực) bên trong',
            style: TextStyle(color: Colors.white, fontSize: 15),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  // Step 2: Click Domain
  Widget _buildStep2() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Subject small
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.orange.shade400,
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.school, color: Colors.white, size: 24),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.arrow_forward, color: Colors.white54),
            ),
            // Domains
            Column(
              children: [
                _domainBox('Domain 1', false),
                const SizedBox(height: 8),
                _domainBox('Domain 2', true),
                const SizedBox(height: 8),
                _domainBox('Domain 3', false),
              ],
            ),
          ],
        ),
        const SizedBox(height: 32),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Nhấn vào Domain để xem các Topic (chủ đề) bên trong',
            style: TextStyle(color: Colors.white, fontSize: 15),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _domainBox(String text, bool highlight) {
    return Container(
      width: 130,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: highlight
            ? LinearGradient(
                colors: [Colors.blue.shade400, Colors.blue.shade600])
            : null,
        color: highlight ? null : Colors.blue.shade300,
        borderRadius: BorderRadius.circular(10),
        boxShadow: highlight
            ? [BoxShadow(color: Colors.blue.withOpacity(0.5), blurRadius: 12)]
            : null,
      ),
      child: Row(
        children: [
          const Icon(Icons.category, color: Colors.white, size: 18),
          const SizedBox(width: 6),
          Text(text,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: highlight ? FontWeight.bold : FontWeight.normal)),
          if (highlight) ...[
            const Spacer(),
            Icon(Icons.touch_app, color: Colors.yellow.shade300, size: 16)
          ],
        ],
      ),
    );
  }

  // Step 3: Click Topic
  Widget _buildStep3() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.blue.shade400,
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.category, color: Colors.white, size: 20),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Icon(Icons.arrow_forward, color: Colors.white54, size: 20),
            ),
            Column(
              children: [
                _topicBox('Topic 1', false),
                const SizedBox(height: 6),
                _topicBox('Topic 2', true),
                const SizedBox(height: 6),
                _topicBox('Topic 3', false),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Icon(Icons.arrow_forward, color: Colors.white54, size: 20),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.green.shade500,
                  borderRadius: BorderRadius.circular(10)),
              child: const Column(
                children: [
                  Icon(Icons.play_lesson, color: Colors.white, size: 28),
                  SizedBox(height: 4),
                  Text('Bài học',
                      style: TextStyle(color: Colors.white, fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Nhấn vào Topic để xem danh sách bài học và bắt đầu học!',
            style: TextStyle(color: Colors.white, fontSize: 15),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _topicBox(String text, bool highlight) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        gradient: highlight
            ? LinearGradient(
                colors: [Colors.teal.shade400, Colors.teal.shade600])
            : null,
        color: highlight ? null : Colors.teal.shade300,
        borderRadius: BorderRadius.circular(8),
        boxShadow: highlight
            ? [BoxShadow(color: Colors.teal.withOpacity(0.5), blurRadius: 10)]
            : null,
      ),
      child: Row(
        children: [
          const Icon(Icons.topic, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(text,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: highlight ? FontWeight.bold : FontWeight.normal)),
          if (highlight) ...[
            const Spacer(),
            Icon(Icons.touch_app, color: Colors.yellow.shade300, size: 14)
          ],
        ],
      ),
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
              color: color.withOpacity(0.15),
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
          color: isSelected ? color.withOpacity(0.15) : AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isSelected ? color.withOpacity(0.5) : AppColors.borderPrimary,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 10)]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(title,
                style: AppTextStyles.labelMedium.copyWith(
                    color: isSelected ? color : AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textTertiary)),
          ],
        ),
      ),
    );
  }
}

/// Compact version of _MindMapButton for 3-column layout
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
          color: isSelected ? color.withOpacity(0.15) : AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? color.withOpacity(0.5) : AppColors.borderPrimary,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 8)]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
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
