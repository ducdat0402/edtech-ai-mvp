import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/theme/theme.dart';

class WeeklyPlanScreen extends StatefulWidget {
  const WeeklyPlanScreen({super.key});

  @override
  State<WeeklyPlanScreen> createState() => _WeeklyPlanScreenState();
}

class _WeeklyPlanScreenState extends State<WeeklyPlanScreen> {
  bool _loading = true;
  bool _saving = false;
  int _targetSessions = 3;
  int _targetLessons = 3;
  Set<int> _plannedDays = {1, 3, 5};
  Map<String, dynamic>? _review;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final plan = await api.getCurrentWeeklyPlan();
      final review = await api.getCurrentWeeklyReview();
      if (!mounted) return;
      setState(() {
        if (plan != null) {
          _targetSessions = (plan['targetSessions'] as num?)?.toInt() ?? 3;
          _targetLessons = (plan['targetLessons'] as num?)?.toInt() ?? 3;
          final raw = (plan['plannedDays'] as List?) ?? const [];
          _plannedDays = raw.map((e) => (e as num).toInt()).toSet();
          if (_plannedDays.isEmpty) _plannedDays = {1, 3, 5};
        }
        _review = review;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _savePlan() async {
    if (_plannedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chọn ít nhất 1 ngày học trong tuần.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      await api.upsertWeeklyPlan(
        targetSessions: _targetSessions,
        targetLessons: _targetLessons,
        plannedDays: _plannedDays.toList()..sort(),
      );
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu cam kết tuần.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không lưu được kế hoạch: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final weekdayLabels = <int, String>{
      1: 'T2',
      2: 'T3',
      3: 'T4',
      4: 'T5',
      5: 'T6',
      6: 'T7',
      0: 'CN',
    };

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: const Text('Lãnh đạo bản thân'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Cam kết tuần',
                  style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Đặt kế hoạch rõ ràng giúp bạn chủ động hơn trong việc học.',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textTertiary),
                ),
                const SizedBox(height: 16),
                _buildStepper(
                  label: 'Số phiên học mục tiêu',
                  value: _targetSessions,
                  onChanged: (v) => setState(() => _targetSessions = v),
                  min: 1,
                  max: 14,
                ),
                const SizedBox(height: 10),
                _buildStepper(
                  label: 'Số bài học mục tiêu',
                  value: _targetLessons,
                  onChanged: (v) => setState(() => _targetLessons = v),
                  min: 1,
                  max: 30,
                ),
                const SizedBox(height: 12),
                Text(
                  'Ngày dự kiến học',
                  style:
                      AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: weekdayLabels.entries.map((e) {
                    final selected = _plannedDays.contains(e.key);
                    return FilterChip(
                      label: Text(e.value),
                      selected: selected,
                      onSelected: (v) {
                        setState(() {
                          if (v) {
                            _plannedDays.add(e.key);
                          } else {
                            _plannedDays.remove(e.key);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _savePlan,
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Lưu cam kết tuần'),
                  ),
                ),
                const SizedBox(height: 24),
                if (_review != null) _buildReviewCard(_review!),
              ],
            ),
    );
  }

  Widget _buildStepper({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
    required int min,
    required int max,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderPrimary),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
            ),
          ),
          IconButton(
            onPressed: value > min ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Text('$value', style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary)),
          IconButton(
            onPressed: value < max ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final actual = (review['actual'] as Map?) ?? const {};
    final followRate = (review['followRate'] as num?)?.toInt() ?? 0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tổng kết tuần hiện tại',
            style: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Phiên học: ${actual['sessionCount'] ?? 0}  |  Bài học: ${actual['lessonCount'] ?? 0}',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          Text(
            'Tỷ lệ bám kế hoạch: $followRate%',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            (review['note'] ?? '').toString(),
            style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

