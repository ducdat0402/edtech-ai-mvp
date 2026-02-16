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
  Set<String> _unlockedNodeIds = {};

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
      final domainData = results[0];
      final profile = results[1];

      // Load unlock status if subjectId is available
      final subjectId = domainData['subjectId'] as String?;
      Set<String> unlockedIds = {};
      if (subjectId != null) {
        try {
          final pricing = await apiService.getUnlockPricing(subjectId);
          // Build set of unlocked node IDs from pricing data
          final isSubjectUnlocked = pricing['isSubjectUnlocked'] == true;
          if (isSubjectUnlocked) {
            // All nodes unlocked
            final nodes = domainData['nodes'] as List<dynamic>? ?? [];
            unlockedIds = nodes.map((n) => (n as Map<String, dynamic>)['id'] as String).toSet();
          } else {
            final domains = pricing['domains'] as List<dynamic>? ?? [];
            for (final d in domains) {
              final domain = d as Map<String, dynamic>;
              if (domain['isUnlocked'] == true) {
                // All nodes in this domain are unlocked
                final nodes = domainData['nodes'] as List<dynamic>? ?? [];
                if (domain['domainId'] == widget.domainId) {
                  unlockedIds = nodes.map((n) => (n as Map<String, dynamic>)['id'] as String).toSet();
                }
              } else {
                final topics = domain['topics'] as List<dynamic>? ?? [];
                for (final t in topics) {
                  final topic = t as Map<String, dynamic>;
                  if (topic['isUnlocked'] == true) {
                    // Mark nodes in this topic as unlocked
                    final nodes = domainData['nodes'] as List<dynamic>? ?? [];
                    for (final n in nodes) {
                      final node = n as Map<String, dynamic>;
                      if (node['topicId'] == topic['topicId']) {
                        unlockedIds.add(node['id'] as String);
                      }
                    }
                  }
                }
              }
            }
          }
        } catch (_) {
          // Ignore pricing errors - just show all as locked
        }
      }

      setState(() {
        _domainData = domainData;
        _userRole = profile['role'] as String? ?? 'user';
        _unlockedNodeIds = unlockedIds;
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
                icon: const Icon(Icons.add, size: 18, color: AppColors.contributorBlue),
                label: const Text('Thêm Topic', style: TextStyle(color: AppColors.contributorBlue, fontWeight: FontWeight.w600)),
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
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline, color: AppColors.contributorBlue, size: 24),
              SizedBox(width: 8),
              Text('Thêm Topic / Bài học mới',
                  style: TextStyle(color: AppColors.contributorBlue, fontWeight: FontWeight.w600, fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNodeCard(Map<String, dynamic> node) {
    final nodeId = node['id'] as String;
    final title = node['title'] as String? ?? 'Bài học';
    final description = node['description'] as String?;
    final metadata = node['metadata'] as Map<String, dynamic>?;
    final icon = metadata?['icon'] as String? ?? '📖';
    final isLocked = !_isContributor && !_unlockedNodeIds.contains(nodeId);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isLocked ? Colors.grey.shade50 : null,
      child: InkWell(
        onTap: () {
          if (isLocked) {
            _showLockedDialog(title);
          } else {
            context.push(
              '/lessons/$nodeId/types',
              extra: {'title': title},
            ).then((_) => _loadDomain());
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: isLocked ? 0.7 : 1.0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isLocked ? Colors.grey : null,
                        ),
                      ),
                      if (description != null && description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (isLocked) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.lock, size: 12, color: Colors.orange.shade400),
                            const SizedBox(width: 4),
                            Text(
                              '25 💎 để mở khóa',
                              style: TextStyle(fontSize: 11, color: Colors.orange.shade600, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                isLocked
                    ? Icon(Icons.lock_outline, color: Colors.orange.shade300, size: 22)
                    : Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLockedDialog(String title) {
    final subjectId = _domainData?['subjectId'] as String?;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔒', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Bài học này cần mở khóa bằng kim cương.\nBạn có thể mở khóa từng topic, chương hoặc cả môn để tiết kiệm.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Đóng'),
                  ),
                ),
                const SizedBox(width: 12),
                if (subjectId != null)
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.push('/subjects/$subjectId/unlock').then((_) => _loadDomain());
                      },
                      icon: const Text('💎', style: TextStyle(fontSize: 16)),
                      label: const Text('Mở khóa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
