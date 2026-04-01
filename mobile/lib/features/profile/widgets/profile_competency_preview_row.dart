import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:edtech_mobile/theme/theme.dart';

/// Thứ tự khóa trùng với template trong [CompetenciesScreen].
class ProfileCompetencyPreviewRow extends StatelessWidget {
  const ProfileCompetencyPreviewRow({
    super.key,
    required this.competenciesData,
    required this.bgSecondary,
    required this.borderColor,
    required this.onTapLearning,
    required this.onTapHuman,
  });

  final Map<String, dynamic>? competenciesData;
  final Color bgSecondary;
  final Color borderColor;
  final VoidCallback onTapLearning;
  final VoidCallback onTapHuman;

  static const List<String> learningKeys = [
    'memory',
    'logical_thinking',
    'processing_speed',
    'practical_application',
    'metacognition',
    'learning_persistence',
    'knowledge_absorption',
  ];

  static const List<String> humanKeys = [
    'systems_thinking',
    'creativity',
    'communication',
    'self_leadership',
    'discipline',
    'growth_mindset',
    'critical_thinking',
    'collaboration',
  ];

  static Map<String, double> extractMetricValues(dynamic raw) {
    final out = <String, double>{};
    if (raw is! List) return out;
    for (final e in raw) {
      if (e is! Map) continue;
      final key = e['key']?.toString();
      final valueRaw = e['value'];
      if (key == null || key.isEmpty) continue;
      final value = valueRaw is num
          ? valueRaw.toDouble()
          : double.tryParse('$valueRaw') ?? 0;
      out[key] = value.clamp(0, 100).toDouble();
    }
    return out;
  }

  static List<double> orderedNormalized(
    Map<String, double> map,
    List<String> keys,
  ) {
    return keys
        .map((k) => ((map[k] ?? 0).clamp(0, 100).toDouble()) / 100.0)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final data = competenciesData;
    final learningMap =
        extractMetricValues(data == null ? null : data['learningMetrics']);
    final humanMap =
        extractMetricValues(data == null ? null : data['humanMetrics']);
    final learningV = orderedNormalized(learningMap, learningKeys);
    final humanV = orderedNormalized(humanMap, humanKeys);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _PreviewCard(
            title: 'Năng lực học tập',
            subtitle: 'Chạm để xem chi tiết',
            color: AppColors.cyanNeon,
            bgSecondary: bgSecondary,
            borderColor: borderColor,
            normalizedValues: learningV,
            onTap: onTapLearning,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _PreviewCard(
            title: 'Năng lực con người',
            subtitle: 'Chạm để xem chi tiết',
            color: AppColors.orangeNeon,
            bgSecondary: bgSecondary,
            borderColor: borderColor,
            normalizedValues: humanV,
            onTap: onTapHuman,
          ),
        ),
      ],
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.bgSecondary,
    required this.borderColor,
    required this.normalizedValues,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final Color color;
  final Color bgSecondary;
  final Color borderColor;
  final List<double> normalizedValues;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: bgSecondary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 118,
                  child: _MiniRadarChart(
                    color: color,
                    borderColor: borderColor,
                    normalizedValues: normalizedValues,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniRadarChart extends StatelessWidget {
  const _MiniRadarChart({
    required this.color,
    required this.borderColor,
    required this.normalizedValues,
  });

  final Color color;
  final Color borderColor;
  final List<double> normalizedValues;

  @override
  Widget build(BuildContext context) {
    if (normalizedValues.isEmpty) {
      return const SizedBox.shrink();
    }
    return RadarChart(
      RadarChartData(
        radarBackgroundColor: Colors.transparent,
        borderData: FlBorderData(show: false),
        radarBorderData: BorderSide(
          color: borderColor.withValues(alpha: 0.6),
        ),
        tickBorderData: BorderSide(
          color: borderColor.withValues(alpha: 0.45),
        ),
        gridBorderData: BorderSide(
          color: borderColor.withValues(alpha: 0.28),
        ),
        ticksTextStyle: AppTextStyles.caption.copyWith(
          color: AppColors.textTertiary,
          fontSize: 8,
        ),
        titleTextStyle: AppTextStyles.caption.copyWith(
          color: Colors.transparent,
          fontSize: 1,
        ),
        getTitle: (_, __) => const RadarChartTitle(text: ''),
        tickCount: 3,
        dataSets: [
          RadarDataSet(
            fillColor: color.withValues(alpha: 0.2),
            borderColor: color.withValues(alpha: 0.92),
            borderWidth: 1.8,
            entryRadius: 2,
            dataEntries: normalizedValues
                .map((v) => RadarEntry(value: v.clamp(0.0, 1.0)))
                .toList(),
          ),
        ],
      ),
    );
  }
}
