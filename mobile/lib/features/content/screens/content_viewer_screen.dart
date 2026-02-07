import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/core/config/api_config.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:edtech_mobile/features/content/widgets/web_video_player.dart';
import 'package:edtech_mobile/features/content/widgets/content_format_badge.dart';
import 'package:edtech_mobile/features/content/widgets/difficulty_badge.dart';
import 'package:edtech_mobile/features/content/widgets/rewards_display.dart';
import 'package:edtech_mobile/features/quiz/screens/quiz_screen.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:edtech_mobile/theme/theme.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';

class ContentViewerScreen extends StatefulWidget {
  final String contentId;

  const ContentViewerScreen({
    super.key,
    required this.contentId,
  });

  @override
  State<ContentViewerScreen> createState() => _ContentViewerScreenState();
}

/// Enum for content display modes
enum ContentDisplayMode {
  text,
  image,
  video,
}

/// Enum for text complexity levels
enum TextComplexityLevel {
  simple,    // Đơn giản
  detailed,  // Chi tiết
  comprehensive, // Chuyên sâu
}

class _ContentViewerScreenState extends State<ContentViewerScreen> {
  Map<String, dynamic>? _contentData;
  Map<String, dynamic>? _nextContentItem;
  Map<String, dynamic>? _prevContentItem;
  bool _isLoading = true;
  String? _error;
  int? _selectedQuizAnswer;
  bool _showQuizResult = false;
  bool _isCompleting = false;
  bool _isCompleted = false;
  String? _userRole; // Store user role: 'user' (learner), 'contributor', 'admin'
  bool get _canEdit => _userRole == 'contributor' || _userRole == 'admin';
  
  // Content display mode - user can switch between text, image, video
  ContentDisplayMode _displayMode = ContentDisplayMode.text;
  
  // Text complexity level - simple, detailed, comprehensive
  TextComplexityLevel _textComplexity = TextComplexityLevel.detailed;
  
  // Cached text variants
  Map<String, String>? _textVariants;
  bool _isLoadingVariants = false;

