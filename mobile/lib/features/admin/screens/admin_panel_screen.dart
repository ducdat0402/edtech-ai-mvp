import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/core/config/api_config.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:edtech_mobile/features/content/widgets/web_video_player.dart';
import 'package:edtech_mobile/features/content/widgets/content_format_badge.dart';
import 'package:edtech_mobile/features/content/widgets/difficulty_badge.dart';
import 'package:edtech_mobile/features/admin/widgets/comparison_dialog.dart';
<<<<<<< Updated upstream
=======
import 'package:edtech_mobile/theme/theme.dart';
>>>>>>> Stashed changes
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _pendingEdits = [];
  List<Map<String, dynamic>> _allContentItems = [];
  List<Map<String, dynamic>> _editHistory = [];
  bool _isLoading = true;
  bool _isLoadingContent = false;
  bool _isLoadingHistory = false;
  String? _error;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPendingEdits();
    _loadAllContentItems();
    _loadEditHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPendingEdits() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final edits = await apiService.getPendingContentEdits();
      setState(() {
        _pendingEdits = edits.map((e) => Map<String, dynamic>.from(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAllContentItems() async {
    setState(() {
      _isLoadingContent = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final items = await apiService.getAllContentItemsWithEdits();
      setState(() {
        _allContentItems = items.map((e) => Map<String, dynamic>.from(e)).toList();
        _isLoadingContent = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingContent = false;
      });
    }
  }

  Future<void> _loadEditHistory() async {
    setState(() {
      _isLoadingHistory = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final history = await apiService.getAllHistory();
      setState(() {
        _editHistory = history.map((e) => Map<String, dynamic>.from(e)).toList();
        _isLoadingHistory = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingHistory = false;
      });
    }
  }

  Future<void> _approveEdit(String editId) async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.approveContentEdit(editId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã duyệt đóng góp thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadPendingEdits(); // Reload list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi duyệt: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectEdit(String editId) async {
    // Show confirmation dialog
    final shouldReject = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Từ chối đóng góp'),
        content: const Text('Bạn có chắc chắn muốn từ chối đóng góp này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );

    if (shouldReject == true) {
      try {
        final apiService = Provider.of<ApiService>(context, listen: false);
        await apiService.rejectContentEdit(editId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã từ chối đóng góp'),
              backgroundColor: Colors.orange,
            ),
          );
          _loadPendingEdits(); // Reload list
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi khi từ chối: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgSecondary,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppGradients.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text('Admin Panel', style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.purpleNeon,
          labelColor: AppColors.purpleNeon,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: AppTextStyles.labelMedium,
          tabs: const [
<<<<<<< Updated upstream
            Tab(text: 'Duyệt đóng góp', icon: Icon(Icons.pending_actions)),
            Tab(text: 'Quản lý bài học', icon: Icon(Icons.article)),
            Tab(text: 'Lịch sử', icon: Icon(Icons.history)),
=======
            Tab(text: 'Duyệt đóng góp', icon: Icon(Icons.pending_actions_rounded)),
            Tab(text: 'Quản lý bài học', icon: Icon(Icons.article_rounded)),
            Tab(text: 'Lịch sử', icon: Icon(Icons.history_rounded)),
>>>>>>> Stashed changes
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: () {
              if (_tabController.index == 0) {
                _loadPendingEdits();
              } else if (_tabController.index == 1) {
                _loadAllContentItems();
              } else {
                _loadEditHistory();
              }
            },
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingEditsTab(),
          _buildContentItemsTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildPendingEditsTab() {
    return _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.purpleNeon))
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
                        child: const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.errorNeon),
                      ),
                      const SizedBox(height: 16),
                      Text('Lỗi: $_error', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 16),
                      GamingButton(text: 'Thử lại', onPressed: _loadPendingEdits, icon: Icons.refresh_rounded),
                    ],
                  ),
                )
              : _pendingEdits.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.successNeon.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_circle_outline_rounded, size: 48, color: AppColors.successNeon),
                          ),
                          const SizedBox(height: 16),
                          Text('Không có đóng góp nào cần duyệt', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadPendingEdits,
                      color: AppColors.purpleNeon,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _pendingEdits.length,
                        itemBuilder: (context, index) {
                          final edit = _pendingEdits[index];
                          return StaggeredListItem(
                            index: index,
                            child: _buildEditCard(edit),
                          );
                        },
                      ),
                    );
  }

  Widget _buildContentItemsTab() {
    return _isLoadingContent
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadAllContentItems,
            child: _allContentItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.article_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'Chưa có bài học nào',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _allContentItems.length,
                    itemBuilder: (context, index) {
                      final item = _allContentItems[index];
                      return _buildContentItemCard(item);
                    },
                  ),
          );
  }

  Widget _buildContentItemCard(Map<String, dynamic> item) {
    final title = item['title'] as String? ?? 'N/A';
    final nodeTitle = item['nodeTitle'] as String? ?? 'N/A';
    final editsCount = item['editsCount'] as int? ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: editsCount > 0 ? Colors.green : Colors.grey,
          child: Text('$editsCount', style: const TextStyle(color: Colors.white)),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Node: $nodeTitle'),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                ContentFormatBadge(
                  format: item['format'] as String?,
                  compact: true,
                ),
                DifficultyBadge(
                  difficulty: item['difficulty'] as String?,
                  compact: true,
                ),
              ],
            ),
          ],
        ),
        trailing: editsCount > 0
            ? Chip(
                label: Text('$editsCount đóng góp'),
                backgroundColor: Colors.green.shade50,
              )
            : const Chip(
                label: Text('Chưa có đóng góp'),
                backgroundColor: Colors.grey,
              ),
        children: [
          // Nút xem lịch sử phiên bản
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                final contentId = item['id'] as String?;
                if (contentId != null) {
                  context.push('/content/$contentId/versions?admin=true');
                }
              },
              icon: const Icon(Icons.history),
              label: const Text('Xem lịch sử phiên bản'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showComparisonDialog(String editId) async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final comparison = await apiService.getEditComparison(editId);
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => ComparisonDialog(comparison: comparison),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tải dữ liệu so sánh: $e')),
        );
      }
    }
  }

  Future<void> _removeEdit(String editId) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gỡ bài đóng góp'),
        content: const Text('Bạn có chắc chắn muốn gỡ bài đóng góp này? Hành động này sẽ xóa bài và revert các thay đổi đã áp dụng.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Gỡ bài'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.removeContentEdit(editId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã gỡ bài đóng góp thành công')),
        );
        _loadAllContentItems(); // Reload list
        _loadPendingEdits(); // Also reload pending if on that tab
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi gỡ bài: $e')),
        );
      }
    }
  }

  Widget _buildEditCard(Map<String, dynamic> edit) {
    final type = edit['type'] as String? ?? '';
    final media = edit['media'] as Map<String, dynamic>?;
    final description = edit['description'] as String?;
    final user = edit['user'] as Map<String, dynamic>?;
    final userName = user?['fullName'] as String? ?? user?['email'] as String? ?? 'Người dùng';
    final contentItem = edit['contentItem'] as Map<String, dynamic>?;
    final contentTitle = contentItem?['title'] as String? ?? 'N/A';
    final editId = edit['id'] as String;
    final createdAt = edit['createdAt'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: User info + Content title
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  child: Text(userName[0].toUpperCase()),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bài học: $contentTitle',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (createdAt != null)
                        Text(
                          'Ngày: ${_formatDate(createdAt)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    type == 'add_video'
                        ? 'Video'
                        : type == 'add_image'
                            ? 'Hình ảnh'
                            : 'Text',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Description
            if (description != null && description.isNotEmpty) ...[
              Text(
                'Mô tả: $description',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
            ],
            
            // Media preview
            if (media != null) ...[
              if (media['imageUrl'] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: _getFullUrl(media['imageUrl']),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 200,
                    placeholder: (context, url) => Container(
                      height: 200,
                      color: Colors.grey.shade200,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 200,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.error),
                    ),
                  ),
                ),
              if (media['videoUrl'] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    height: 200,
                    child: _VideoPlayerWidget(
                      videoUrl: _getFullUrl(media['videoUrl']),
                    ),
                  ),
                ),
              if (media['caption'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Chú thích: ${media['caption']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
            
            // Action buttons
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showComparisonDialog(editId),
                    icon: const Icon(Icons.compare_arrows, size: 18),
                    label: const Text('Xem so sánh (Trước/Sau)'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _rejectEdit(editId),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Từ chối'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _approveEdit(editId),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Duyệt'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getFullUrl(String? url) {
    if (url == null || url.isEmpty) {
      print('Admin Panel: Empty URL provided');
      return '';
    }
    // If already a full URL (starts with http:// or https://), return as is
    if (url.startsWith('http://') || url.startsWith('https://')) {
      print('Admin Panel: Full URL already: $url');
      return url;
    }
    // If it's a relative path (starts with /), prepend base URL
    // Extract base URL from ApiConfig (remove /api/v1)
    final baseUrl = ApiConfig.baseUrl.replaceAll('/api/v1', '');
    final fullUrl = '$baseUrl$url';
    print('Admin Panel: Converted URL from "$url" to "$fullUrl"');
    return fullUrl;
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildHistoryTab() {
    return _isLoadingHistory
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadEditHistory,
            child: _editHistory.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'Chưa có lịch sử',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _editHistory.length,
                    itemBuilder: (context, index) {
                      final history = _editHistory[index];
<<<<<<< Updated upstream
                      return _buildHistoryCard(history, index == _editHistory.length - 1);
=======
                      return StaggeredListItem(
                        index: index,
                        child: _buildHistoryCard(history, index == _editHistory.length - 1),
                      );
>>>>>>> Stashed changes
                    },
                  ),
          );
  }

  Widget _buildHistoryCard(Map<String, dynamic> history, bool isLast) {
    final action = history['action'] as String? ?? '';
    final description = history['description'] as String? ?? '';
    final user = history['user'] as Map<String, dynamic>?;
    final userName = user?['fullName'] as String? ?? user?['email'] as String? ?? 'Người dùng';
    final createdAt = history['createdAt'] as String?;
    final contentItem = history['contentItem'] as Map<String, dynamic>?;
    final contentTitle = contentItem?['title'] as String? ?? 'Bài học';

    // Parse date
    DateTime? dateTime;
    if (createdAt != null) {
      try {
        dateTime = DateTime.parse(createdAt);
      } catch (e) {
        // Ignore parse error
      }
    }

    // Get action icon and color
    IconData actionIcon;
    Color actionColor;
    String actionText;

    switch (action) {
      case 'submit':
        actionIcon = Icons.send;
        actionColor = Colors.blue;
        actionText = 'Gửi đóng góp';
        break;
      case 'approve':
        actionIcon = Icons.check_circle;
        actionColor = Colors.green;
        actionText = 'Duyệt';
        break;
      case 'reject':
        actionIcon = Icons.cancel;
        actionColor = Colors.red;
        actionText = 'Từ chối';
        break;
      case 'remove':
        actionIcon = Icons.delete;
        actionColor = Colors.orange;
        actionText = 'Gỡ bài';
        break;
      case 'create':
        actionIcon = Icons.add_circle;
        actionColor = Colors.purple;
        actionText = 'Tạo mới';
        break;
      case 'update':
        actionIcon = Icons.edit;
        actionColor = Colors.blue;
        actionText = 'Cập nhật';
        break;
      default:
        actionIcon = Icons.info;
        actionColor = Colors.grey;
        actionText = action;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline line
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: actionColor.withOpacity(0.1),
                border: Border.all(color: actionColor, width: 2),
              ),
              child: Icon(actionIcon, color: actionColor, size: 20),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: Colors.grey.shade300,
                margin: const EdgeInsets.symmetric(vertical: 4),
              ),
          ],
        ),
        const SizedBox(width: 12),
        // Content
        Expanded(
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              actionText,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: actionColor,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              contentTitle,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (dateTime != null)
                        Text(
                          _formatDateTime(dateTime),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        child: Text(userName[0].toUpperCase(), style: const TextStyle(fontSize: 10)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          userName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Vừa xong';
        }
        return '${difference.inMinutes} phút trước';
      }
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays == 1) {
      return 'Hôm qua';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

class _VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  const _VideoPlayerWidget({
    required this.videoUrl,
  });

  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _useHtmlPlayer = false; // Flag to use WebVideoPlayer/MediaKit

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
      _useHtmlPlayer = false;
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    try {
      // Validate URL
      if (widget.videoUrl.isEmpty || !widget.videoUrl.startsWith('http')) {
        throw Exception('URL video không hợp lệ: ${widget.videoUrl}');
      }

      final controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      
      // Set error handler
      controller.addListener(() {
        if (controller.value.hasError) {
          if (mounted) {
            setState(() {
              _hasError = true;
              _errorMessage = controller.value.errorDescription ?? 'Lỗi không xác định';
            });
          }
        }
      });

      // Initialize with timeout
      await controller.initialize().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Timeout khi tải video. Có thể video quá lớn hoặc server không phản hồi.');
        },
      );

      if (mounted) {
        setState(() {
          _controller = controller;
          _isInitialized = true;
          _hasError = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      print('Error initializing video: $e');
      print('Error type: ${e.runtimeType}');
      print('Video URL: ${widget.videoUrl}');
      if (mounted) {
        final errorStr = e.toString();
        final isUnimplementedError = errorStr.contains('UnimplementedError') || 
                                     errorStr.contains('unimplemented');
        
        print('Is UnimplementedError: $isUnimplementedError');
        
        if (isUnimplementedError) {
          // Network video UnimplementedError - check platform
          print('UnimplementedError detected for network video');
          try {
            // Check if we're on a platform that supports video_player
            final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
            if (isMobile) {
              // On mobile, try to retry with a delay or show error
              print('Mobile platform detected, showing error with retry option');
              setState(() {
                _hasError = true;
                _errorMessage = 'Không thể tải video. Vui lòng thử lại hoặc kiểm tra kết nối mạng.';
              });
            } else {
              // On desktop/web, use fallback player
              print('Desktop/Web platform detected, using fallback player');
              setState(() {
                _hasError = false;
                _useHtmlPlayer = true; // This will trigger WebVideoPlayer or MediaKit player
              });
            }
          } catch (e) {
            // If Platform check fails, assume desktop and use fallback
            print('Platform check failed, using fallback player: $e');
            setState(() {
              _hasError = false;
              _useHtmlPlayer = true;
            });
          }
        } else {
          // Other errors
          setState(() {
            _hasError = true;
            _errorMessage = errorStr.replaceAll('Exception: ', '').replaceAll('UnimplementedError: ', '');
          });
        }
      }
    }
  }

  Widget _buildHtmlVideoPlayer() {
    // Use WebVideoPlayer widget for web/desktop platforms
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: WebVideoPlayer(
        videoUrl: widget.videoUrl,
        height: 200,
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _openVideoInBrowser() async {
    try {
      final uri = Uri.parse(widget.videoUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể mở video trong trình duyệt')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use HTML5/MediaKit video player if video_player doesn't work
    if (_useHtmlPlayer) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _buildHtmlVideoPlayer(),
      );
    }

    if (_hasError) {
      // Check if it's UnimplementedError (platform not supported)
      final isUnimplementedError = _errorMessage != null && 
          (_errorMessage!.toLowerCase().contains('unimplemented') ||
           _errorMessage!.contains('UnimplementedError'));
      
      // Check if it's a mobile platform
      final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
      
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isUnimplementedError ? Icons.video_library_outlined : Icons.error_outline,
                color: Colors.white70,
                size: 48,
              ),
              const SizedBox(height: 8),
              Text(
                isUnimplementedError 
                    ? 'Không thể preview video trên platform này'
                    : 'Không thể tải video',
                style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              if (_errorMessage != null && !isUnimplementedError) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    _errorMessage!.length > 60
                        ? '${_errorMessage!.substring(0, 60)}...'
                        : _errorMessage!,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              // Show video URL and open button for mobile errors or non-UnimplementedError
              if (isUnimplementedError || !isMobile) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.videoUrl,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _openVideoInBrowser,
                        icon: const Icon(Icons.open_in_browser, size: 16),
                        label: const Text('Mở trong trình duyệt'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      if (!isUnimplementedError) ...[
                        const SizedBox(height: 4),
                        TextButton.icon(
                          onPressed: _initializeVideo,
                          icon: const Icon(Icons.refresh, color: Colors.white70, size: 16),
                          label: const Text(
                            'Thử lại',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ] else ...[
                // For mobile non-UnimplementedError, show retry button
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _initializeVideo,
                  icon: const Icon(Icons.refresh, color: Colors.white70, size: 16),
                  label: const Text(
                    'Thử lại',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (!_isInitialized || _controller == null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 8),
              Text(
                'Đang tải video...',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: VideoPlayer(_controller!),
        ),
        Positioned(
          bottom: 8,
          left: 8,
          right: 8,
          child: VideoProgressIndicator(
            _controller!,
            allowScrubbing: true,
            colors: const VideoProgressColors(
              playedColor: Colors.red,
              bufferedColor: Colors.grey,
              backgroundColor: Colors.white24,
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              if (_controller!.value.isPlaying) {
                _controller!.pause();
              } else {
                _controller!.play();
              }
            });
          },
          child: Container(
            color: Colors.transparent,
            child: _controller!.value.isPlaying
                ? const SizedBox.shrink()
                : const Icon(
                    Icons.play_circle_filled,
                    size: 64,
                    color: Colors.white70,
                  ),
          ),
        ),
      ],
    );
  }
}

