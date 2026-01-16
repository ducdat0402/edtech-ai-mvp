import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/core/widgets/error_widget.dart';
import 'package:edtech_mobile/core/widgets/skeleton_loader.dart';
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
      final history = await apiService.getHistoryForUser();
      
      print('🔍 Journey Log: Loaded ${history.length} history entries');
      for (int i = 0; i < history.length; i++) {
        final item = history[i];
        print('📝 Entry $i: action=${item['action']}, description=${item['description']}, createdAt=${item['createdAt']}');
      }
      
      setState(() {
        _history = history;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Journey Log Error: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhật Ký Hành Trình'),
      ),
      body: _isLoading
          ? _buildLoading()
          : _error != null
              ? AppErrorWidget(
                  message: _error!,
                  onRetry: _loadHistory,
                )
              : _history.isEmpty
                  ? const Center(
                      child: Text('Chưa có hoạt động nào được ghi lại'),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadHistory,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _history.length,
                        itemBuilder: (context, index) {
                          final item = _history[index];
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
    final contentTitle = contentItem['title'] as String? ?? 'Bài học chưa đặt tên';
    final user = item['user'] as Map<String, dynamic>? ?? {};
    final performerName = user['fullName'] ?? user['email'] ?? 'Hệ thống';
    
    // Format date
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
        statusColor = Colors.green;
        statusText = 'Đã duyệt';
        statusIcon = Icons.check_circle;
        break;
      case 'reject':
        statusColor = Colors.red;
        statusText = 'Từ chối';
        statusIcon = Icons.cancel;
        break;
      case 'submit':
        statusColor = Colors.blue;
        statusText = 'Đã gửi';
        statusIcon = Icons.send;
        break;
      case 'create':
        statusColor = Colors.purple;
        statusText = 'Tạo mới';
        statusIcon = Icons.add_circle;
        break;
      case 'update':
        statusColor = Colors.orange;
        statusText = 'Cập nhật';
        statusIcon = Icons.edit;
        break;
      case 'remove':
        statusColor = Colors.red;
        statusText = 'Đã gỡ';
        statusIcon = Icons.delete;
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Hoạt động';
        statusIcon = Icons.info;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  dateStr,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              details,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Bài học: $contentTitle',
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 14,
              ),
            ),
            if (performerName != null && action == 'approve' || action == 'reject') ...[
              const SizedBox(height: 8),
              Row(
                children: [
                   Icon(Icons.admin_panel_settings, size: 14, color: Colors.blue.shade700),
                   const SizedBox(width: 4),
                   Text(
                    'Xử lý bởi: Admin',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
