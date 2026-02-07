import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/core/widgets/error_widget.dart';
import 'package:edtech_mobile/core/widgets/skeleton_loader.dart';
import 'package:edtech_mobile/theme/theme.dart';

class DomainDetailScreen extends StatefulWidget {
  final String domainId;

  const DomainDetailScreen({
    super.key,
    required this.domainId,
  });

  @override
  State<DomainDetailScreen> createState() => _DomainDetailScreenState();
}

class _DomainDetailScreenState extends State<DomainDetailScreen> {
  Map<String, dynamic>? _domainData;
  bool _isLoading = true;
  String? _error;
  String _userRole = 'user';

  bool get _isContributor => _userRole == 'contributor' || _userRole == 'admin';

  @override
  void initState() {
    super.initState();
    _loadDomain();
  }

  Future<void> _loadDomain() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final results = await Future.wait([
        apiService.getDomainDetail(widget.domainId),
        apiService.getUserProfile(),
      ]);
      setState(() {
        _domainData = results[0];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_domainData?['name'] ?? 'Chương học'),
      ),
      body: _isLoading
          ? const SkeletonLoader(
              width: double.infinity, height: double.infinity)
          : _error != null
              ? AppErrorWidget(message: _error!, onRetry: _loadDomain)
              : _domainData == null
                  ? const Center(child: Text('Không tìm thấy chương học'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Domain info
                          _buildDomainInfo(),
                          const SizedBox(height: 24),
                          // Nodes list
                          _buildNodesList(),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildDomainInfo() {
    final name = _domainData!['name'] as String? ?? 'Chương học';
    final description = _domainData!['description'] as String?;
    final metadata = _domainData!['metadata'] as Map<String, dynamic>?;
    final icon = metadata?['icon'] as String? ?? '📚';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  icon,
                  style: const TextStyle(fontSize: 48),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (description != null && description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                description,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNodesList() {
    final nodes = _domainData!['nodes'] as List<dynamic>? ?? [];

    if (nodes.isEmpty && !_isContributor) {
      return Center(
        child: Column(
          children: [
            Icon(Icons.book_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Chưa có bài học nào trong chương này',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Danh sách bài học',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            if (_isContributor)
              TextButton.icon(
                onPressed: () async {
                  final subjectId = _domainData!['subjectId'] as String?;
                  final domainName = _domainData!['name'] as String? ?? '';
                  if (subjectId == null) return;
                  final result = await context.push(
                    '/contributor/create-topic?subjectId=$subjectId&domainId=${widget.domainId}&domainName=${Uri.encodeComponent(domainName)}',
                  );
                  if (result == true) _loadDomain();
                },
                icon: Icon(Icons.add, size: 18, color: AppColors.contributorBlue),
                label: Text('Thêm Topic', style: TextStyle(color: AppColors.contributorBlue, fontWeight: FontWeight.w600)),
              ),
          ],
        ),
        const SizedBox(height: 12),
        ...nodes.map((node) => _buildNodeCard(node as Map<String, dynamic>)),
        if (_isContributor) _buildAddTopicCard(),
      ],
    );
  }

  Widget _buildAddTopicCard() {
    final subjectId = _domainData!['subjectId'] as String?;
    final domainName = _domainData!['name'] as String? ?? '';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: AppColors.contributorBlue.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.contributorBlue.withOpacity(0.3), width: 1.5),
      ),
      child: InkWell(
        onTap: () async {
          if (subjectId == null) return;
          final result = await context.push(
            '/contributor/create-topic?subjectId=$subjectId&domainId=${widget.domainId}&domainName=${Uri.encodeComponent(domainName)}',
          );
          if (result == true) _loadDomain();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline, color: AppColors.contributorBlue, size: 24),
              const SizedBox(width: 8),
              Text('Thêm Topic / Bài học mới',
                  style: TextStyle(color: AppColors.contributorBlue, fontWeight: FontWeight.w600, fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNodeCard(Map<String, dynamic> node) {
    final title = node['title'] as String? ?? 'Bài học';
    final description = node['description'] as String?;
    final metadata = node['metadata'] as Map<String, dynamic>?;
    final icon = metadata?['icon'] as String? ?? '📖';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // Navigate to node detail or skill tree
          final subjectId = _domainData!['subjectId'] as String?;
          if (subjectId != null) {
            context
                .push('/skill-tree?subjectId=$subjectId&nodeId=${node['id']}');
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                icon,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (description != null && description.isNotEmpty) ...[
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
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
