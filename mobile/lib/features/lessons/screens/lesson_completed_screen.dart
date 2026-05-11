import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/theme/theme.dart';

class LessonCompletedScreen extends StatefulWidget {
  const LessonCompletedScreen({
    super.key,
    required this.nodeId,
    required this.lessonTitle,
    required this.accuracyPercent,
    required this.xpEarned,
    required this.streak,
    required this.durationLabel,
  });

  final String nodeId;
  final String lessonTitle;
  final int accuracyPercent;
  final int xpEarned;
  final int streak;
  final String durationLabel;

  @override
  State<LessonCompletedScreen> createState() => _LessonCompletedScreenState();
}

class _LessonCompletedScreenState extends State<LessonCompletedScreen> {
  String? _topicName;
  int? _lessonIndex;
  Map<String, dynamic>? _nextLesson;
  bool _loadingMeta = true;

  @override
  void initState() {
    super.initState();
    _loadMeta();
  }

  Future<void> _loadMeta() async {
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final node = await api.getNodeDetail(widget.nodeId);
      final topicId = node['topicId']?.toString();
      if (topicId != null && topicId.isNotEmpty) {
        final nodes = await api.getNodesByTopic(topicId);
        final sorted = nodes
            .whereType<Map<String, dynamic>>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
          ..sort(
            (a, b) => ((a['order'] as num?)?.toInt() ?? 0)
                .compareTo((b['order'] as num?)?.toInt() ?? 0),
          );
        final idx = sorted.indexWhere(
          (n) => n['id']?.toString() == widget.nodeId,
        );
        if (!mounted) return;
        setState(() {
          _topicName = node['topicTitle']?.toString() ?? node['topicName']?.toString();
          _lessonIndex = idx >= 0 ? idx + 1 : null;
          _nextLesson = (idx >= 0 && idx + 1 < sorted.length) ? sorted[idx + 1] : null;
          _loadingMeta = false;
        });
      } else {
        if (!mounted) return;
        setState(() => _loadingMeta = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMeta = false);
    }
  }

  void _goBackToLessonList() {
    final nav = Navigator.of(context);
    nav.pop(true);
    if (nav.canPop()) {
      nav.pop();
    }
  }

  void _goToNextLesson() {
    final nextId = _nextLesson?['id']?.toString();
    if (nextId == null || nextId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã hết bài trong chủ đề')),
      );
      return;
    }
    final nextTitle = _nextLesson?['title']?.toString() ?? 'Bài học';
    context.go('/lessons/$nextId/types', extra: {'title': nextTitle});
  }

  String get _subtitle {
    if (_topicName == null || _topicName!.isEmpty || _lessonIndex == null) {
      return '';
    }
    return '$_topicName · Bài $_lessonIndex';
  }

  @override
  Widget build(BuildContext context) {
    final t = context.colors;
    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: t.textPrimary),
          onPressed: _goBackToLessonList,
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset(
                'assets/images/lesson_completed_hero.png',
                height: 180,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 14),
              Text(
                'Hoàn thành bài học!',
                textAlign: TextAlign.center,
                style: AppTextStyles.h2.copyWith(
                  color: t.brand,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.lessonTitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.h4.copyWith(
                  color: t.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (_subtitle.isNotEmpty || _loadingMeta) ...[
                const SizedBox(height: 4),
                Text(
                  _loadingMeta ? 'Đang tải thông tin bài...' : _subtitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: t.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 22),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.9,
                children: [
                  _StatCard(
                    icon: Icons.gps_fixed_rounded,
                    iconColor: const Color(0xFFDD514C),
                    title: 'Chính xác',
                    value: '${widget.accuracyPercent}%',
                  ),
                  _StatCard(
                    icon: Icons.star_rounded,
                    iconColor: const Color(0xFFF4B73B),
                    title: 'EXP đã nhận',
                    value: '+${widget.xpEarned}',
                  ),
                  _StatCard(
                    icon: Icons.local_fire_department_rounded,
                    iconColor: const Color(0xFFFF8A34),
                    title: 'Chuỗi',
                    value: '${widget.streak}',
                  ),
                  _StatCard(
                    icon: Icons.access_time_filled_rounded,
                    iconColor: t.brand,
                    title: 'Thời gian',
                    value: widget.durationLabel,
                  ),
                ],
              ),
              const SizedBox(height: 26),
              FilledButton(
                onPressed: _goToNextLesson,
                style: FilledButton.styleFrom(
                  backgroundColor: t.brand,
                  foregroundColor: t.textOnBrand,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Text('Bài tiếp theo'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _goBackToLessonList,
                style: FilledButton.styleFrom(
                  backgroundColor: t.cardMuted,
                  foregroundColor: t.brand,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Text('Về danh sách bài học'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 6),
              Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(color: t.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.h3.copyWith(
              color: t.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