  @override
  void initState() {
    super.initState();
    _loadContent();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final profile = await apiService.getUserProfile();
      setState(() {
        _userRole = profile['role'] as String?;
      });
    } catch (e) {
      // Ignore error, user might not be logged in
    }
  }

  @override
  void didUpdateWidget(ContentViewerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload content when contentId changes (e.g., when navigating with context.go())
    if (oldWidget.contentId != widget.contentId) {
      print(
          '🔄 Content ID changed from ${oldWidget.contentId} to ${widget.contentId}, reloading...');
      // Reset state before reloading
      setState(() {
        _isLoading = true;
        _error = null;
        _isCompleted = false;
        _isCompleting = false;
        _showQuizResult = false;
        _selectedQuizAnswer = null;
        _nextContentItem = null;
        _prevContentItem = null;
        _displayMode = ContentDisplayMode.text; // Reset to text mode
      });
      _loadContent();
    }
  }

  /// Helper function to convert relative path to full URL
  String _buildFullUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    // If already a full URL (starts with http:// or https://), return as is
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    // If it's a relative path (starts with /), prepend base URL
    // Extract base URL from ApiConfig (remove /api/v1)
    final baseUrl = ApiConfig.baseUrl.replaceAll('/api/v1', '');
    return '$baseUrl$url';
  }

  Future<void> _loadContent() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final data = await apiService.getContentDetail(widget.contentId);

      // Load all content items from the same node
      final nodeId = data['nodeId'] as String?;
      if (nodeId != null) {
        try {
          final allItems = await apiService.getContentByNode(nodeId);
          // Sort by order
          allItems.sort((a, b) =>
              (a['order'] as int? ?? 0).compareTo(b['order'] as int? ?? 0));

          final currentIndex =
              allItems.indexWhere((item) => item['id'] == widget.contentId);

          print('Loaded ${allItems.length} content items');
          print('Current content ID: ${widget.contentId}');
          print('Current index: $currentIndex');

          final nextItem =
              currentIndex >= 0 && currentIndex < allItems.length - 1
                  ? allItems[currentIndex + 1]
                  : null;
          final prevItem = currentIndex > 0 ? allItems[currentIndex - 1] : null;

          print('Next item: ${nextItem?['id']} - ${nextItem?['title']}');
          print('Prev item: ${prevItem?['id']} - ${prevItem?['title']}');
          
          // Debug: Log textVariants
          final textVariants = data['textVariants'];
          print('📝 TextVariants loaded: ${textVariants != null}');
          if (textVariants != null) {
            print('  - simple: ${(textVariants['simple'] as String?)?.substring(0, (textVariants['simple'] as String?)?.length.clamp(0, 50) ?? 0) ?? "null"}...');
            print('  - detailed: ${(textVariants['detailed'] as String?)?.substring(0, (textVariants['detailed'] as String?)?.length.clamp(0, 50) ?? 0) ?? "null"}...');
            print('  - comprehensive: ${(textVariants['comprehensive'] as String?)?.substring(0, (textVariants['comprehensive'] as String?)?.length.clamp(0, 50) ?? 0) ?? "null"}...');
          }

          setState(() {
            _contentData = data;
            _nextContentItem = nextItem;
            _prevContentItem = prevItem;
            _isLoading = false;
          });
        } catch (e) {
          // If can't load content items, just show current content
          setState(() {
            _contentData = data;
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _contentData = data;
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

  Future<void> _markComplete({int? score}) async {
    if (_contentData == null || _isCompleting) return;

    setState(() {
      _isCompleting = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final nodeId = _contentData!['nodeId'] as String;
      final contentItemId = _contentData!['id'] as String;
      final itemType = _contentData!['type'] as String;

      await apiService.completeContentItem(
        nodeId: nodeId,
        contentItemId: contentItemId,
        itemType: itemType,
        score: score,
      );

      // Show success message and mark as completed
      if (mounted) {
        setState(() {
          _isCompleted = true;
        });

        // Reload content items to ensure navigation buttons are available
        await _loadContentItems();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã hoàn thành! 🎉'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
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
    } finally {
      if (mounted) {
        setState(() {
          _isCompleting = false;
        });
      }
    }
  }

  void _submitQuizAnswer() {
    if (_selectedQuizAnswer == null) return;

    final quizData = _contentData!['quizData'] as Map<String, dynamic>?;
    if (quizData == null) return;

    final correctAnswer = quizData['correctAnswer'] as int?;
    final isCorrect = _selectedQuizAnswer == correctAnswer;

    setState(() {
      _showQuizResult = true;
    });

    // Mark complete with score, then reload content items for navigation
    _markComplete(score: isCorrect ? 100 : 0).then((_) {
      // Reload content items after completion to ensure navigation buttons work
      _loadContentItems();
    });
  }

  void _navigateToEditLesson() {
    // Navigate to edit lesson screen with current content data
    context
        .push(
      '/content/${widget.contentId}/edit',
      extra: _contentData,
    )
        .then((result) {
      // Reload content after returning from edit screen
      if (result == true) {
        _loadContent();
      }
    });
  }

  Future<void> _loadContentItems() async {
    final nodeId = _contentData?['nodeId'] as String?;
    if (nodeId == null) return;

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final allItems = await apiService.getContentByNode(nodeId);
      // Sort by order
      allItems.sort((a, b) =>
          (a['order'] as int? ?? 0).compareTo(b['order'] as int? ?? 0));

      final currentIndex =
          allItems.indexWhere((item) => item['id'] == widget.contentId);

      print('Reloaded ${allItems.length} content items');
      print('Current content ID: ${widget.contentId}');
      print('Current index: $currentIndex');

      final nextItem = currentIndex >= 0 && currentIndex < allItems.length - 1
          ? allItems[currentIndex + 1]
          : null;
      final prevItem = currentIndex > 0 ? allItems[currentIndex - 1] : null;

      print('Next item: ${nextItem?['id']} - ${nextItem?['title']}');
      print('Prev item: ${prevItem?['id']} - ${prevItem?['title']}');

      if (mounted) {
        setState(() {
          _nextContentItem = nextItem;
          _prevContentItem = prevItem;
        });
      }
    } catch (e) {
      print('Error reloading content items: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _contentData?['title'] ?? 'Content',
          style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderPrimary),
            ),
            child: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 20),
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
        actions: [
          if (_canEdit)
            IconButton(
              icon: Icon(Icons.history_rounded, color: AppColors.textSecondary),
              onPressed: () {
                context.push('/content/${widget.contentId}/versions');
              },
              tooltip: 'Lịch sử phiên bản',
            ),
          if (_canEdit)
            TextButton.icon(
              onPressed: () => _navigateToEditLesson(),
              icon: Icon(Icons.edit_rounded, size: 18, color: AppColors.cyanNeon),
              label: Text('Chỉnh sửa', style: AppTextStyles.labelSmall.copyWith(color: AppColors.cyanNeon)),
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.purpleNeon))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.errorNeon.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.errorNeon),
                        ),
                        const SizedBox(height: 16),
                        Text('Error: $_error', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        GamingButton(
                          text: 'Thử lại',
                          onPressed: _loadContent,
                          icon: Icons.refresh_rounded,
                        ),
                      ],
                    ),
                  ),
                )
              : _contentData == null
                  ? Center(child: Text('No data available', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)))
                  : _buildContent(),
    );
  }

  Widget _buildContent() {
    final type = _contentData!['type'] as String;

    switch (type) {
      case 'concept':
        return _buildConceptView();
      case 'example':
        return _buildExampleView();
      case 'boss_quiz':
        return _buildQuizView();
      case 'hidden_reward':
        return _buildRewardView();
      default:
        return _buildDefaultView();
    }
  }

  /// Check if content has text
  bool get _hasText {
    return _contentData?['richContent'] != null || 
           (_contentData?['content'] != null && _contentData!['content'].toString().isNotEmpty);
  }

  /// Check if content has image
  bool get _hasImage {
    final media = _contentData?['media'];
    if (media == null) return false;
    final imageUrl = media['imageUrl'];
    final imageUrls = media['imageUrls'] as List?;
    return (imageUrl != null && imageUrl.toString().isNotEmpty) ||
           (imageUrls != null && imageUrls.isNotEmpty);
  }

  /// Check if content has video (either actual video or video format metadata)
  bool get _hasVideo {
    final media = _contentData?['media'];
    if (media == null) return false;
    
    // Check for actual video file
    final videoUrl = media['videoUrl'];
    final hasVideoUrl = videoUrl != null && videoUrl.toString().isNotEmpty;
    
    // Check for video format metadata (script/description)
    final videoScript = media['videoScript'];
    final videoDescription = media['videoDescription'];
    final hasVideoFormat = (videoScript != null && videoScript.toString().isNotEmpty) ||
                           (videoDescription != null && videoDescription.toString().isNotEmpty);
    
    return hasVideoUrl || hasVideoFormat;
  }

  /// Get available display modes for current content
  List<ContentDisplayMode> get _availableModes {
    final modes = <ContentDisplayMode>[];
    if (_hasText) modes.add(ContentDisplayMode.text);
    if (_hasImage) modes.add(ContentDisplayMode.image);
    if (_hasVideo) modes.add(ContentDisplayMode.video);
    return modes;
  }

  /// Build the content format switcher widget
  Widget _buildContentModeSwitcher() {
    final modes = _availableModes;
    
    // If only one mode available, don't show switcher
    if (modes.length <= 1) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: modes.map((mode) {
          final isSelected = _displayMode == mode;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _displayMode = mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getModeIcon(mode),
                      size: 18,
                      color: isSelected ? Colors.blue : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getModeLabel(mode),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? Colors.blue : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _getModeIcon(ContentDisplayMode mode) {
    switch (mode) {
      case ContentDisplayMode.text:
        return Icons.article_outlined;
      case ContentDisplayMode.image:
        return Icons.image_outlined;
      case ContentDisplayMode.video:
        return Icons.play_circle_outline;
    }
  }

  String _getModeLabel(ContentDisplayMode mode) {
    switch (mode) {
      case ContentDisplayMode.text:
        return 'Văn bản';
      case ContentDisplayMode.image:
        return 'Hình ảnh';
      case ContentDisplayMode.video:
        return 'Video';
    }
  }

  /// Build text complexity level selector
  Widget _buildComplexitySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label for the selector
        Row(
          children: [
            Icon(Icons.tune_rounded, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              'Chọn mức độ văn bản:',
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Complexity selector - always full width
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.bgSecondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderPrimary, width: 1.5),
          ),
          child: Row(
            children: TextComplexityLevel.values.map((level) {
              final isSelected = _textComplexity == level;
              final levelColor = level == TextComplexityLevel.simple 
                  ? AppColors.successNeon 
                  : level == TextComplexityLevel.detailed 
                      ? AppColors.cyanNeon 
                      : AppColors.orangeNeon;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _textComplexity = level);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? levelColor.withOpacity(0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? levelColor : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _getComplexityIcon(level),
                          size: 20,
                          color: isSelected ? levelColor : AppColors.textTertiary,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getComplexityLabel(level),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? levelColor : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  IconData _getComplexityIcon(TextComplexityLevel level) {
    switch (level) {
      case TextComplexityLevel.simple:
        return Icons.flash_on_rounded;
      case TextComplexityLevel.detailed:
        return Icons.menu_book_rounded;
      case TextComplexityLevel.comprehensive:
        return Icons.school_rounded;
    }
  }

  String _getComplexityLabel(TextComplexityLevel level) {
    switch (level) {
      case TextComplexityLevel.simple:
        return 'Đơn giản';
      case TextComplexityLevel.detailed:
        return 'Chi tiết';
      case TextComplexityLevel.comprehensive:
        return 'Chuyên sâu';
    }
  }

  /// Get text content based on selected complexity level
  String? _getTextForComplexity() {
    final textVariants = _contentData?['textVariants'] as Map<String, dynamic>?;
    
    print('🔍 _getTextForComplexity called, level: $_textComplexity');
    print('   textVariants: $textVariants');
    
    if (textVariants != null) {
      String? result;
      switch (_textComplexity) {
        case TextComplexityLevel.simple:
          result = textVariants['simple'] as String?;
          break;
        case TextComplexityLevel.detailed:
          result = textVariants['detailed'] as String?;
          break;
        case TextComplexityLevel.comprehensive:
          result = textVariants['comprehensive'] as String?;
          break;
      }
      
      // If result is empty or null, fallback to content
      if (result != null && result.trim().isNotEmpty) {
        print('   Using textVariant: ${result.substring(0, result.length.clamp(0, 50))}...');
        return result;
      }
      
      print('   TextVariant is empty, falling back to content');
    }
    
    // Fallback to original content
    final content = _contentData?['content'] as String?;
    print('   Fallback to content: ${content?.substring(0, (content?.length ?? 0).clamp(0, 50))}...');
    return content;
  }

  /// Check if text variants are available
  bool get _hasTextVariants {
    final textVariants = _contentData?['textVariants'] as Map<String, dynamic>?;
    return textVariants != null && 
           (textVariants['simple'] != null || textVariants['comprehensive'] != null);
  }

  /// Build text content section
  Widget _buildTextContent() {
    final type = _contentData?['type'] as String?;
    final isTextContent = type == 'concept' || type == 'example';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show complexity selector only for concept/example content
        if (isTextContent) ...[
          _buildComplexitySelector(),
          if (!_hasTextVariants)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.infoNeon.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.infoNeon.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.infoNeon),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Nội dung này chỉ có 1 phiên bản. Phiên bản khác sẽ được tạo tự động.',
                      style: AppTextStyles.caption.copyWith(color: AppColors.infoNeon),
                    ),
                  ),
                ],
              ),
            ),
        ],
        
        // Content based on selected complexity (or original if no variants)
        // Priority: textVariants > richContent > content
        Builder(builder: (context) {
          // Check if textVariants has content for selected level
          final textVariants = _contentData!['textVariants'] as Map<String, dynamic>?;
          String? variantText;
          
          if (textVariants != null) {
            switch (_textComplexity) {
              case TextComplexityLevel.simple:
                variantText = textVariants['simple'] as String?;
                break;
              case TextComplexityLevel.detailed:
                variantText = textVariants['detailed'] as String?;
                break;
              case TextComplexityLevel.comprehensive:
                variantText = textVariants['comprehensive'] as String?;
                break;
            }
          }
          
          // If textVariant has content, use it
          if (variantText != null && variantText.trim().isNotEmpty) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderPrimary),
              ),
              child: Text(
                variantText,
                style: AppTextStyles.bodyMedium.copyWith(
                  height: 1.6,
                  color: AppColors.textPrimary,
                ),
              ),
            );
          }
          
          // Fallback to richContent
          if (_contentData!['richContent'] != null) {
            return _buildRichContent(_contentData!['richContent']);
          }
          
          // Fallback to plain content
          final content = _contentData!['content'] as String?;
          if (content != null && content.isNotEmpty) {
            return Text(
              content,
              style: AppTextStyles.bodyMedium.copyWith(
                height: 1.6,
                color: AppColors.textPrimary,
              ),
            );
          }
          
          return const SizedBox.shrink();
        }),
      ],
    );
  }

  /// Check if image is a placeholder
  bool _isPlaceholderImage(String? url) {
    if (url == null) return false;
    return url.contains('placehold.co');
  }

  /// Check if video is a placeholder
  bool _isPlaceholderVideo(String? url) {
    if (url == null) return false;
    return url.contains('BigBuckBunny') || url.contains('sample');
  }

  /// Build placeholder notice banner with contribution guide
  /// Only shown for contributors and admins
  Widget _buildPlaceholderNotice({required String type}) {
    if (!_canEdit) return const SizedBox.shrink();
    final isVideo = type == 'video';
    final media = _contentData?['media'];
    
    // Get AI-generated prompts/scripts for contribution guide
    final imagePrompt = media?['imagePrompt'] as String?;
    final videoScript = media?['videoScript'] as String?;
    final contributionGuide = isVideo ? videoScript : imagePrompt;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade100,
            Colors.amber.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade300, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade400,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isVideo ? Icons.videocam_off : Icons.image_not_supported,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isVideo ? '📹 Video mặc định' : '🖼️ Hình ảnh mặc định',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Nội dung này chưa có ${isVideo ? "video" : "hình ảnh"} thật.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // CTA box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.volunteer_activism, color: Colors.green.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Hãy đóng góp ${isVideo ? "video" : "hình ảnh"} để phát triển môn học trong cộng đồng!',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Contribution Guide - show AI-generated prompt/script
          if (contributionGuide != null && contributionGuide.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isVideo ? Icons.description : Icons.brush,
                        size: 18,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isVideo ? '📝 Gợi ý kịch bản video:' : '🎨 Gợi ý nội dung hình ảnh:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    contributionGuide,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue.shade900,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                context.push('/content/${widget.contentId}/contribute', extra: {
                  'contentData': _contentData,
                  'mediaType': type,
                });
              },
              icon: Icon(isVideo ? Icons.video_call : Icons.add_photo_alternate),
              label: Text('Đóng góp ${isVideo ? "video" : "hình ảnh"} ngay'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build contribution CTA button
  /// Only shown for contributors and admins
  Widget _buildContributionButton({required String type}) {
    if (!_canEdit) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: ElevatedButton.icon(
        onPressed: () {
          // Navigate to contribution screen
          context.push('/content/${widget.contentId}/contribute', extra: {
            'contentData': _contentData,
            'mediaType': type,
          });
        },
        icon: const Icon(Icons.add_photo_alternate),
        label: Text(type == 'image' ? 'Đóng góp hình ảnh' : 'Đóng góp video'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  /// Build zoomable image with tap to fullscreen
  Widget _buildZoomableImage(String imageUrl) {
    return GestureDetector(
      onTap: () => _showFullScreenImage(imageUrl),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              placeholder: (context, url) => Container(
                height: 200,
                color: Colors.grey.shade200,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                height: 200,
                color: Colors.grey.shade200,
                child: const Center(
                  child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                ),
              ),
            ),
          ),
          // Zoom hint overlay
          Positioned(
            right: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.zoom_in, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Nhấn để phóng to',
                    style: TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Show fullscreen image with zoom and pan support
  void _showFullScreenImage(String imageUrl) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        barrierDismissible: true,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: _FullScreenImageViewer(imageUrl: imageUrl),
          );
        },
      ),
    );
  }

  /// Build image content section
  Widget _buildImageContent() {
    final media = _contentData!['media'];
    if (media == null) return const SizedBox.shrink();

    final imageUrls = media['imageUrls'] as List?;
    final imageUrl = media['imageUrl'] as String?;
    final imageDescription = media['imageDescription'] as String?;
    final isPlaceholder = _isPlaceholderImage(imageUrl);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show placeholder notice if this is default image
        if (isPlaceholder) ...[
          _buildPlaceholderNotice(type: 'image'),
        ] else if (imageDescription != null && imageDescription.isNotEmpty) ...[
          // Show normal description for real images
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 20, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    imageDescription,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue.shade800,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        // Image display (only show for real images, not placeholder)
        if (!isPlaceholder) ...[
          if (imageUrls != null && imageUrls.isNotEmpty)
            _buildImageGallery(imageUrls)
          else if (imageUrl != null)
            _buildZoomableImage(_buildFullUrl(imageUrl)),
        ],
      ],
    );
  }

  /// Build video content section
  Widget _buildVideoContent() {
    final media = _contentData!['media'];
    if (media == null) return const SizedBox.shrink();

    final videoUrl = media['videoUrl'] as String?;
    final videoDescription = media['videoDescription'] as String?;
    final videoScript = media['videoScript'] as String?;
    final videoDuration = media['videoDuration'] as String?;
    final isPlaceholder = _isPlaceholderVideo(videoUrl);
    final hasVideoUrl = videoUrl != null && videoUrl.isNotEmpty;
    final hasVideoFormat = (videoScript != null && videoScript.isNotEmpty) ||
                           (videoDescription != null && videoDescription.isNotEmpty);

    // If no video format at all, show nothing
    if (!hasVideoUrl && !hasVideoFormat) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Case 1: No actual video, but has video format (script/description)
        // Show contribution guide with the script
        if (!hasVideoUrl && hasVideoFormat) ...[
          _buildPlaceholderNotice(type: 'video'),
        ]
        // Case 2: Has placeholder video
        else if (hasVideoUrl && isPlaceholder) ...[
          _buildPlaceholderNotice(type: 'video'),
        ]
        // Case 3: Has real video
        else if (hasVideoUrl && !isPlaceholder) ...[
          // Show description for real videos
          if (videoDescription != null && videoDescription.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.videocam_outlined, size: 20, color: Colors.purple.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          videoDescription,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.purple.shade800,
                            height: 1.4,
                          ),
                        ),
                        if (videoDuration != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Thời lượng: $videoDuration',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.purple.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Video player for real videos
          Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
            ),
            child: _VideoPlayerWidget(
              videoUrl: _buildFullUrl(videoUrl),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildConceptView() {
    // Auto-select first available mode if current mode not available
    if (!_availableModes.contains(_displayMode) && _availableModes.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _displayMode = _availableModes.first);
      });
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title with badges
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  _contentData!['title'] ?? 'Concept',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Format, Difficulty, and Rewards badges
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ContentFormatBadge(format: _contentData!['format'] as String?),
              DifficultyBadge(
                  difficulty: _contentData!['difficulty'] as String?),
            ],
          ),
          const SizedBox(height: 12),
          // Rewards display
          RewardsDisplay(
            xp: _contentData!['rewards']?['xp'] as int?,
            coin: _contentData!['rewards']?['coin'] as int?,
          ),
          const SizedBox(height: 16),

          // ✅ Content Mode Switcher - Chuyển đổi giữa Văn bản, Hình ảnh, Video
          _buildContentModeSwitcher(),

          // ✅ Display content based on selected mode
          if (_displayMode == ContentDisplayMode.text)
            _buildTextContent()
          else if (_displayMode == ContentDisplayMode.image)
            _buildImageContent()
          else if (_displayMode == ContentDisplayMode.video)
            _buildVideoContent(),

          const SizedBox(height: 24),
          _buildCompleteButton(),
        ],
      ),
    );
  }

  Widget _buildExampleView() {
    // Auto-select first available mode if current mode not available
    if (!_availableModes.contains(_displayMode) && _availableModes.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _displayMode = _availableModes.first);
      });
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title with badges
          Text(
            _contentData!['title'] ?? 'Example',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          // Format, Difficulty, and Rewards badges
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ContentFormatBadge(format: _contentData!['format'] as String?),
              DifficultyBadge(
                  difficulty: _contentData!['difficulty'] as String?),
            ],
          ),
          const SizedBox(height: 12),
          // Rewards display
          RewardsDisplay(
            xp: _contentData!['rewards']?['xp'] as int?,
            coin: _contentData!['rewards']?['coin'] as int?,
          ),
          const SizedBox(height: 16),
          
          // ✅ Content Mode Switcher - Chuyển đổi giữa Văn bản, Hình ảnh, Video
          _buildContentModeSwitcher(),

          // ✅ Display content based on selected mode
          if (_displayMode == ContentDisplayMode.text)
            _buildExampleTextContent()
          else if (_displayMode == ContentDisplayMode.image)
            _buildImageContent()
          else if (_displayMode == ContentDisplayMode.video)
            _buildVideoContent(),
          
          const SizedBox(height: 24),
          _buildCompleteButton(),
        ],
      ),
    );
  }

  /// Build text content for example view (with code styling)
  Widget _buildExampleTextContent() {
    if (_contentData!['richContent'] != null) {
      return _buildRichContent(_contentData!['richContent']);
    } else if (_contentData!['content'] != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          _contentData!['content'],
          style: const TextStyle(
            fontSize: 14,
            fontFamily: 'monospace',
            color: Colors.white,
            height: 1.5,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildQuizView() {
    final quizData = _contentData!['quizData'] as Map<String, dynamic>?;
    if (quizData == null) {
      return const Center(child: Text('No quiz data available'));
    }

    final question = quizData['question'] as String? ?? '';
    final options = quizData['options'] as List<dynamic>? ?? [];
    final correctAnswer = quizData['correctAnswer'] as int?;
    final explanation = quizData['explanation'] as String?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title with badges
          Text(
            _contentData!['title'] ?? 'Quiz',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          // Format, Difficulty, and Rewards badges
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ContentFormatBadge(format: _contentData!['format'] as String?),
              DifficultyBadge(
                  difficulty: _contentData!['difficulty'] as String?),
            ],
          ),
          const SizedBox(height: 12),
          // Rewards display
          RewardsDisplay(
            xp: _contentData!['rewards']?['xp'] as int?,
            coin: _contentData!['rewards']?['coin'] as int?,
          ),
          const SizedBox(height: 16),
          const SizedBox(height: 24),
          Text(
            question,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          ...List.generate(options.length, (index) {
            final isSelected = _selectedQuizAnswer == index;
            final isCorrect = _showQuizResult && index == correctAnswer;
            final isWrong =
                _showQuizResult && isSelected && index != correctAnswer;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: _showQuizResult
                    ? null
                    : () {
                        setState(() {
                          _selectedQuizAnswer = index;
                        });
                      },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isCorrect
                        ? Colors.green.shade100
                        : isWrong
                            ? Colors.red.shade100
                            : isSelected
                                ? Colors.blue.shade100
                                : Colors.grey.shade100,
                    border: Border.all(
                      color: isCorrect
                          ? Colors.green
                          : isWrong
                              ? Colors.red
                              : isSelected
                                  ? Colors.blue
                                  : Colors.grey.shade300,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCorrect
                              ? Colors.green
                              : isWrong
                                  ? Colors.red
                                  : isSelected
                                      ? Colors.blue
                                      : Colors.transparent,
                          border: Border.all(
                            color: isCorrect
                                ? Colors.green
                                : isWrong
                                    ? Colors.red
                                    : isSelected
                                        ? Colors.blue
                                        : Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: isCorrect
                            ? const Icon(Icons.check,
                                size: 16, color: Colors.white)
                            : isWrong
                                ? const Icon(Icons.close,
                                    size: 16, color: Colors.white)
                                : isSelected
                                    ? const Icon(Icons.check,
                                        size: 16, color: Colors.white)
                                    : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          options[index].toString(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          if (_showQuizResult && explanation != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Giải thích:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(explanation),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (!_showQuizResult)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _selectedQuizAnswer != null ? _submitQuizAnswer : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Submit Answer'),
              ),
            ),
          if (_showQuizResult) ...[
            // Show navigation buttons after quiz is completed
            const SizedBox(height: 24),
            Row(
              children: [
                // Back button
                if (_prevContentItem != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        print('Quiz: Prev button pressed');
                        print('Quiz: _prevContentItem: $_prevContentItem');
                        if (_prevContentItem != null) {
                          final prevId = _prevContentItem!['id'] as String?;
                          print(
                              'Quiz: Navigating to previous content: $prevId');
                          if (prevId != null && prevId.isNotEmpty) {
                            // Use go() to replace current route instead of pushing new one
                            context.go('/content/$prevId');
                          } else {
                            print(
                                'Quiz: Error: prevContentItem id is null or empty');
                          }
                        } else {
                          print('Quiz: Error: _prevContentItem is null');
                        }
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Bài trước'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  )
                else
                  // Show info message if this is the first item
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.grey.shade600, size: 18),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Đây là bài đầu tiên',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_prevContentItem != null && _nextContentItem != null)
                  const SizedBox(width: 12),
                // Next button
                if (_nextContentItem != null)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        print('Quiz: Next button pressed');
                        print('Quiz: _nextContentItem: $_nextContentItem');
                        if (_nextContentItem != null) {
                          final nextId = _nextContentItem!['id'] as String?;
                          print('Quiz: Navigating to next content: $nextId');
                          if (nextId != null && nextId.isNotEmpty) {
                            // Use go() to replace current route instead of pushing new one
                            context.go('/content/$nextId');
                          } else {
                            print(
                                'Quiz: Error: nextContentItem id is null or empty');
                          }
                        } else {
                          print('Quiz: Error: _nextContentItem is null');
                        }
                      },
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Bài tiếp theo'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.blue,
                      ),
                    ),
                  )
                else
                  // Show info message if this is the last item
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.grey.shade600, size: 18),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Đây là bài cuối cùng',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Back to node button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  // Always navigate directly to node detail screen
                  final nodeId = _contentData?['nodeId'] as String?;
                  if (nodeId != null) {
                    context.go('/nodes/$nodeId');
                  } else {
                    // Fallback: try to pop or go to dashboard
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/dashboard');
                    }
                  }
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Quay lại Node'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRewardView() {
    final rewards = _contentData!['rewards'] as Map<String, dynamic>?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.star,
            size: 80,
            color: Colors.amber,
          ),
          const SizedBox(height: 24),
          Text(
            _contentData!['title'] ?? 'Hidden Reward',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          if (rewards != null) ...[
            if (rewards['xp'] != null)
              _RewardItem(
                icon: Icons.star,
                label: 'XP',
                value: '+${rewards['xp']}',
                color: Colors.amber,
              ),
            if (rewards['coin'] != null)
              _RewardItem(
                icon: Icons.monetization_on,
                label: 'Coins',
                value: '+${rewards['coin']}',
                color: Colors.orange,
              ),
            if (rewards['shard'] != null)
              _RewardItem(
                icon: Icons.diamond,
                label: 'Shard',
                value: '${rewards['shard']} x${rewards['shardAmount'] ?? 1}',
                color: Colors.purple,
              ),
          ],
          const SizedBox(height: 24),
          _buildCompleteButton(),
        ],
      ),
    );
  }

  Widget _buildDefaultView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title with badges
          Text(
            _contentData!['title'] ?? 'Content',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          // Format, Difficulty, and Rewards badges
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ContentFormatBadge(format: _contentData!['format'] as String?),
              DifficultyBadge(
                  difficulty: _contentData!['difficulty'] as String?),
            ],
          ),
          const SizedBox(height: 12),
          // Rewards display
          RewardsDisplay(
            xp: _contentData!['rewards']?['xp'] as int?,
            coin: _contentData!['rewards']?['coin'] as int?,
          ),
          const SizedBox(height: 16),
          if (_contentData!['content'] != null) Text(_contentData!['content']),
          const SizedBox(height: 24),
          _buildCompleteButton(),
        ],
      ),
    );
  }

  Widget _buildCompleteButton() {
    if (_isCompleted) {
      // Show navigation buttons after completion
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Đã hoàn thành! 🎉',
                    style: TextStyle(
                      color: Colors.green.shade900,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Back button
              if (_prevContentItem != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      print('Prev button pressed');
                      print('_prevContentItem: $_prevContentItem');
                      if (_prevContentItem != null) {
                        final prevId = _prevContentItem!['id'] as String?;
                        print('Navigating to previous content: $prevId');
                        if (prevId != null && prevId.isNotEmpty) {
                          // Use go() to replace current route instead of pushing new one
                          context.go('/content/$prevId');
                        } else {
                          print('Error: prevContentItem id is null or empty');
                        }
                      } else {
                        print('Error: _prevContentItem is null');
                      }
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Bài trước'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                )
              else
                // Show info message if this is the first item
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.grey.shade600, size: 20),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Đây là bài đầu tiên',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_prevContentItem != null && _nextContentItem != null)
                const SizedBox(width: 12),
              // Next button
              if (_nextContentItem != null)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      print('Next button pressed');
                      print('_nextContentItem: $_nextContentItem');
                      if (_nextContentItem != null) {
                        final nextId = _nextContentItem!['id'] as String?;
                        print('Navigating to next content: $nextId');
                        if (nextId != null && nextId.isNotEmpty) {
                          // Use go() to replace current route instead of pushing new one
                          context.go('/content/$nextId');
                        } else {
                          print('Error: nextContentItem id is null or empty');
                        }
                      } else {
                        print('Error: _nextContentItem is null');
                      }
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Bài tiếp theo'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue,
                    ),
                  ),
                )
              else
                // Show info message if this is the last item
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.grey.shade600, size: 20),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Đây là bài cuối cùng',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Back to node button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                // Always navigate directly to node detail screen
                final nodeId = _contentData?['nodeId'] as String?;
                if (nodeId != null) {
                  context.go('/nodes/$nodeId');
                } else {
                  // Fallback: try to pop or go to dashboard
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/dashboard');
                  }
                }
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Quay lại Node'),
            ),
          ),
        ],
      );
    }

    // Check content type - concept/example requires quiz, others can mark complete directly
    final contentType = _contentData?['type'] as String?;
    final isQuizRequired = contentType == 'concept' || contentType == 'example';

    if (isQuizRequired) {
      // Show "Làm bài kiểm tra" button for concept/example
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _openQuiz,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: contentType == 'concept' ? Colors.blue : Colors.teal,
          ),
          icon: const Icon(Icons.quiz, color: Colors.white),
          label: Text(
            'Làm bài kiểm tra (${contentType == 'concept' ? '5 câu' : '7 câu'})',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    // For other content types (hidden_reward, boss_quiz), allow direct completion
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isCompleting ? null : () => _markComplete(),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.green,
        ),
        child: _isCompleting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Hoàn thành',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  /// Open quiz screen for concept/example content
  /// Quiz bài học bình thường KHÔNG cần kiểm tra tiến độ
  /// Chỉ Boss Quiz mới cần hoàn thành ít nhất 1 mức độ
  Future<void> _openQuiz() async {
    final contentType = _contentData?['type'] as String?;
    final contentTitle = _contentData?['title'] as String? ?? '';
    final nodeId = _contentData?['nodeId'] as String? ?? '';

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => QuizScreen(
          contentItemId: widget.contentId,
          contentTitle: contentTitle,
          contentType: contentType ?? 'concept',
          nodeId: nodeId,
          onComplete: (passed) {
            if (passed) {
              // Auto mark complete when quiz is passed
              _markComplete(score: 100);
            }
          },
        ),
      ),
    );

    // If quiz was passed (returned true), the onComplete callback already marked it complete
    if (result == true) {
      // Refresh to show completed state
      _loadContent();
    }
  }

  Widget _buildRichContent(dynamic richContent) {
    try {
      final quillController = quill.QuillController.basic();
      if (richContent is List) {
        final delta = Delta.fromJson(richContent);
        quillController.document = quill.Document.fromDelta(delta);
      } else if (richContent is Map) {
        final delta = Delta.fromJson([richContent]);
        quillController.document = quill.Document.fromDelta(delta);
      } else {
        quillController.document = quill.Document()
          ..insert(0, richContent.toString());
      }
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: IgnorePointer(
          child: quill.QuillEditor.basic(
            configurations: quill.QuillEditorConfigurations(
              controller: quillController,
              sharedConfigurations: const quill.QuillSharedConfigurations(),
            ),
          ),
        ),
      );
    } catch (e) {
      return Text(
        richContent.toString(),
        style: const TextStyle(fontSize: 16, height: 1.5),
      );
    }
  }

  Widget _buildImageGallery(List<dynamic> imageUrls) {
    // Use GridView like in preview (2 columns)
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 4 / 3,
      ),
      itemCount: imageUrls.length,
      itemBuilder: (context, index) {
        final fullUrl = _buildFullUrl(imageUrls[index].toString());
        return GestureDetector(
          onTap: () => _showFullScreenImage(fullUrl),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: fullUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey.shade200,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.error),
                  ),
                ),
              ),
              // Zoom icon overlay
              Positioned(
                right: 4,
                bottom: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.zoom_in, color: Colors.white, size: 14),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

}

