import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/core/config/api_config.dart';
import 'package:intl/intl.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:edtech_mobile/features/content/widgets/web_video_player.dart';

class ContentVersionHistoryScreen extends StatefulWidget {
  final String contentItemId;
  final bool isAdmin;

  const ContentVersionHistoryScreen({
    super.key,
    required this.contentItemId,
    this.isAdmin = false,
  });

  @override
  State<ContentVersionHistoryScreen> createState() =>
      _ContentVersionHistoryScreenState();
}

class _ContentVersionHistoryScreenState
    extends State<ContentVersionHistoryScreen> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _versions = [];

  @override
  void initState() {
    super.initState();
    _loadVersions();
  }

  Future<void> _loadVersions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      List<dynamic> versions;

      if (widget.isAdmin) {
        versions = await apiService.getVersionsForContent(widget.contentItemId);
      } else {
        versions =
            await apiService.getMyVersionsForContent(widget.contentItemId);
      }

      setState(() {
        _versions = versions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _revertToVersion(String versionId) async {
    if (!widget.isAdmin) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận revert'),
        content: const Text(
          'Bạn có chắc chắn muốn revert về phiên bản này? Các phiên bản mới hơn sẽ bị gỡ và người dùng sẽ được thông báo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Revert'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.revertToVersion(versionId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã revert về phiên bản thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadVersions();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  Future<void> _setAsCurrentVersion(Map<String, dynamic> version) async {
    if (!widget.isAdmin) return;

    final versionId = version['id'] as String?;
    final versionNumber = version['versionNumber'] as int? ?? 0;
    
    if (versionId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận lấy làm bản chính'),
        content: Text(
          'Bạn có chắc chắn muốn đặt phiên bản $versionNumber làm bản chính? '
          'Các phiên bản mới hơn sẽ bị gỡ và người dùng sẽ được thông báo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.revertToVersion(versionId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã đặt phiên bản $versionNumber làm bản chính thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadVersions();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  void _showVersionPreview(Map<String, dynamic> version) {
    final snapshot = version['contentSnapshot'] as Map<String, dynamic>?;
    if (snapshot == null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 800),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.history, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Phiên bản ${version['versionNumber']}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              // Preview content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _buildVersionPreviewContent(snapshot),
                ),
              ),
              // Actions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: widget.isAdmin
                    ? Row(
                        // Chỉ hiển thị nút "Lấy làm bản chính" cho admin
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!(version['isCurrent'] as bool? ?? false))
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _setAsCurrentVersion(version);
                              },
                              icon: const Icon(Icons.star),
                              label: const Text('Lấy làm bản chính'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green.shade700),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Đây là bản chính hiện tại',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      )
                    : Row(
                        // Cho user: chỉ hiển thị nút "Chuyển tới phần chỉnh sửa"
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _navigateToEdit(version);
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text('Chuyển tới phần chỉnh sửa'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVersionPreviewContent(Map<String, dynamic> snapshot) {
    final title = snapshot['title'] ?? 'N/A';
    final richContent = snapshot['richContent'];
    final content = snapshot['content'] as String?;
    final media = snapshot['media'] as Map<String, dynamic>?;
    final imageUrls = media?['imageUrls'] as List<dynamic>?;
    final videoUrl = media?['videoUrl'] as String?;
    final quizData = snapshot['quizData'] as Map<String, dynamic>?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Quiz or Rich content
        if (quizData != null) ...[
          // Quiz preview
          Text(
            quizData['question'] ?? 'Câu hỏi quiz',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          ...List.generate(
            (quizData['options'] as List<dynamic>?)?.length ?? 0,
            (index) {
              final options = quizData['options'] as List<dynamic>? ?? [];
              if (index >= options.length) return const SizedBox.shrink();
              final optionText = options[index].toString();
              final isCorrect = index == (quizData['correctAnswer'] as int?);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isCorrect ? Colors.green.shade100 : Colors.grey.shade100,
                    border: Border.all(
                      color: isCorrect ? Colors.green : Colors.grey.shade300,
                      width: isCorrect ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isCorrect ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: isCorrect ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          optionText,
                          style: TextStyle(
                            fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (isCorrect)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Đúng',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          if (quizData['explanation'] != null && (quizData['explanation'] as String).isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Giải thích:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(quizData['explanation']),
                ],
              ),
            ),
          ],
        ] else if (richContent != null) ...[
          // Rich content preview
          _buildRichContentPreview(richContent),
        ] else if (content != null) ...[
          // Plain text content
          Text(
            content,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
        ],
        const SizedBox(height: 16),

        // Images
        if (imageUrls != null && imageUrls.isNotEmpty) ...[
          const Text(
            'Hình ảnh minh họa',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          GridView.builder(
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
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: _buildFullUrl(imageUrls[index].toString()),
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
              );
            },
          ),
          const SizedBox(height: 16),
        ],

        // Video
        if (videoUrl != null && videoUrl.toString().isNotEmpty) ...[
          const Text(
            'Video hướng dẫn',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 200,
              child: WebVideoPlayer(
                videoUrl: _buildFullUrl(videoUrl.toString()),
                height: 200,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRichContentPreview(dynamic richContent) {
    try {
      final quillController = quill.QuillController.basic();
      if (richContent is List) {
        final delta = Delta.fromJson(richContent);
        quillController.document = quill.Document.fromDelta(delta);
      } else if (richContent is Map) {
        final delta = Delta.fromJson([richContent]);
        quillController.document = quill.Document.fromDelta(delta);
      } else {
        quillController.document = quill.Document()..insert(0, richContent.toString());
      }
      return IgnorePointer(
        child: quill.QuillEditor.basic(
          configurations: quill.QuillEditorConfigurations(
            controller: quillController,
            sharedConfigurations: const quill.QuillSharedConfigurations(),
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

  String _buildFullUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    final baseUrl = ApiConfig.baseUrl.replaceAll('/api/v1', '');
    return '$baseUrl$url';
  }

  Future<void> _navigateToEdit(Map<String, dynamic> version) async {
    final snapshot = version['contentSnapshot'] as Map<String, dynamic>?;
    if (snapshot == null) return;

    // Fetch current content data to use as original for comparison
    Map<String, dynamic>? originalData;
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      originalData = await apiService.getContentDetail(widget.contentItemId);
    } catch (e) {
      // If fetch fails, continue without originalData
      print('Failed to fetch current content: $e');
    }

    // Convert version snapshot to format that EditLessonScreen expects
    final editData = {
      'title': snapshot['title'] ?? '',
      'content': snapshot['content'] ?? '',
      'richContent': snapshot['richContent'],
      'quizData': snapshot['quizData'],
      'format': snapshot['format'],
      'media': snapshot['media'] ?? {},
    };

    // Navigate to edit screen with version data and original data
    if (!mounted) return;
    
    // Use a custom route to pass both initialData and originalData
    // Since we can only pass one extra, we'll combine them
    final combinedData = {
      'initialData': editData,
      'originalData': originalData,
    };
    
    context.push(
      '/content/${widget.contentItemId}/edit',
      extra: combinedData,
    ).then((result) {
      // Reload versions if edit was submitted
      if (result == true && mounted) {
        _loadVersions();
      }
    });
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isAdmin ? 'Lịch sử phiên bản' : 'Phiên bản của tôi'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Lỗi: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadVersions,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : _versions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            widget.isAdmin
                                ? 'Chưa có phiên bản nào'
                                : 'Bạn chưa có phiên bản nào được duyệt',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadVersions,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _versions.length,
                        itemBuilder: (context, index) {
                          final version = _versions[index];
                          return _buildVersionCard(version);
                        },
                      ),
                    ),
    );
  }

  Widget _buildVersionCard(Map<String, dynamic> version) {
    final versionNumber = version['versionNumber'] as int? ?? 0;
    final isCurrent = version['isCurrent'] as bool? ?? false;
    final createdAt = version['createdAt'] as String?;
    final createdBy = version['createdBy'] as Map<String, dynamic>?;
    final createdByName =
        createdBy?['fullName'] ?? createdBy?['email'] ?? 'Người dùng';
    final description = version['description'] as String? ?? '';
    final snapshot = version['contentSnapshot'] as Map<String, dynamic>?;
    final title = snapshot?['title'] ?? 'N/A';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isCurrent ? 4 : 1,
      color: isCurrent ? Colors.green.shade50 : null,
      child: InkWell(
        onTap: () => _showVersionPreview(version),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isCurrent ? Colors.green : Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'V${versionNumber}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (isCurrent) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Hiện tại',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (widget.isAdmin && !isCurrent)
                    IconButton(
                      icon: const Icon(Icons.restore, color: Colors.orange),
                      onPressed: () => _revertToVersion(version['id']),
                      tooltip: 'Revert về phiên bản này',
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (description.isNotEmpty) ...[
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
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    createdByName,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

