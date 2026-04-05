import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/core/widgets/error_widget.dart';
import 'package:edtech_mobile/core/widgets/skeleton_loader.dart';
import 'package:edtech_mobile/theme/theme.dart';
import 'package:intl/intl.dart';

class JourneyLogScreen extends StatefulWidget {
  const JourneyLogScreen({super.key});

  @override
  State<JourneyLogScreen> createState() => _JourneyLogScreenState();
}

class _JourneyLogScreenState extends State<JourneyLogScreen> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final history = await apiService.getMyPendingContributions();

      setState(() {
        _history = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(
          'Nhật ký hành trình',
          style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: _isLoading
          ? _buildLoading()
          : _error != null
              ? AppErrorWidget(
                  message: _error!,
                  onRetry: _loadHistory,
                )
              : _history.isEmpty
                  ? Center(
                      child: Text(
                        'Chưa có hoạt động nào được ghi lại',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadHistory,
                      color: AppColors.primaryLight,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _history.length,
                        itemBuilder: (context, index) {
                          final item = _history[index] as Map<String, dynamic>;
                          return _buildHistoryItem(item);
                        },
                      ),
                    ),
    );
  }

  Widget _buildLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: SkeletonCard(height: 100),
        );
      },
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> item) {
    final action = item['action'] as String? ?? 'unknown';
    final createdAt = item['createdAt'] as String?;
    final details = item['description'] as String? ?? '';
    final contentItem = item['contentItem'] as Map<String, dynamic>? ?? {};
    final contentTitle =
        contentItem['title'] as String? ?? 'Bài học chưa đặt tên';
    final user = item['user'] as Map<String, dynamic>? ?? {};
    final performerName = user['fullName'] ?? user['email'];

    String dateStr = '';
    if (createdAt != null) {
      try {
        final date = DateTime.parse(createdAt).toLocal();
        dateStr = DateFormat('dd/MM/yyyy HH:mm').format(date);
      } catch (e) {
        dateStr = createdAt;
      }
    }

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (action) {
      case 'approve':
        statusColor = AppColors.successNeon;
        statusText = 'Đã duyệt';
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'reject':
        statusColor = AppColors.errorNeon;
        statusText = 'Từ chối';
        statusIcon = Icons.cancel_rounded;
        break;
      case 'submit':
        statusColor = AppColors.primaryLight;
        statusText = 'Đã gửi';
        statusIcon = Icons.send_rounded;
        break;
      case 'create':
        statusColor = AppColors.purpleNeon;
        statusText = 'Tạo mới';
        statusIcon = Icons.add_circle_rounded;
        break;
      case 'update':
        statusColor = AppColors.orangeNeon;
        statusText = 'Cập nhật';
        statusIcon = Icons.edit_rounded;
        break;
      case 'remove':
        statusColor = AppColors.errorNeon;
        statusText = 'Đã gỡ';
        statusIcon = Icons.delete_rounded;
        break;
      default:
        statusColor = AppColors.textSecondary;
        statusText = 'Hoạt động';
        statusIcon = Icons.info_rounded;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x332D363D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: statusColor.withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                dateStr,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            details,
            style:
                AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Bài học: $contentTitle',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
          if (performerName != null &&
              (action == 'approve' || action == 'reject')) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.admin_panel_settings_rounded,
                    size: 14, color: AppColors.primaryLight),
                const SizedBox(width: 4),
                Text(
                  'Xử lý bởi: Admin',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primaryLight,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
