import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/core/widgets/error_widget.dart';
import 'package:edtech_mobile/core/widgets/empty_state.dart';
import 'package:edtech_mobile/core/widgets/skeleton_loader.dart';

class RoadmapScreen extends StatefulWidget {
  final String? subjectId;

  const RoadmapScreen({
    super.key,
    this.subjectId,
  });

  @override
  State<RoadmapScreen> createState() => _RoadmapScreenState();
}

class _RoadmapScreenState extends State<RoadmapScreen> {
  Map<String, dynamic>? _roadmapData;
  Map<String, dynamic>? _todayLesson;
  bool _isLoading = true;
  String? _error;
  bool _isCompleting = false;

  @override
  void initState() {
    super.initState();
    _loadRoadmap();
  }

  Future<void> _loadRoadmap() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      
      // Load roadmap
      final roadmapResponse = await apiService.getRoadmap(subjectId: widget.subjectId);
      
      // Handle response - convert to Map (API always returns Map or null)
      final roadmap = roadmapResponse is Map
          ? Map<String, dynamic>.from(roadmapResponse)
          : null;
      
      // Load today's lesson if roadmap exists
      Map<String, dynamic>? todayLesson;
      if (roadmap != null) {
        final roadmapId = roadmap['id'];
        if (roadmapId != null) {
          try {
            final todayResponse = await apiService.getTodayLesson(roadmapId.toString());
            todayLesson = Map<String, dynamic>.from(todayResponse as Map);
          } catch (e) {
            // Today lesson might not exist yet
            print('Error loading today lesson: $e');
          }
        }
      }

      setState(() {
        _roadmapData = roadmap;
        _todayLesson = todayLesson;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _completeDay(int dayNumber) async {
    if (_roadmapData == null || _isCompleting) return;

    setState(() {
      _isCompleting = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final roadmapId = _roadmapData!['id'] as String;
      
      await apiService.completeDay(roadmapId, dayNumber);

      // Reload roadmap
      await _loadRoadmap();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã hoàn thành ngày học! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCompleting = false;
        });
      }
    }
  }

  void _navigateToDayContent(Map<String, dynamic> day) {
    final nodeId = day['nodeId'];
    if (nodeId != null) {
      context.push('/nodes/$nodeId');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lộ trình học tập'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRoadmap,
          ),
        ],
      ),
      body: _isLoading
          ? _buildSkeletonLoader()
          : _error != null
              ? AppErrorWidget(
                  message: _error!,
                  onRetry: _loadRoadmap,
                )
              : _roadmapData == null
                  ? EmptyStateWidget(
                      icon: Icons.calendar_today,
                      title: 'Chưa có lộ trình học tập',
                      message: 'Hãy hoàn thành placement test để tạo lộ trình',
                      action: ElevatedButton(
                        onPressed: () => context.go('/placement-test'),
                        child: const Text('Bắt đầu Placement Test'),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadRoadmap,
                      child: _buildRoadmap(),
                    ),
    );
  }

  Widget _buildSkeletonLoader() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonCard(height: 100),
          const SizedBox(height: 24),
          SkeletonCard(height: 200),
          const SizedBox(height: 24),
          SkeletonCard(height: 300),
        ],
      ),
    );
  }

  Widget _buildRoadmap() {
    final days = _roadmapData!['days'] as List<dynamic>? ?? [];
    final currentDay = _roadmapData!['currentDay'] as int? ?? 1;
    final todayDayNumber = _todayLesson?['dayNumber'] as int?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Roadmap Header
          _buildRoadmapHeader(),
          const SizedBox(height: 24),

          // Today's Lesson Highlight
          if (_todayLesson != null) ...[
            _buildTodayLesson(),
            const SizedBox(height: 24),
          ],

          // 30 Days Grid
          const Text(
            '30 Ngày học tập',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildDaysGrid(days, currentDay, todayDayNumber),
        ],
      ),
    );
  }

  Widget _buildRoadmapHeader() {
    final metadata = _roadmapData!['metadata'] as Map<String, dynamic>? ?? {};
    final level = metadata['level'] as String? ?? 'beginner';
    final startDate = _roadmapData!['startDate'] as String?;
    final endDate = _roadmapData!['endDate'] as String?;

    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getLevelColor(level),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    level.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Ngày ${_roadmapData!['currentDay'] ?? 1}/30',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            if (startDate != null && endDate != null) ...[
              const SizedBox(height: 12),
              Text(
                'Từ ${_formatDate(startDate)} đến ${_formatDate(endDate)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTodayLesson() {
    final dayNumber = _todayLesson!['dayNumber'] as int?;
    final content = _todayLesson!['content'] as Map<String, dynamic>? ?? {};
    final status = _todayLesson!['status'] as String? ?? 'pending';

    return Container(
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.today, color: Colors.orange, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bài học hôm nay',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Ngày $dayNumber',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (status == 'completed')
                  const Icon(Icons.check_circle, color: Colors.green, size: 32),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              content['title'] ?? 'No title',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (content['description'] != null) ...[
              const SizedBox(height: 8),
              Text(
                content['description'] ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
            if (content['estimatedMinutes'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${content['estimatedMinutes']} phút',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            if (status != 'completed')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isCompleting
                      ? null
                      : () {
                          if (dayNumber != null) {
                            _navigateToDayContent(_todayLesson!);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Bắt đầu học',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    if (dayNumber != null) {
                      _navigateToDayContent(_todayLesson!);
                    }
                  },
                  child: const Text('Xem lại'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaysGrid(List<dynamic> days, int currentDay, int? todayDayNumber) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: 30,
      itemBuilder: (context, index) {
        final dayNumber = index + 1;
        final day = days.firstWhere(
          (d) => d['dayNumber'] == dayNumber,
          orElse: () => null,
        );
        final status = day?['status'] as String? ?? 'pending';
        final isToday = dayNumber == todayDayNumber;
        final isCurrent = dayNumber == currentDay;

        return _DayCard(
          dayNumber: dayNumber,
          status: status,
          isToday: isToday,
          isCurrent: isCurrent,
          content: day?['content'],
          onTap: () {
            if (day != null && status != 'pending') {
              _navigateToDayContent(day);
            }
          },
        );
      },
    );
  }

  Color _getLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}

class _DayCard extends StatelessWidget {
  final int dayNumber;
  final String status;
  final bool isToday;
  final bool isCurrent;
  final Map<String, dynamic>? content;
  final VoidCallback? onTap;

  const _DayCard({
    required this.dayNumber,
    required this.status,
    required this.isToday,
    required this.isCurrent,
    this.content,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color borderColor;
    IconData? icon;

    if (isToday) {
      backgroundColor = Colors.orange.shade100;
      borderColor = Colors.orange;
      icon = Icons.today;
    } else if (status == 'completed') {
      backgroundColor = Colors.green.shade100;
      borderColor = Colors.green;
      icon = Icons.check_circle;
    } else if (isCurrent) {
      backgroundColor = Colors.blue.shade100;
      borderColor = Colors.blue;
    } else {
      backgroundColor = Colors.grey.shade200;
      borderColor = Colors.grey.shade300;
    }

    return GestureDetector(
      onTap: status != 'pending' ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null)
              Icon(icon, size: 20, color: borderColor)
            else
              const SizedBox(height: 4),
            Text(
              '$dayNumber',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: borderColor,
              ),
            ),
            if (content?['type'] == 'review')
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.purple.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'R',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.purple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

