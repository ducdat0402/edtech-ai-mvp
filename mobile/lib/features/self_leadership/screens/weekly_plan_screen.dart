import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/core/widgets/app_bar_leading_back_home.dart';
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const AppBarLeadingBackAndHome(),
        leadingWidth: 112,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    context.colors.success.withValues(alpha: 0.45),
                    context.colors.success.withValues(alpha: 0.08),
                  ],
                ),
                border: Border.all(
                  color: context.colors.textOnBrand.withValues(alpha: 0.1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: context.colors.success.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.event_available_rounded,
                color: context.colors.success,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Cam kết tuần',
                style: AppTextStyles.h4.copyWith(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ],
        ),
      ),
      body: _loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          context.colors.brand.withValues(alpha: 0.35),
                          context.colors.card,
                        ],
                      ),
                      border: Border.all(
                        color: context.colors.brand.withValues(alpha: 0.3),
                      ),
                    ),
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        color: context.colors.brandStrong,
                        strokeWidth: 2.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Đang tải kế hoạch…',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _buildIntroBanner(),
                const SizedBox(height: 18),
                _buildStepper(
                  label: 'Số phiên học mục tiêu',
                  value: _targetSessions,
                  onChanged: (v) => setState(() => _targetSessions = v),
                  min: 1,
                  max: 14,
                  icon: Icons.play_circle_fill_rounded,
                  accent: context.colors.warning,
                ),
                const SizedBox(height: 12),
                _buildStepper(
                  label: 'Số bài học mục tiêu',
                  value: _targetLessons,
                  onChanged: (v) => setState(() => _targetLessons = v),
                  min: 1,
                  max: 30,
                  icon: Icons.menu_book_rounded,
                  accent: context.colors.brandStrong,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: LinearGradient(
                          colors: [
                            context.colors.brand.withValues(alpha: 0.35),
                            context.colors.brand.withValues(alpha: 0.08),
                          ],
                        ),
                        border: Border.all(
                          color: context.colors.brand.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Icon(
                        Icons.calendar_month_rounded,
                        color: context.colors.brandStrong,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Ngày dự kiến học',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: context.colors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildDaysWrap(weekdayLabels),
                const SizedBox(height: 20),
                _buildSaveButton(),
                const SizedBox(height: 24),
                if (_review != null) _buildReviewCard(_review!),
              ],
            ),
    );
  }

  Widget _buildIntroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.colors.brand.withValues(alpha: 0.2),
            context.colors.info.withValues(alpha: 0.1),
            context.colors.card,
          ],
        ),
        border: Border.all(
          color: context.colors.brand.withValues(alpha: 0.32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.32),
            offset: const Offset(0, 5),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.flag_rounded,
                color: context.colors.gold,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Kế hoạch 7 ngày',
                style: AppTextStyles.labelLarge.copyWith(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Đặt mục tiêu rõ ràng giúp bạn chủ động hơn — chọn số phiên, số bài và các ngày trong tuần bạn sẽ học.',
            style: AppTextStyles.bodySmall.copyWith(
              color: context.colors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaysWrap(Map<int, String> weekdayLabels) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.colors.brand.withValues(alpha: 0.1),
            context.colors.card,
          ],
        ),
        border: Border.all(
          color: context.colors.brand.withValues(alpha: 0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.26),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: weekdayLabels.entries.map((e) {
          final selected = _plannedDays.contains(e.key);
          return Material(
            color: Colors.transparent,
            child: FilterChip(
              showCheckmark: false,
              label: Text(
                e.value,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? context.colors.textOnBrand : context.colors.textSecondary,
                ),
              ),
              selected: selected,
              selectedColor: context.colors.brand.withValues(alpha: 0.85),
              backgroundColor: context.colors.cardMuted,
              side: BorderSide(
                color: selected
                    ? context.colors.brand.withValues(alpha: 0.65)
                    : context.colors.border.withValues(alpha: 0.65),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              onSelected: (v) {
                setState(() {
                  if (v) {
                    _plannedDays.add(e.key);
                  } else {
                    _plannedDays.remove(e.key);
                  }
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSaveButton() {
    final sem = context.colors;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: context.colors.brand.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            offset: const Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: _saving ? null : _savePlan,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _saving
                    ? [
                        sem.cardMuted,
                        sem.cardMuted,
                      ]
                    : [
                        sem.brand,
                        sem.brandStrong,
                      ],
              ),
              border: Border.all(
                color: sem.textOnBrand.withValues(alpha: 0.15),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: _saving
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: sem.brandStrong,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.save_rounded,
                              color: sem.textOnBrand, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'Lưu cam kết tuần',
                            style: TextStyle(
                              color: sem.textOnBrand,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepper({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
    required int min,
    required int max,
    required IconData icon,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.12),
            context.colors.card,
          ],
        ),
        border: Border.all(
          color: accent.withValues(alpha: 0.28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  accent.withValues(alpha: 0.35),
                  accent.withValues(alpha: 0.1),
                ],
              ),
              border: Border.all(
                color: accent.withValues(alpha: 0.4),
              ),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _StepperCircleButton(
            icon: Icons.remove_rounded,
            accent: accent,
            enabled: value > min,
            onTap: () => onChanged(value - 1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Container(
              constraints: const BoxConstraints(minWidth: 36),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: context.colors.cardMuted,
                border: Border.all(
                  color: accent.withValues(alpha: 0.35),
                ),
              ),
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: AppTextStyles.h4.copyWith(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          _StepperCircleButton(
            icon: Icons.add_rounded,
            accent: accent,
            enabled: value < max,
            onTap: () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final actual = (review['actual'] as Map?) ?? const {};
    final followRate = (review['followRate'] as num?)?.toInt() ?? 0;
    final rateColor = followRate >= 70
        ? context.colors.success
        : followRate >= 40
            ? context.colors.gold
            : context.colors.warning;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.colors.info.withValues(alpha: 0.1),
            context.colors.card,
          ],
        ),
        border: Border.all(
          color: context.colors.info.withValues(alpha: 0.28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            offset: const Offset(0, 5),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      context.colors.info.withValues(alpha: 0.4),
                      context.colors.info.withValues(alpha: 0.08),
                    ],
                  ),
                  border: Border.all(
                    color: context.colors.info.withValues(alpha: 0.35),
                  ),
                ),
                child: Icon(
                  Icons.insights_rounded,
                  color: context.colors.brandStrong,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tổng kết tuần hiện tại',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: context.colors.cardMuted,
              border: Border.all(
                color: context.colors.border.withValues(alpha: 0.65),
              ),
            ),
            child: Row(
              children: [
                _ReviewStatChip(
                  icon: Icons.play_circle_outline_rounded,
                  label: 'Phiên',
                  value: '${actual['sessionCount'] ?? 0}',
                  color: context.colors.warning,
                ),
                Container(
                  width: 1,
                  height: 28,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  color: context.colors.textTertiary.withValues(alpha: 0.35),
                ),
                _ReviewStatChip(
                  icon: Icons.menu_book_rounded,
                  label: 'Bài',
                  value: '${actual['lessonCount'] ?? 0}',
                  color: context.colors.brandStrong,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Bám kế hoạch',
                style: AppTextStyles.bodySmall.copyWith(
                  color: context.colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: LinearGradient(
                    colors: [
                      rateColor.withValues(alpha: 0.35),
                      rateColor.withValues(alpha: 0.12),
                    ],
                  ),
                  border: Border.all(
                    color: rateColor.withValues(alpha: 0.45),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: rateColor.withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '$followRate%',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: rateColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if ((review['note'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              (review['note'] ?? '').toString(),
              style: AppTextStyles.caption.copyWith(
                color: context.colors.textTertiary,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StepperCircleButton extends StatelessWidget {
  const _StepperCircleButton({
    required this.icon,
    required this.accent,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final Color accent;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: enabled
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent.withValues(alpha: 0.45),
                      accent.withValues(alpha: 0.15),
                    ],
                  )
                : null,
            color: enabled ? null : context.colors.cardMuted,
            border: Border.all(
              color: enabled
                  ? accent.withValues(alpha: 0.5)
                  : context.colors.textTertiary.withValues(alpha: 0.25),
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            size: 22,
            color: enabled ? context.colors.textOnBrand : context.colors.textTertiary,
          ),
        ),
      ),
    );
  }
}

class _ReviewStatChip extends StatelessWidget {
  const _ReviewStatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: context.colors.textTertiary,
                    fontSize: 10,
                  ),
                ),
                Text(
                  value,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
