import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/core/widgets/error_widget.dart';
import 'package:edtech_mobile/theme/theme.dart';

class MyPendingContributionsScreen extends StatefulWidget {
  const MyPendingContributionsScreen({super.key});

  @override
  State<MyPendingContributionsScreen> createState() =>
      _MyPendingContributionsScreenState();
}

class _MyPendingContributionsScreenState
    extends State<MyPendingContributionsScreen> {
  List<dynamic> _contributions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadContributions();
  }

  Future<void> _loadContributions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final data = await apiService.getMyPendingContributions();
      setState(() {
        _contributions = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteContribution(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.contributorBgSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Xóa đóng góp', style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary)),
        content: Text(
          'Bạn có chắc muốn xóa đóng góp này?',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Xóa', style: TextStyle(color: AppColors.errorNeon)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.deletePendingContribution(id);
      _loadContributions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã xóa đóng góp'),
            backgroundColor: AppColors.contributorBlue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.errorNeon),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.contributorBgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Đóng góp của tôi',
          style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.contributorBlueLight),
            onPressed: () => context.push('/contributor/create-subject'),
            tooltip: 'Tạo môn học mới',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.contributorBlue))
          : _error != null
              ? AppErrorWidget(message: _error!, onRetry: _loadContributions)
              : _contributions.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadContributions,
                      color: AppColors.contributorBlue,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _contributions.length,
                        itemBuilder: (context, index) {
                          final item = _contributions[index] as Map<String, dynamic>;
                          return _buildContributionCard(item);
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/contributor/create-subject'),
        backgroundColor: AppColors.contributorBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Tạo môn học', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.contributorBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.volunteer_activism,
                size: 64,
                color: AppColors.contributorBlue.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Chưa có đóng góp nào',
              style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Bắt đầu đóng góp bằng cách tạo môn học mới!',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContributionCard(Map<String, dynamic> item) {
    final type = item['type'] as String? ?? 'subject';
    final status = item['status'] as String? ?? 'pending';
    final title = item['title'] as String? ?? '';
    final description = item['description'] as String? ?? '';
    final createdAt = item['createdAt'] as String?;
    final reviewNote = item['reviewNote'] as String?;
    final id = item['id'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.contributorBgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getStatusColor(status).withOpacity(0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                _buildTypeBadge(type),
                const SizedBox(width: 8),
                _buildStatusBadge(status),
                const Spacer(),
                if (status == 'pending')
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: AppColors.errorNeon, size: 20),
                    onPressed: () => _deleteContribution(id),
                    tooltip: 'Xóa',
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Title
            Text(
              title,
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),

            // Description
            if (description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                description,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Review note
            if (reviewNote != null && reviewNote.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      status == 'approved' ? Icons.check_circle : Icons.info_outline,
                      size: 16,
                      color: _getStatusColor(status),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Admin: $reviewNote',
                        style: AppTextStyles.caption.copyWith(
                          color: _getStatusColor(status),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Date
            if (createdAt != null) ...[
              const SizedBox(height: 10),
              Text(
                _formatDate(createdAt),
                style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBadge(String type) {
    final config = _typeConfig(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config['color'].withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config['icon'] as IconData, size: 14, color: config['color'] as Color),
          const SizedBox(width: 4),
          Text(
            config['label'] as String,
            style: AppTextStyles.caption.copyWith(
              color: config['color'] as Color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = _getStatusColor(status);
    final label = _getStatusLabel(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Map<String, dynamic> _typeConfig(String type) {
    switch (type) {
      case 'subject':
        return {'icon': Icons.school, 'label': 'Môn học', 'color': AppColors.contributorBlue};
      case 'domain':
        return {'icon': Icons.folder, 'label': 'Domain', 'color': AppColors.cyanNeon};
      case 'topic':
        return {'icon': Icons.topic, 'label': 'Topic', 'color': AppColors.purpleNeon};
      case 'lesson':
        return {'icon': Icons.article, 'label': 'Bài học', 'color': AppColors.successNeon};
      default:
        return {'icon': Icons.help, 'label': type, 'color': AppColors.textSecondary};
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warningNeon;
      case 'approved':
        return AppColors.successNeon;
      case 'rejected':
        return AppColors.errorNeon;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Chờ duyệt';
      case 'approved':
        return 'Đã duyệt';
      case 'rejected':
        return 'Từ chối';
      default:
        return status;
    }
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoDate;
    }
  }
}
