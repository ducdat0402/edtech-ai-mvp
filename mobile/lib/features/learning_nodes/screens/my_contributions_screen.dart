import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/core/widgets/app_bar_leading_back_home.dart';
import 'package:edtech_mobile/theme/theme.dart';

/// Màn hình xem lịch sử đóng góp của người dùng
/// Hiển thị tất cả các đóng góp (video, image, text) với trạng thái
class MyContributionsScreen extends StatefulWidget {
  const MyContributionsScreen({super.key});

  @override
  State<MyContributionsScreen> createState() => _MyContributionsScreenState();
}

class _MyContributionsScreenState extends State<MyContributionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _myEdits = [];
  List<dynamic> _myHistory = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = context.read<ApiService>();

      // Load my pending contributions
      final contributions = await apiService.getMyPendingContributions();

      if (mounted) {
        setState(() {
          _myEdits = contributions;
          _myHistory = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Lỗi khi tải dữ liệu: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.colors;
    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const AppBarLeadingBackAndHome(),
        leadingWidth: 112,
        automaticallyImplyLeading: false,
        title: Text('Đóng góp của tôi',
            style: AppTextStyles.h4.copyWith(color: t.textPrimary)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: t.brand,
          indicatorWeight: 3,
          labelColor: t.brand,
          unselectedLabelColor: t.textSecondary,
          labelStyle: AppTextStyles.labelMedium,
          tabs: [
            Tab(
                icon: const Icon(Icons.edit_document),
                text: 'Bài đóng góp (${_myEdits.length})'),
            Tab(
                icon: const Icon(Icons.history),
                text: 'Lịch sử (${_myHistory.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: t.brand))
          : _error != null
              ? _buildErrorState()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildEditsTab(),
                    _buildHistoryTab(),
                  ],
                ),
    );
  }

  Widget _buildErrorState() {
    final t = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: t.error.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child:
                  Icon(Icons.error_outline_rounded, size: 48, color: t.error),
            ),
            const SizedBox(height: 20),
            Text(_error!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: t.textSecondary)),
            const SizedBox(height: 24),
            GamingButton(
                text: 'Thử lại',
                onPressed: _loadData,
                icon: Icons.refresh_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildEditsTab() {
    if (_myEdits.isEmpty) {
      return _buildEmptyState(
        icon: Icons.edit_off_rounded,
        title: 'Chưa có đóng góp nào',
        subtitle:
            'Hãy đóng góp video, hình ảnh hoặc nội dung cho bài học để nhận phần thưởng!',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: context.colors.brand,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myEdits.length,
        itemBuilder: (context, index) {
          final edit = _myEdits[index] as Map<String, dynamic>;
          return StaggeredListItem(
            index: index,
            child: _buildEditCard(edit),
          );
        },
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_myHistory.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history_toggle_off_rounded,
        title: 'Chưa có lịch sử',
        subtitle: 'Lịch sử hoạt động đóng góp của bạn sẽ hiển thị ở đây.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: context.colors.brand,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myHistory.length,
        itemBuilder: (context, index) {
          final entry = _myHistory[index] as Map<String, dynamic>;
          return StaggeredListItem(
            index: index,
            child: _buildHistoryCard(entry),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final t = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: t.card,
                shape: BoxShape.circle,
                border: Border.all(color: t.border),
              ),
              child: Icon(icon, size: 48, color: t.textTertiary),
            ),
            const SizedBox(height: 24),
            Text(title, style: AppTextStyles.h4.copyWith(color: t.textPrimary)),
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: t.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildEditCard(Map<String, dynamic> edit) {
    final t = context.colors;
    final type = edit['type'] as String? ?? 'update_content';
    final status = edit['status'] as String? ?? 'pending';
    final createdAt = edit['createdAt'] as String?;
    final description = edit['description'] as String?;
    final title = edit['title'] as String?;
    final upvotes = edit['upvotes'] as int? ?? 0;
    final downvotes = edit['downvotes'] as int? ?? 0;

    // Get type info
    IconData typeIcon;
    Color typeColor;
    String typeLabel;
    switch (type) {
      case 'add_video':
        typeIcon = Icons.videocam_rounded;
        typeColor = t.brand;
        typeLabel = 'Video';
        break;
      case 'add_image':
        typeIcon = Icons.image_rounded;
        typeColor = t.gold;
        typeLabel = 'Hình ảnh';
        break;
      case 'add_text':
        typeIcon = Icons.text_fields_rounded;
        typeColor = t.success;
        typeLabel = 'Văn bản';
        break;
      default:
        typeIcon = Icons.edit_rounded;
        typeColor = t.brand;
        typeLabel = 'Nội dung';
    }

    // Get status info
    Color statusColor;
    String statusLabel;
    IconData statusIcon;
    switch (status) {
      case 'approved':
        statusColor = t.success;
        statusLabel = 'Đã duyệt';
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'rejected':
        statusColor = t.error;
        statusLabel = 'Bị từ chối';
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusColor = t.warning;
        statusLabel = 'Đang chờ duyệt';
        statusIcon = Icons.hourglass_empty_rounded;
    }

    // Format date
    String formattedDate = '';
    if (createdAt != null) {
      try {
        final date = DateTime.parse(createdAt);
        formattedDate =
            '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      } catch (_) {
        formattedDate = createdAt;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showEditDetails(edit),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    // Type icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(typeIcon, color: typeColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    // Title and type
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title ?? description ?? 'Đóng góp $typeLabel',
                            style: AppTextStyles.labelLarge
                                .copyWith(color: t.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: typeColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  typeLabel,
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: typeColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                formattedDate,
                                style: AppTextStyles.caption
                                    .copyWith(color: t.textTertiary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: Color(0x332D363D), height: 1),
                const SizedBox(height: 8),
                // Status and votes row
                Row(
                  children: [
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: statusColor.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 16, color: statusColor),
                          const SizedBox(width: 6),
                          Text(
                            statusLabel,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Votes
                    Row(
                      children: [
                        Icon(Icons.thumb_up_rounded, size: 16, color: t.success),
                        const SizedBox(width: 4),
                        Text(
                          '$upvotes',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: t.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.thumb_down_rounded, size: 16, color: t.error),
                        const SizedBox(width: 4),
                        Text(
                          '$downvotes',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: t.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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

  Widget _buildHistoryCard(Map<String, dynamic> entry) {
    final t = context.colors;
    final action = entry['action'] as String? ?? 'unknown';
    final description = entry['description'] as String? ?? '';
    final createdAt = entry['createdAt'] as String?;

    // Get action info
    IconData actionIcon;
    Color actionColor;
    switch (action) {
      case 'submit':
        actionIcon = Icons.upload_rounded;
        actionColor = t.brand;
        break;
      case 'approve':
        actionIcon = Icons.check_circle_rounded;
        actionColor = t.success;
        break;
      case 'reject':
        actionIcon = Icons.cancel_rounded;
        actionColor = t.error;
        break;
      case 'remove':
        actionIcon = Icons.delete_rounded;
        actionColor = t.warning;
        break;
      default:
        actionIcon = Icons.info_rounded;
        actionColor = t.textSecondary;
    }

    // Format date
    String formattedDate = '';
    if (createdAt != null) {
      try {
        final date = DateTime.parse(createdAt);
        formattedDate =
            '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      } catch (_) {
        formattedDate = createdAt;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: actionColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(actionIcon, color: actionColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: t.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedDate,
                  style: AppTextStyles.caption
                      .copyWith(color: t.textTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDetails(Map<String, dynamic> edit) {
    final t = context.colors;
    final editId = edit['id'] as String?;
    final type = edit['type'] as String? ?? 'update_content';
    final status = edit['status'] as String? ?? 'pending';
    final createdAt = edit['createdAt'] as String?;
    final description = edit['description'] as String?;
    final title = edit['title'] as String?;
    final media = edit['media'] as Map<String, dynamic>?;
    final contentItem = edit['contentItem'] as Map<String, dynamic>?;
    final upvotes = edit['upvotes'] as int? ?? 0;
    final downvotes = edit['downvotes'] as int? ?? 0;

    // Get type info
    IconData typeIcon;
    Color typeColor;
    String typeLabel;
    switch (type) {
      case 'add_video':
        typeIcon = Icons.videocam_rounded;
        typeColor = t.brand;
        typeLabel = 'Video';
        break;
      case 'add_image':
        typeIcon = Icons.image_rounded;
        typeColor = t.gold;
        typeLabel = 'Hình ảnh';
        break;
      case 'add_text':
        typeIcon = Icons.text_fields_rounded;
        typeColor = t.success;
        typeLabel = 'Văn bản';
        break;
      default:
        typeIcon = Icons.edit_rounded;
        typeColor = t.brand;
        typeLabel = 'Nội dung';
    }

    // Format date
    String formattedDate = '';
    if (createdAt != null) {
      try {
        final date = DateTime.parse(createdAt);
        formattedDate =
            '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      } catch (_) {
        formattedDate = createdAt;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: t.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(typeIcon, color: typeColor, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title ?? 'Đóng góp $typeLabel',
                              style: AppTextStyles.h4
                                  .copyWith(color: t.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formattedDate,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: t.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon:
                            Icon(Icons.close_rounded, color: t.textSecondary),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Color(0x332D363D)),
                  const SizedBox(height: 16),

                  // Content item info
                  if (contentItem != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: t.cardMuted,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: t.border),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.book_rounded, color: t.textTertiary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bài học',
                                  style: AppTextStyles.caption
                                      .copyWith(color: t.textTertiary),
                                ),
                                Text(
                                  contentItem['title']?.toString() ?? 'N/A',
                                  style: AppTextStyles.labelMedium
                                      .copyWith(color: t.textPrimary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Description
                  if (description != null && description.isNotEmpty) ...[
                    Text(
                      'Mô tả',
                      style: AppTextStyles.labelLarge
                          .copyWith(color: t.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: t.textSecondary),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Media preview
                  if (media != null) ...[
                    Text(
                      'Nội dung đóng góp',
                      style: AppTextStyles.labelLarge
                          .copyWith(color: t.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    if (media['videoUrl'] != null)
                      Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.play_circle_fill,
                                  size: 64,
                                  color:
                                      t.textOnBrand.withValues(alpha: 0.8)),
                              const SizedBox(height: 8),
                              Text(
                                'Video đã tải lên',
                                style: TextStyle(
                                  color:
                                      t.textOnBrand.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (media['imageUrl'] != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          media['imageUrl'] as String,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 180,
                            decoration: BoxDecoration(
                              color: t.cardMuted,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.broken_image_rounded,
                                size: 48, color: t.textTertiary),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],

                  // Votes
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: t.cardMuted,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: t.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildVoteStat(Icons.thumb_up_rounded, upvotes, t.success),
                        const SizedBox(width: 32),
                        _buildVoteStat(
                            Icons.thumb_down_rounded, downvotes, t.error),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action buttons
                  if (editId != null && status == 'pending') ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _viewEditHistory(editId);
                        },
                        icon: const Icon(Icons.history),
                        label: const Text('Xem lịch sử chỉnh sửa'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          foregroundColor: t.brand,
                          side: BorderSide(color: t.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVoteStat(IconData icon, int count, Color color) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: AppTextStyles.h4.copyWith(color: color),
        ),
      ],
    );
  }

  void _viewEditHistory(String editId) async {
    final t = context.colors;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          Center(child: CircularProgressIndicator(color: t.brand)),
    );

    try {
      final List<dynamic> history = []; // Old edit history removed

      if (!mounted) return;
      Navigator.pop(context);

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: t.card,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.3,
            maxChildSize: 0.8,
            expand: false,
            builder: (context, scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.history_rounded, color: t.brand),
                        const SizedBox(width: 8),
                        Text(
                          'Lịch sử',
                          style: AppTextStyles.h4
                              .copyWith(color: t.textPrimary),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: t.textSecondary),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(color: Color(0x332D363D)),
                    const SizedBox(height: 12),
                    if (history.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            'Chưa có lịch sử',
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: t.textSecondary),
                          ),
                        ),
                      )
                    else
                      ...history.map((entry) =>
                          _buildHistoryCard(entry as Map<String, dynamic>)),
                  ],
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Lỗi: $e'), backgroundColor: t.error),
        );
      }
    }
  }
}
