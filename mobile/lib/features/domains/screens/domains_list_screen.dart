import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/core/widgets/error_widget.dart';
import 'package:edtech_mobile/core/widgets/skeleton_loader.dart';
import 'package:edtech_mobile/theme/theme.dart';

class DomainsListScreen extends StatefulWidget {
  final String subjectId;
  final String? subjectName;

  const DomainsListScreen({
    super.key,
    required this.subjectId,
    this.subjectName,
  });

  @override
  State<DomainsListScreen> createState() => _DomainsListScreenState();
}

class _DomainsListScreenState extends State<DomainsListScreen> {
  List<dynamic> _domains = [];
  bool _isLoading = true;
  String? _error;
  String _userRole = 'user';

  bool get _isContributor => _userRole == 'contributor' || _userRole == 'admin';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final results = await Future.wait([
        apiService.getDomainsBySubject(widget.subjectId),
        apiService.getUserProfile(),
      ]);
      setState(() {
        _domains = results[0] as List<dynamic>;
        final profile = results[1] as Map<String, dynamic>;
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
        title: Text(widget.subjectName ?? 'Chương học'),
      ),
      body: _isLoading
          ? const SkeletonLoader(width: double.infinity, height: double.infinity)
          : _error != null
              ? AppErrorWidget(message: _error!, onRetry: _loadData)
              : _domains.isEmpty && !_isContributor
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.book_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'Chưa có chương học nào',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Vui lòng quay lại sau',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _domains.length + (_isContributor ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (_isContributor && index == _domains.length) {
                            return _buildAddDomainCard();
                          }
                          final domain = _domains[index];
                          return _buildDomainCard(domain);
                        },
                      ),
                    ),
      floatingActionButton: _isContributor && !_isLoading
          ? FloatingActionButton(
              onPressed: () async {
                final result = await context.push(
                  '/contributor/create-domain?subjectId=${widget.subjectId}&subjectName=${Uri.encodeComponent(widget.subjectName ?? '')}',
                );
                if (result == true) _loadData();
              },
              backgroundColor: AppColors.contributorBlue,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildAddDomainCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: AppColors.contributorBlue.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.contributorBlue.withOpacity(0.3), width: 1.5),
      ),
      child: InkWell(
        onTap: () async {
          final result = await context.push(
            '/contributor/create-domain?subjectId=${widget.subjectId}&subjectName=${Uri.encodeComponent(widget.subjectName ?? '')}',
          );
          if (result == true) _loadData();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline, color: AppColors.contributorBlue, size: 24),
              const SizedBox(width: 8),
              Text('Thêm Domain mới', style: TextStyle(color: AppColors.contributorBlue, fontWeight: FontWeight.w600, fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDomainCard(Map<String, dynamic> domain) {
    final name = domain['name'] as String? ?? 'Chương học';
    final description = domain['description'] as String?;
    final order = domain['order'] as int? ?? 0;
    final metadata = domain['metadata'] as Map<String, dynamic>?;
    final icon = metadata?['icon'] as String? ?? '📚';
    final estimatedDays = metadata?['estimatedDays'] as int?;
    final nodesCount = (domain['nodes'] as List<dynamic>?)?.length ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () {
          // Navigate to domain detail or nodes list
          context.push('/domains/${domain['id']}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Order badge
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '${order + 1}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Icon
              Text(
                icon,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
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
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (nodesCount > 0) ...[
                          Icon(Icons.book, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            '$nodesCount bài học',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                        if (estimatedDays != null && estimatedDays > 0) ...[
                          if (nodesCount > 0) ...[
                            const SizedBox(width: 16),
                            Icon(Icons.schedule, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              '~$estimatedDays ngày',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Arrow
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

