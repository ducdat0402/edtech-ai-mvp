import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/core/widgets/error_widget.dart';
import 'package:edtech_mobile/core/widgets/skeleton_loader.dart';

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
      final domain = await apiService.getDomainDetail(widget.domainId);
      setState(() {
        _domainData = domain;
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

    if (nodes.isEmpty) {
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
        Text(
          'Danh sách bài học',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),
        ...nodes.map((node) => _buildNodeCard(node as Map<String, dynamic>)),
      ],
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