class _VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final bool isLocalFile;

  const _VideoPlayerWidget({
    required this.videoUrl,
    this.isLocalFile = false,
  });

  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _useHtmlPlayer = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void didUpdateWidget(_VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reinitialize if video URL changed
    if (oldWidget.videoUrl != widget.videoUrl) {
      _controller?.dispose();
      _isInitialized = false;
      _hasError = false;
      _errorMessage = null;
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    // On desktop/web, skip video_player and use WebVideoPlayer directly
    final isDesktopOrWeb = kIsWeb ||
        (!kIsWeb &&
            (Platform.isWindows || Platform.isLinux || Platform.isMacOS));

    if (isDesktopOrWeb && !widget.isLocalFile) {
      // For network videos on desktop/web, use WebVideoPlayer directly
      // Set _useHtmlPlayer to true so build() will use WebVideoPlayer
      if (mounted) {
        setState(() {
          _useHtmlPlayer = true;
          _isInitialized = true;
          _hasError = false;
        });
      }
      return;
    }

    try {
      VideoPlayerController controller;
      if (widget.isLocalFile) {
        // Check if file exists
        final file = File(widget.videoUrl);
        if (!await file.exists()) {
          throw Exception('File không tồn tại: ${widget.videoUrl}');
        }

        // Check file size to ensure it's readable
        final fileSize = await file.length();
        if (fileSize == 0) {
          throw Exception('File rỗng hoặc không thể đọc được');
        }

        controller = VideoPlayerController.file(file);

        // Set error handler
        controller.addListener(() {
          if (controller.value.hasError) {
            if (mounted) {
              setState(() {
                _hasError = true;
                _errorMessage =
                    controller.value.errorDescription ?? 'Lỗi không xác định';
              });
            }
          }
        });
      } else {
        // Video URL should already be full URL from parent widget
        controller =
            VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      }

      // Initialize with timeout
      await controller.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception(
              'Timeout khi khởi tạo video. Video có thể quá lớn hoặc không hỗ trợ định dạng này.');
        },
      );

      if (mounted) {
        setState(() {
          _controller = controller;
          _isInitialized = true;
          _hasError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        // On desktop/web, try WebVideoPlayer as fallback
        if (isDesktopOrWeb && !widget.isLocalFile) {
          setState(() {
            _useHtmlPlayer = true;
            _isInitialized = true;
            _hasError = false;
          });
        } else {
          setState(() {
            _hasError = true;
            _errorMessage = e.toString();
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // On web/desktop, try WebVideoPlayer first if video_player fails
    final isDesktopOrWeb = kIsWeb ||
        (!kIsWeb &&
            (Platform.isWindows || Platform.isLinux || Platform.isMacOS));

    if (_hasError) {
      // Check for UnimplementedError - check both error message and error type
      final errorMsg = _errorMessage?.toLowerCase() ?? '';
      if (errorMsg.contains('unimplemented') ||
          errorMsg.contains('not implemented')) {
        // Try HTML video player for web/desktop
        if (isDesktopOrWeb) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: WebVideoPlayer(
              videoUrl: widget.videoUrl,
              height: 200,
            ),
          );
        }
        // For mobile, try opening in external browser
        return Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.play_circle_fill, size: 48, color: Colors.white),
              const SizedBox(height: 12),
              const Text(
                'Video không thể phát trong ứng dụng',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () async {
                  final url = Uri.parse(widget.videoUrl);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Mở trong trình duyệt'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      }
      // Other errors - try WebVideoPlayer as fallback on desktop/web
      if (isDesktopOrWeb) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: WebVideoPlayer(
            videoUrl: widget.videoUrl,
            height: 200,
          ),
        );
      }
      // Show error for mobile
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey.shade600),
              const SizedBox(height: 8),
              Text(
                'Lỗi khi tải video',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Use HTML5 video player if set (for desktop/web)
    if (_useHtmlPlayer) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: WebVideoPlayer(
          videoUrl: widget.videoUrl,
          height: 200,
        ),
      );
    }

    if (!_isInitialized || _controller == null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: _controller!.value.aspectRatio,
      child: VideoPlayer(_controller!),
    );
  }
}

class _RewardItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _RewardItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Full screen image viewer with zoom and pan support
class _FullScreenImageViewer extends StatefulWidget {
  final String imageUrl;

  const _FullScreenImageViewer({required this.imageUrl});

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  final TransformationController _transformationController =
      TransformationController();
  bool _isZoomed = false;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    if (_isZoomed) {
      // Reset zoom
      _transformationController.value = Matrix4.identity();
      _isZoomed = false;
    } else {
      // Zoom to 2x
      _transformationController.value = Matrix4.identity()..scale(2.0);
      _isZoomed = true;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Dismissible image
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            onDoubleTap: _handleDoubleTap,
            child: Center(
              child: InteractiveViewer(
                transformationController: _transformationController,
                minScale: 0.5,
                maxScale: 4.0,
                onInteractionEnd: (details) {
                  _isZoomed =
                      _transformationController.value.getMaxScaleOnAxis() > 1.1;
                },
                child: CachedNetworkImage(
                  imageUrl: widget.imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  errorWidget: (context, url, error) => const Center(
                    child: Icon(Icons.broken_image, size: 64, color: Colors.white54),
                  ),
                ),
              ),
            ),
          ),

          // Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 24),
              ),
            ),
          ),

          // Zoom hint
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _isZoomed
                      ? 'Nhấn đúp để thu nhỏ • Vuốt để di chuyển'
                      : 'Nhấn đúp để phóng to • Chụm để zoom',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
